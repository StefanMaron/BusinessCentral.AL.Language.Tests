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

    // Every operation below runs inside asserterror through Op(): Op ends with the error 'LT CP ok <value>' when the operation itself raised
    // nothing, so each observation is either that marker or BC's own error text and code. asserterror rolls back what the operation wrote.

    // ---- item 76: CalcField without read permission on the CalcFormula table ----

    [Test]
    procedure CalcField_NoReadPermission()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        WasStarted: Boolean;
    begin
        SeedLedger();
        WasStarted := StartMock(Mock);
        Mock.Set(EmptyTok);
        asserterror Op(1);
        Observer.ObserveError('if_fieldref_calcfield');
        asserterror Op(2);
        Observer.ObserveError('if_record_calcfields');
        asserterror Op(3);
        Observer.ObserveError('tryfunction_calcfields');
        asserterror Op(4);
        Observer.ObserveError('host_count');
        RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure CalcField_NoReadPermission_CodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Host: Record "LT CP Flow Host";
        WasStarted: Boolean;
    begin
        WasStarted := StartMock(Mock);
        Mock.Set(EmptyTok);
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
    procedure CalcField_IndirectRead_AndNoMock()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        WasStarted: Boolean;
    begin
        SeedLedger();
        asserterror Op(5);
        Observer.ObserveError('no_mock_calcfields');
        WasStarted := StartMock(Mock);
        Mock.Set(IndirectTok);
        asserterror Op(5);
        Observer.ObserveError('indirect_calcfields');
        asserterror Op(6);
        Observer.ObserveError('indirect_direct_count');
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
    procedure Indirect_PermissionsPropertyAndDirectWrites()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Ledger: Record "LT CP Ledger";
        WasStarted: Boolean;
    begin
        SeedLedger();
        WasStarted := StartMock(Mock);
        Mock.Set(IndirectTok);
        asserterror Op(10);
        Observer.ObserveError('writer_insert');
        asserterror Op(11);
        Observer.ObserveError('writer_modify');
        asserterror Op(12);
        Observer.ObserveError('writer_count');
        asserterror Op(13);
        Observer.ObserveError('readonly_writer_insert');
        asserterror Op(14);
        Observer.ObserveError('direct_insert');
        asserterror Op(15);
        Observer.ObserveError('direct_modify');
        asserterror Op(6);
        Observer.ObserveError('direct_count');
        Mock.Set(EmptyTok);
        asserterror Op(10);
        Observer.ObserveError('empty_writer_insert');
        RestoreMock(Mock, WasStarted);
        Observer.Observe('rows_after', Format(Ledger.Count()));
        Observer.Finish();
    end;

    // ---- item 81: subscriber with a Permissions property, read deeper in the call stack ----

    [Test]
    procedure Subscriber_ReadDeeperInTheCallStack()
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
        asserterror Op(21);
        Observer.ObserveError('read_in_subscriber');
        asserterror Op(22);
        Observer.ObserveError('read_in_codeunit_without_permissions');
        asserterror Op(23);
        Observer.ObserveError('read_in_codeunit_with_permissions');
        asserterror Op(24);
        Observer.ObserveError('read_in_inherent_permissions_method');
        asserterror Op(25);
        Observer.ObserveError('direct_reader_without_permissions');
        Mock.Set(EmptyTok);
        asserterror Op(21);
        Observer.ObserveError('empty_read_in_subscriber');
        RestoreMock(Mock, WasStarted);
        Item.DeleteAll();
        Ext.DeleteAll();
        Observer.Finish();
    end;

    // ---- item 82: InherentPermissions attribute ----

    [Test]
    procedure InherentAttribute_InsideAfterNested()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
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
        asserterror Op(31);
        Observer.ObserveError('plain_before');
        asserterror Op(32);
        Observer.ObserveError('inherent');
        asserterror Op(33);
        Observer.ObserveError('inherent_then_plain');
        asserterror Op(34);
        Observer.ObserveError('nested_same_codeunit');
        asserterror Op(35);
        Observer.ObserveError('nested_other_codeunit');
        asserterror Op(36);
        Observer.ObserveError('direct_count');
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
    procedure ExcludedSet_UnderTheMock()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        WasStarted: Boolean;
    begin
        SeedLedger();
        WasStarted := StartMock(Mock);
        Mock.Set(FullTok);
        asserterror Op(6);
        Observer.ObserveError('full_count');
        asserterror Op(14);
        Observer.ObserveError('full_insert');
        Mock.Set(ExclTok);
        asserterror Op(6);
        Observer.ObserveError('excl_count');
        asserterror Op(14);
        Observer.ObserveError('excl_insert');
        Mock.Set(EmptyTok);
        asserterror Op(6);
        Observer.ObserveError('empty_count');
        RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    local procedure Op(Which: Integer)
    var
        Ledger: Record "LT CP Ledger";
        Host: Record "LT CP Flow Host";
        Item: Record "LT CP Item";
        Writer: Codeunit "LT CP Writer";
        ReadOnlyWriter: Codeunit "LT CP Writer Read Only";
        Reader: Codeunit "LT CP Reader";
        Inherent: Codeunit "LT CP Inherent";
        RecRef: RecordRef;
        FRef: FieldRef;
        Result: Text;
    begin
        case Which of
            1:
                begin
                    RecRef.Open(Database::"LT CP Flow Host");
                    FRef := RecRef.Field(2);
                    if FRef.CalcField() then
                        Result := 'true ' + Format(FRef.Value())
                    else
                        Result := 'false';
                end;
            2:
                if Host.CalcFields("Ledger Count") then
                    Result := 'true ' + Format(Host."Ledger Count")
                else
                    Result := 'false';
            3:
                if TryCalcFields(Host) then
                    Result := 'true ' + Format(Host."Ledger Count")
                else
                    Result := 'false: ' + GetLastErrorText();
            4:
                Result := Format(Host.Count());
            5:
                begin
                    Host.CalcFields("Ledger Count", "Ledger Sum");
                    Result := Format(Host."Ledger Count") + ' ' + Format(Host."Ledger Sum");
                end;
            6:
                Result := Format(Ledger.Count());
            10:
                begin
                    Writer.InsertRow(10);
                    Result := Format(Writer.CountRows());
                end;
            11:
                begin
                    Writer.ModifyRow(1, 9);
                    Ledger.Get(1);
                    Result := Format(Ledger.Amount);
                end;
            12:
                Result := Format(Writer.CountRows());
            13:
                ReadOnlyWriter.InsertRow(13);
            14:
                begin
                    Ledger."Entry No." := 14;
                    Ledger.Insert();
                end;
            15:
                begin
                    Ledger.Get(1);
                    Ledger.Amount := 15;
                    Ledger.Modify();
                end;
            21, 22, 23, 24:
                begin
                    Item.Get(1);
                    Item.Mode := Which - 20;
                    Item.Modify();
                    Result := 'mode ' + Format(Item.Mode);
                end;
            25:
                Reader.ReadExt();
            31, 33:
                begin
                    if Which = 33 then
                        Result := Format(Inherent.CountInherent()) + ' then ';
                    Result += Format(Inherent.CountPlain());
                end;
            32:
                Result := Format(Inherent.CountInherent());
            34:
                Result := Format(Inherent.CountNested());
            35:
                Result := Format(Inherent.CountViaOther());
            36:
                Result := Format(Inherent.CountPlain());
        end;
        Error('LT CP ok %1', Result);
    end;

    [TryFunction]
    local procedure TryCalcFields(var Host: Record "LT CP Flow Host")
    begin
        Host.CalcFields("Ledger Count");
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
