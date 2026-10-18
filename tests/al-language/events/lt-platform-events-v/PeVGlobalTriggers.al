// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-triggers-and-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT V Subs, LT V Log and the LT V Row A - I tables of PeVFixtures.al
// Global Triggers events (GetGlobalTableTriggerMask, GetDatabaseTableTriggerSetup, OnGlobal* and OnDatabase*): when each fires, its arguments, and what a subscriber that changes
// the var arguments (mask, the four setup flags) or the record it is handed does to the write. Every scenario uses its own table, because the platform asks for mask and setup once per table.
// BC versions: 27 - 29

codeunit 69852 "LT V Global Trigger Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT V Log";

    local procedure Cycle(TableNo: Integer; Observer: Codeunit "Probe Observer")
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
        RecRef.DeleteAll();
        Observer.Observe('open_and_deleteall', Log.Take());
        RecRef.Init();
        RecRef.Field(1).Value := 1;
        RecRef.Field(2).Value := 'a';
        RecRef.Field(3).Value := 1.5;
        RecRef.Insert(true);
        Observer.Observe('insert', Log.Take());
        RecRef.Field(2).Value := 'b';
        RecRef.Field(3).Value := 2.5;
        RecRef.Modify(true);
        Observer.Observe('modify', Log.Take());
        RecRef.Rename(2);
        Observer.Observe('rename', Log.Take());
        RecRef.Delete(true);
        Observer.Observe('delete', Log.Take());
        RecRef.Close();
        Log.Stop();
    end;

    [Test]
    procedure GlobalTriggers_SubscriberLeavesDefaults_RowA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row A", Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_MaskFifteenAndAllSetupFlagsFalse_RowB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row B", Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_MaskZeroAndAllSetupFlagsTrue_RowC()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row C", Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_MaskFifteenAndAllSetupFlagsTrue_Arguments_RowD()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row D", Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_OnlyInsertFlag_RowE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row E", Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_OnlyModifyFlag_RowF()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row F", Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_OnlyDeleteFlag_RowG()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row G", Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_OnlyRenameFlag_RowH()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row H", Observer);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryMutatingInsert(var RecRef: RecordRef)
    begin
        RecRef.Insert(true);
    end;

    [TryFunction]
    local procedure TryMutatingModify(var RecRef: RecordRef)
    begin
        RecRef.Modify(true);
    end;

    [Test]
    procedure GlobalTriggers_SubscriberChangesTheRecordItIsHanded_RowI()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Check: Record "LT V Row I";
    begin
        Log.Start();
        RecRef.Open(Database::"LT V Row I");
        RecRef.DeleteAll();
        Observer.Observe('open_and_deleteall', Log.Take());
        RecRef.Init();
        RecRef.Field(1).Value := 1;
        RecRef.Field(2).Value := 'a';
        RecRef.Field(3).Value := 1.5;
        Observer.Observe('insert_ok', Format(TryMutatingInsert(RecRef)));
        Observer.ObserveError('insert_error');
        Observer.Observe('insert_log', Log.Take());
        Observer.Observe('variable_after_insert', Format(RecRef.Field(2).Value) + '/' + Format(RecRef.Field(3).Value));
        Observer.Observe('found', Format(Check.Get(1)));
        Observer.Observe('stored_after_insert', Check.Name + '/' + Format(Check.Amount));
        RecRef.Field(2).Value := 'b';
        RecRef.Field(3).Value := 2.5;
        Observer.Observe('modify_ok', Format(TryMutatingModify(RecRef)));
        Observer.ObserveError('modify_error');
        Observer.Observe('modify_log', Log.Take());
        Observer.Observe('variable_after_modify', Format(RecRef.Field(2).Value) + '/' + Format(RecRef.Field(3).Value));
        Observer.Observe('found_again', Format(Check.Get(1)));
        Observer.Observe('stored_after_modify', Check.Name + '/' + Format(Check.Amount));
        RecRef.Close();
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_InsertWithoutTrigger_DoesNotAskOrRaise()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT V Row D";
    begin
        // Row D was asked in the test above, so this checks the raise, not the ask: Insert(false) and Modify(false) run no trigger and raise no event.
        Log.Start();
        Row.Id := 5;
        Row.Name := 'quiet';
        Row.Insert(false);
        Observer.Observe('insert_false', Log.Take());
        Row.Name := 'quiet2';
        Row.Modify(false);
        Observer.Observe('modify_false', Log.Take());
        Row.Delete(false);
        Observer.Observe('delete_false', Log.Take());
        Row.Id := 6;
        Row.Insert(true);
        Observer.Observe('insert_true', Log.Take());
        Row.Delete(true);
        Observer.Observe('delete_true', Log.Take());
        Log.Stop();
        Observer.Finish();
    end;
}
