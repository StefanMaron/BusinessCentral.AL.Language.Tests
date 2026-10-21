// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-fields
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in QrSystemIdObjects.al (87285 - 87288)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a SystemId set during Insert by a table extension's OnBeforeInsert, OnInsert or OnAfterInsert trigger, by an OnAfterInsertEvent
//   subscriber, by the table's OnInsert or an OnBeforeInsertEvent subscriber to the SystemId of a row that already exists, by a table
//   extension trigger on a temporary record and through RecordRef.Insert: is it kept in the caller's variable and in the stored row,
//   without InsertWithSystemId. Already pinned elsewhere: the table's own OnInsert (record/lt-at-partner-gaps/AtSystemIdOnInsert.al) and
//   an OnBeforeInsertEvent subscriber with a new id (record/lt-af-record-events/AfSystemIdBeforeInsert.al).
// BC versions: 27, 28, 29

codeunit 87289 "LT QR SystemId Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        State: Codeunit "LT QR Sys State";

    local procedure Run(var Observer: Codeunit "Probe Observer"; Name: Text; Mode: Integer; RunTrigger: Boolean)
    var
        Row: Record "LT QR Sys Row";
        Stored: Record "LT QR Sys Row";
        Wanted: Guid;
        Empty: Guid;
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Wanted := CreateGuid();
        State.Arm(Mode, Wanted);
        Row.Init();
        Row.Id := 1;
        Row.Note := 'n';
        Ok := Row.Insert(RunTrigger);
        State.Arm(0, Empty);
        Observer.Observe(Name + '|insert', Format(Ok));
        Observer.Observe(Name + '|caller keeps', Format(Row.SystemId = Wanted));
        Observer.Observe(Name + '|caller null', Format(IsNullGuid(Row.SystemId)));
        Observer.Observe(Name + '|stored', Format(Stored.Get(1)));
        Observer.Observe(Name + '|stored keeps', Format(Stored.SystemId = Wanted));
        Observer.Observe(Name + '|stored = caller', Format(Stored.SystemId = Row.SystemId));
        Clear(Stored);
        Observer.Observe(Name + '|GetBySystemId(wanted)', Format(Stored.GetBySystemId(Wanted)));
    end;

    [Test]
    procedure QR_TableExt_OnBeforeInsert()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'ext before', 1, true);
        Observer.Finish();
    end;

    [Test]
    procedure QR_TableExt_OnInsert()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'ext oninsert', 2, true);
        Observer.Finish();
    end;

    [Test]
    procedure QR_TableExt_OnAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'ext after', 3, true);
        Observer.Finish();
    end;

    [Test]
    procedure QR_TableExt_Triggers_InsertFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'ext before false', 1, false);
        Observer.Finish();
    end;

    [Test]
    procedure QR_Subscriber_OnAfterInsertEvent()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "LT QR Sys Subscriber";
    begin
        BindSubscription(Subscriber);
        Run(Observer, 'sub after', 4, false);
        Run(Observer, 'sub after true', 4, true);
        UnbindSubscription(Subscriber);
        Observer.Finish();
    end;

    [Test]
    procedure QR_RecordRef_Insert_TableExtOnBeforeInsert()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QR Sys Row";
        RecRef: RecordRef;
        IdRef: FieldRef;
        Wanted: Guid;
        Empty: Guid;
    begin
        Row.DeleteAll();
        Wanted := CreateGuid();
        State.Arm(1, Wanted);
        RecRef.Open(Database::"LT QR Sys Row");
        RecRef.Init();
        IdRef := RecRef.Field(1);
        IdRef.Value := 1;
        Observer.Observe('insert', Format(RecRef.Insert(true)));
        State.Arm(0, Empty);
        IdRef := RecRef.Field(RecRef.SystemIdNo());
        Observer.Observe('recref keeps', Format(Format(IdRef.Value) = Format(Wanted)));
        Observer.Observe('stored keeps', Format(Row.GetBySystemId(Wanted)));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure QR_Temporary_TableExtOnInsert()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT QR Sys Row" temporary;
        Wanted: Guid;
        Empty: Guid;
    begin
        Wanted := CreateGuid();
        State.Arm(2, Wanted);
        Temp.Init();
        Temp.Id := 1;
        Observer.Observe('insert', Format(Temp.Insert(true)));
        State.Arm(0, Empty);
        Observer.Observe('caller keeps', Format(Temp.SystemId = Wanted));
        Observer.Observe('caller null', Format(IsNullGuid(Temp.SystemId)));
        Temp.Get(1);
        Observer.Observe('get keeps', Format(Temp.SystemId = Wanted));
        Observer.Observe('get null', Format(IsNullGuid(Temp.SystemId)));
        Observer.Finish();
    end;

    [Test]
    procedure QR_OnInsert_DuplicateOfExistingRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QR Sys Row";
        First: Record "LT QR Sys Row";
        Empty: Guid;
    begin
        Row.DeleteAll();
        First.Init();
        First.Id := 1;
        First.Insert();
        State.Arm(5, First.SystemId);
        Row.Init();
        Row.Id := 2;
        asserterror Row.Insert(true);
        State.Arm(0, Empty);
        Observer.ObserveError('duplicate');
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure QR_Subscriber_OnBeforeInsert_DuplicateOfExistingRow()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "LT QR Sys Subscriber";
        Row: Record "LT QR Sys Row";
        First: Record "LT QR Sys Row";
        Empty: Guid;
    begin
        Row.DeleteAll();
        First.Init();
        First.Id := 1;
        First.Insert();
        BindSubscription(Subscriber);
        State.Arm(6, First.SystemId);
        Row.Init();
        Row.Id := 2;
        asserterror Row.Insert();
        State.Arm(0, Empty);
        UnbindSubscription(Subscriber);
        Observer.ObserveError('duplicate');
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Finish();
    end;
}
