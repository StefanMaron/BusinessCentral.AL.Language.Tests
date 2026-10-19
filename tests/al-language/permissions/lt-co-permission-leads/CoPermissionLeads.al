// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Permissions Mock (dependency); own objects 84940-84950.
// Probe: corpus issue 669 (writer CO), items 66, 72, 74 and 75. Every literal asserted below is what the BC service tier produced.
// Facts: (75) which permissions apply when a manually bound subscriber of a table's OnAfterInsertEvent modifies a table the user may
// only read: the subscriber's own Permissions property, the publisher table's Permissions property, or the user's;
// (66) TaskScheduler.CreateTask and CanCreateTask under the Permissions Mock with a set that has no task scheduler rights;
// (72) the rows a wildcard 'page * = X' permission gives in Metadata Permission;
// (74) a page over a virtual table with AccessByPermission on a field, and AccessByPermission = tabledata <x> = D on an action, compile;
// what a TestPage reports for those controls.
// BC versions: 27, 28, 29

table 84940 "LT CO Perm Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 84941 "LT CO Perm Ledger"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Value; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

// The publisher table itself has modify permission on the ledger through its Permissions property.
table 84942 "LT CO Perm Src WP"
{
    DataClassification = SystemMetadata;
    Permissions = tabledata "LT CO Perm Ledger" = m;

    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 84943 "LT CO Sub NoPerm"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT CO Perm Src", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertSrc(var Rec: Record "LT CO Perm Src"; RunTrigger: Boolean)
    begin
        TouchLedger(Rec."Entry No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT CO Perm Src WP", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertSrcWP(var Rec: Record "LT CO Perm Src WP"; RunTrigger: Boolean)
    begin
        TouchLedger(Rec."Entry No.");
    end;

    local procedure TouchLedger(NewValue: Integer)
    var
        Ledger: Record "LT CO Perm Ledger";
    begin
        Ledger.Get(1);
        Ledger.Value := NewValue;
        Ledger.Modify();
    end;
}

codeunit 84944 "LT CO Sub WithPerm"
{
    EventSubscriberInstance = Manual;
    Permissions = tabledata "LT CO Perm Ledger" = m;

    [EventSubscriber(ObjectType::Table, Database::"LT CO Perm Src", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertSrc(var Rec: Record "LT CO Perm Src"; RunTrigger: Boolean)
    var
        Ledger: Record "LT CO Perm Ledger";
    begin
        Ledger.Get(1);
        Ledger.Value := Rec."Entry No.";
        Ledger.Modify();
    end;
}

permissionset 84945 "LT CO Perm User"
{
    Assignable = true;
    Permissions =
        tabledata "LT CO Perm Src" = RIMD,
        tabledata "LT CO Perm Src WP" = RIMD,
        tabledata "LT CO Perm Ledger" = R,
        codeunit "LT CO Sub NoPerm" = X,
        codeunit "LT CO Sub WithPerm" = X,
        codeunit "LT CO Task Noop" = X;
}

permissionset 84946 "LT CO Perm Wild"
{
    Assignable = true;
    Permissions = page * = X;
}

permissionset 84947 "LT CO Perm User M"
{
    Assignable = true;
    Permissions =
        tabledata "LT CO Perm Src" = RIMD,
        tabledata "LT CO Perm Ledger" = RM,
        codeunit "LT CO Sub NoPerm" = X;
}

codeunit 84948 "LT CO Task Noop"
{
    trigger OnRun()
    begin
    end;
}

// Compile facts for item 74: AccessByPermission on a field of a page over a virtual table, and 'tabledata <x> = D' on a field and an
// action, compile. Any other kind than X on a table, page, codeunit, report, query or xmlport object is AL0195 (must-not-compile 1715 to 1718).
page 84949 "LT CO ABP Facts"
{
    PageType = List;
    SourceTable = "Table Metadata";
    SourceTableView = where(ID = const(84941));
    Editable = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(ID; Rec.ID) { AccessByPermission = tabledata "Table Metadata" = R; }
                field(Name; Rec.Name) { AccessByPermission = tabledata "LT CO Perm Ledger" = D; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteRight)
            {
                AccessByPermission = tabledata "LT CO Perm Ledger" = D;
                trigger OnAction()
                begin
                end;
            }
        }
    }
}

codeunit 84950 "LT CO Permission Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        UserSetTok: Label 'LT CO Perm User', Locked = true;
        UserMSetTok: Label 'LT CO Perm User M', Locked = true;
        DoneTok: Label 'LT CO done', Locked = true;
        LedgerValueSeen: Integer;

    local procedure Init()
    var
        Src: Record "LT CO Perm Src";
        SrcWP: Record "LT CO Perm Src WP";
        Ledger: Record "LT CO Perm Ledger";
    begin
        Src.DeleteAll();
        SrcWP.DeleteAll();
        Ledger.DeleteAll();
        Ledger."Entry No." := 1;
        Ledger.Value := 0;
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

    // Inserts the row, records the ledger value the subscriber left, and always raises: a platform error or DoneTok.
    local procedure InsertSrcThenStop(EntryNo: Integer)
    var
        Src: Record "LT CO Perm Src";
        Ledger: Record "LT CO Perm Ledger";
    begin
        LedgerValueSeen := -1;
        Src."Entry No." := EntryNo;
        Src.Insert();
        Ledger.Get(1);
        LedgerValueSeen := Ledger.Value;
        Error(DoneTok);
    end;

    local procedure InsertSrcWPThenStop(EntryNo: Integer)
    var
        SrcWP: Record "LT CO Perm Src WP";
        Ledger: Record "LT CO Perm Ledger";
    begin
        LedgerValueSeen := -1;
        SrcWP."Entry No." := EntryNo;
        SrcWP.Insert();
        Ledger.Get(1);
        LedgerValueSeen := Ledger.Value;
        Error(DoneTok);
    end;

    [Test]
    procedure Subscriber_NoPermissionsProperty_UserReadOnly_CO()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Sub: Codeunit "LT CO Sub NoPerm";
        WasStarted: Boolean;
    begin
        Init();
        BindSubscription(Sub);
        WasStarted := StartMock(Mock);
        Mock.Set(UserSetTok);
        asserterror InsertSrcThenStop(7);
        Observer.ObserveError('insert');
        RestoreMock(Mock, WasStarted);
        UnbindSubscription(Sub);
        Observer.Observe('ledger value seen', Format(LedgerValueSeen));
        Observer.Finish();
    end;

    [Test]
    procedure Subscriber_WithPermissionsProperty_UserReadOnly_CO()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Sub: Codeunit "LT CO Sub WithPerm";
        WasStarted: Boolean;
    begin
        Init();
        BindSubscription(Sub);
        WasStarted := StartMock(Mock);
        Mock.Set(UserSetTok);
        asserterror InsertSrcThenStop(8);
        Observer.ObserveError('insert');
        RestoreMock(Mock, WasStarted);
        UnbindSubscription(Sub);
        Observer.Observe('ledger value seen', Format(LedgerValueSeen));
        Observer.Finish();
    end;

    [Test]
    procedure Subscriber_PublisherTableHasPermissions_UserReadOnly_CO()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Sub: Codeunit "LT CO Sub NoPerm";
        WasStarted: Boolean;
    begin
        Init();
        BindSubscription(Sub);
        WasStarted := StartMock(Mock);
        Mock.Set(UserSetTok);
        asserterror InsertSrcWPThenStop(9);
        Observer.ObserveError('insert');
        RestoreMock(Mock, WasStarted);
        UnbindSubscription(Sub);
        Observer.Observe('ledger value seen', Format(LedgerValueSeen));
        Observer.Finish();
    end;

    [Test]
    procedure Subscriber_NoPermissionsProperty_UserMayModify_CO()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Sub: Codeunit "LT CO Sub NoPerm";
        WasStarted: Boolean;
    begin
        Init();
        BindSubscription(Sub);
        WasStarted := StartMock(Mock);
        Mock.Set(UserMSetTok);
        asserterror InsertSrcThenStop(10);
        Observer.ObserveError('insert');
        RestoreMock(Mock, WasStarted);
        UnbindSubscription(Sub);
        Observer.Observe('ledger value seen', Format(LedgerValueSeen));
        Observer.Finish();
    end;

    [Test]
    procedure Subscriber_NoPermissionsProperty_NoMock_CO()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT CO Sub NoPerm";
    begin
        Init();
        BindSubscription(Sub);
        asserterror InsertSrcThenStop(11);
        Observer.ObserveError('insert');
        UnbindSubscription(Sub);
        Observer.Observe('ledger value seen', Format(LedgerValueSeen));
        Observer.Finish();
    end;

    local procedure CreateTaskThenStop()
    var
        TaskId: Guid;
        NullGuid: Guid;
    begin
        TaskId := TaskScheduler.CreateTask(Codeunit::"LT CO Task Noop", 0);
        Error('%1 id_null=%2', DoneTok, TaskId = NullGuid);
    end;

    [Test]
    procedure TaskScheduler_UnderMock_WithoutTaskRights_CO()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        WasStarted: Boolean;
    begin
        Observer.Observe('can create, no mock', Format(TaskScheduler.CanCreateTask()));
        WasStarted := StartMock(Mock);
        Mock.Set(UserSetTok);
        Observer.Observe('can create, mock', Format(TaskScheduler.CanCreateTask()));
        asserterror CreateTaskThenStop();
        Observer.ObserveError('create, mock');
        RestoreMock(Mock, WasStarted);
        asserterror CreateTaskThenStop();
        Observer.ObserveError('create, no mock');
        Observer.Finish();
    end;

    [Test]
    procedure WildcardPagePermission_MetadataPermissionRows_CO()
    var
        Observer: Codeunit "Probe Observer";
        MetadataPermission: Record "Metadata Permission";
        Rows: Text;
    begin
        MetadataPermission.SetRange("Role ID", 'LT CO Perm Wild');
        Observer.Observe('row count', Format(MetadataPermission.Count()));
        if MetadataPermission.FindSet() then
            repeat
                Rows += Format(MetadataPermission."Object Type") + ' ' + Format(MetadataPermission."Object ID") + ' R=' + Format(MetadataPermission."Read Permission") +
                    ' I=' + Format(MetadataPermission."Insert Permission") + ' M=' + Format(MetadataPermission."Modify Permission") +
                    ' D=' + Format(MetadataPermission."Delete Permission") + ' X=' + Format(MetadataPermission."Execute Permission") + ';';
            until MetadataPermission.Next() = 0;
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;

    [Test]
    procedure AccessByPermission_TestPageControls_CO()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Facts: TestPage "LT CO ABP Facts";
        WasStarted: Boolean;
    begin
        Facts.OpenView();
        Observer.Observe('no mock: first row', Facts.ID.Value());
        Observer.Observe('no mock: name visible', Format(Facts.Name.Visible()));
        Observer.Observe('no mock: action visible', Format(Facts.DeleteRight.Visible()));
        Observer.Observe('no mock: action enabled', Format(Facts.DeleteRight.Enabled()));
        Facts.Close();
        WasStarted := StartMock(Mock);
        Mock.Set(UserSetTok);
        Facts.OpenView();
        Observer.Observe('mock: first row', Facts.ID.Value());
        Observer.Observe('mock: name visible', Format(Facts.Name.Visible()));
        Observer.Observe('mock: action visible', Format(Facts.DeleteRight.Visible()));
        Observer.Observe('mock: action enabled', Format(Facts.DeleteRight.Enabled()));
        Facts.Close();
        RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;
}
