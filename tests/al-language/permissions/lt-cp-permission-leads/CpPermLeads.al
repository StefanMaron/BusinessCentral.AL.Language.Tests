// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-permissions
// Scope: in-scope
// Fixtures used: Probe Observer (69160); CpPermObjects.al (85000-85017); Permissions Mock (131006) from the dependency.
// Probe: corpus issue 669 (odd AL behavior leads, part D), items 76 to 89. Each test lowers the effective permissions with
//   Permissions Mock.Set (the named set plus "All Objects") and observes what BC does:
//   76 FieldRef.CalcField / Record.CalcFields without read permission on the CalcFormula table (if, TryFunction, Codeunit.Run),
//   78 RecordRef.Open on the system table Table Information from a Cloud app,
//   80 a codeunit Permissions property with only indirect grants in the user's set, and a direct write next to it,
//   81 a subscriber with a Permissions property that calls a codeunit without one (the read deeper in the call stack),
//   82 the InherentPermissions attribute: inside the method, after it returns, in nested calls,
//   84 Permissions Mock.ClearAssignments without a Start of its own (Microsoft's test runner toggles the mock around every test method),
//   86 ExcludedPermissionSets at run time under the mock.
// BC versions: 27, 28, 29

codeunit 85018 "LT CP Permission Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        IndirectTok: Label 'LT CP Indirect', Locked = true;
        EmptyTok: Label 'LT CP Empty', Locked = true;
        FullTok: Label 'LT CP Full', Locked = true;
        ExclTok: Label 'LT CP Excl', Locked = true;

    // ---- item 76: CalcField without read permission on the CalcFormula table ----

    [Test]
    procedure CalcField_NoReadPermission_IfFieldRefCalcField()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        WasStarted: Boolean;
    begin
        SeedLedger();
        WasStarted := StartMock(Mock);
        Mock.Set(EmptyTok);
        asserterror IfFieldRefCalcField();
        Observer.ObserveError('if_fieldref_calcfield');
        RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure CalcField_NoReadPermission_IfRecordCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        WasStarted: Boolean;
    begin
        SeedLedger();
        WasStarted := StartMock(Mock);
        Mock.Set(EmptyTok);
        asserterror IfRecordCalcFields();
        Observer.ObserveError('if_record_calcfields');
        RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure CalcField_NoReadPermission_TryFunctionAndCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Host: Record "LT CP Flow Host";
        WasStarted: Boolean;
    begin
        SeedLedger();
        WasStarted := StartMock(Mock);
        Mock.Set(EmptyTok);
        if TryCalcFields(Host) then
            Observer.Observe('tryfunction', 'true ' + Format(Host."Ledger Count"))
        else begin
            Observer.Observe('tryfunction', 'false');
            Observer.ObserveError('tryfunction_error');
        end;
        Clear(Host);
        if Codeunit.Run(Codeunit::"LT CP CalcFields Run", Host) then
            Observer.Observe('codeunit_run', 'true')
        else begin
            Observer.Observe('codeunit_run', 'false');
            Observer.ObserveError('codeunit_run_error');
        end;
        RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure CalcField_IndirectReadOnly_AndNoMock()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Host: Record "LT CP Flow Host";
        WasStarted: Boolean;
    begin
        SeedLedger();
        Host.CalcFields("Ledger Count", "Ledger Sum");
        Observer.Observe('no_mock', Format(Host."Ledger Count") + ' ' + Format(Host."Ledger Sum"));
        Clear(Host);
        WasStarted := StartMock(Mock);
        Mock.Set(IndirectTok);
        asserterror Host.CalcFields("Ledger Count");
        Observer.ObserveError('indirect_read_only');
        RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    // ---- item 78: Table Information through a RecordRef from a Cloud app ----

    [Test]
    procedure RecordRefOpen_TableInformation()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        asserterror RecRef.Open(2000000028);
        Observer.ObserveError('open_2000000028');
        Observer.Finish();
    end;

    // ---- item 80: Permissions property and indirect grants ----

    [Test]
    procedure Indirect_CodeunitWithPermissions_WritesDirectWriteRefused()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Writer: Codeunit "LT CP Writer";
        ReadOnlyWriter: Codeunit "LT CP Writer Read Only";
        Ledger: Record "LT CP Ledger";
        N: Integer;
        WasStarted: Boolean;
    begin
        Ledger.DeleteAll();
        WasStarted := StartMock(Mock);
        Mock.Set(IndirectTok);
        Writer.InsertRow(1);
        Observer.Observe('writer_insert', 'no error');
        Writer.ModifyRow(1, 5);
        Observer.Observe('writer_modify', 'no error');
        Observer.Observe('writer_count', Format(Writer.CountRows()));
        asserterror ReadOnlyWriter.InsertRow(2);
        Observer.ObserveError('readonly_writer_insert');
        Ledger."Entry No." := 3;
        asserterror Ledger.Insert();
        Observer.ObserveError('direct_insert');
        asserterror N := Ledger.Count();
        Observer.ObserveError('direct_count');
        RestoreMock(Mock, WasStarted);
        Ledger.Reset();
        Observer.Observe('rows_after', Format(Ledger.Count()));
        if Ledger.Get(1) then
            Observer.Observe('row1_amount', Format(Ledger.Amount));
        Observer.Finish();
    end;

    // ---- item 81: subscriber with a Permissions property, read deeper in the call stack ----

    [Test]
    procedure Subscriber_ReadInSubscriber()
    begin
        RunSubscriberMode(1);
    end;

    [Test]
    procedure Subscriber_ReadInCodeunitWithoutPermissions()
    begin
        RunSubscriberMode(2);
    end;

    [Test]
    procedure Subscriber_ReadInCodeunitWithPermissions()
    begin
        RunSubscriberMode(3);
    end;

    [Test]
    procedure Subscriber_ReadInInherentPermissionsMethod()
    begin
        RunSubscriberMode(4);
    end;

    // ---- item 82: InherentPermissions attribute ----

    [Test]
    procedure InherentAttribute_InsideAfterNested()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Inherent: Codeunit "LT CP Inherent";
        Secret: Record "LT CP Secret";
        WasStarted: Boolean;
    begin
        Secret.DeleteAll();
        Secret."Entry No." := 1;
        Secret.Insert();
        Secret."Entry No." := 2;
        Secret.Insert();
        WasStarted := StartMock(Mock);
        Mock.Set(EmptyTok);
        asserterror Inherent.CountPlain();
        Observer.ObserveError('plain_before');
        Observer.Observe('inherent', Format(Inherent.CountInherent()));
        asserterror Inherent.CountPlain();
        Observer.ObserveError('plain_after');
        if TryCount(1, Inherent, Secret) then
            Observer.Observe('nested_same_codeunit', Format(Secret.Count()))
        else
            Observer.ObserveError('nested_same_codeunit');
        if TryCount(2, Inherent, Secret) then
            Observer.Observe('nested_other_codeunit', 'no error')
        else
            Observer.ObserveError('nested_other_codeunit');
        RestoreMock(Mock, WasStarted);
        Secret.DeleteAll();
        Observer.Finish();
    end;

    // ---- item 84: ClearAssignments without a Start of the test's own ----

    [Test]
    procedure Mock_ClearAssignmentsWithoutOwnStart()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
    begin
        Observer.Observe('started_on_entry', Format(Mock.IsStarted()));
        Mock.ClearAssignments();
        Observer.Observe('clear', 'no error');
        Observer.Observe('started_after', Format(Mock.IsStarted()));
        Observer.Finish();
    end;

    // ---- item 86: ExcludedPermissionSets under the mock ----

    [Test]
    procedure ExcludedSet_RemovesReadKeepsInsert()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Ledger: Record "LT CP Ledger";
        N: Integer;
        WasStarted: Boolean;
    begin
        Ledger.DeleteAll();
        WasStarted := StartMock(Mock);
        Mock.Set(FullTok);
        Observer.Observe('full_count', Format(Ledger.Count()));
        Mock.Set(ExclTok);
        asserterror N := Ledger.Count();
        Observer.ObserveError('excl_count');
        Ledger."Entry No." := 7;
        if Ledger.Insert() then
            Observer.Observe('excl_insert', 'true')
        else
            Observer.ObserveError('excl_insert');
        RestoreMock(Mock, WasStarted);
        Ledger.Reset();
        Observer.Observe('rows_after', Format(Ledger.Count()));
        Ledger.DeleteAll();
        Observer.Finish();
    end;

    local procedure RunSubscriberMode(Mode: Integer)
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Item: Record "LT CP Item";
        Ext: Record "LT CP Ext";
        WasStarted: Boolean;
    begin
        Item.DeleteAll();
        Ext.DeleteAll();
        Ext."Entry No." := 1;
        Ext.Insert();
        Item."Entry No." := 1;
        Item.Insert();
        WasStarted := StartMock(Mock);
        Mock.Set(IndirectTok);
        Item.Get(1);
        Item.Mode := Mode;
        if TryModify(Item) then
            Observer.Observe('modify', 'no error')
        else
            Observer.ObserveError('modify');
        RestoreMock(Mock, WasStarted);
        Item.Get(1);
        Observer.Observe('mode_after', Format(Item.Mode));
        Item.DeleteAll();
        Ext.DeleteAll();
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryModify(var Item: Record "LT CP Item")
    begin
        Item.Modify();
    end;

    [TryFunction]
    local procedure TryCount(Which: Integer; var Inherent: Codeunit "LT CP Inherent"; var Secret: Record "LT CP Secret")
    begin
        case Which of
            1:
                Inherent.CountNested();
            2:
                Inherent.CountViaOther();
        end;
    end;

    [TryFunction]
    local procedure TryCalcFields(var Host: Record "LT CP Flow Host")
    begin
        Host.CalcFields("Ledger Count");
    end;

    local procedure IfFieldRefCalcField()
    var
        RecRef: RecordRef;
        FRef: FieldRef;
    begin
        RecRef.Open(Database::"LT CP Flow Host");
        FRef := RecRef.Field(2);
        if FRef.CalcField() then
            Error('LT CP CalcField returned true, value %1', FRef.Value())
        else
            Error('LT CP CalcField returned false');
    end;

    local procedure IfRecordCalcFields()
    var
        Host: Record "LT CP Flow Host";
    begin
        if Host.CalcFields("Ledger Count") then
            Error('LT CP CalcFields returned true, value %1', Host."Ledger Count")
        else
            Error('LT CP CalcFields returned false');
    end;

    local procedure SeedLedger()
    var
        Ledger: Record "LT CP Ledger";
    begin
        Ledger.DeleteAll();
        Ledger."Entry No." := 1;
        Ledger.Amount := 2;
        Ledger.Insert();
        Ledger."Entry No." := 2;
        Ledger.Amount := 3;
        Ledger.Insert();
    end;

    local procedure StartMock(var Mock: Codeunit "Permissions Mock") WasStarted: Boolean
    begin
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
    end;

    local procedure RestoreMock(var Mock: Codeunit "Permissions Mock"; WasStarted: Boolean)
    begin
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
    end;
}
