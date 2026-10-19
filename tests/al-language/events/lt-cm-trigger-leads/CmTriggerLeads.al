// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-validate-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-variables
// Scope: in-scope
// Fixtures used: CmTriggerObjects.al in this folder (84820-84829, 84831-84833), Probe Observer (69160).
// Facts: corpus issue 669 (odd AL behavior leads, part D), items 31, 33 to 40.
// BC versions: 27, 28, 29

codeunit 84830 "LT CM Trigger Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT CM Log";

    local procedure Reset()
    var
        Row: Record "LT CM Row";
        Parent: Record "LT CM Parent";
        LogRow: Record "LT CM Log Row";
        TempRow: Record "LT CM Temp Row";
        Src: Record "LT CM Src";
        Backup: Record "LT CM Backup";
        InsRow: Record "LT CM Ins Row";
    begin
        Row.DeleteAll();
        Parent.DeleteAll();
        LogRow.DeleteAll();
        TempRow.DeleteAll();
        Src.DeleteAll();
        Backup.DeleteAll();
        InsRow.DeleteAll();
        Log.Take();
    end;

    local procedure SeedRow(Id: Integer; Name: Text[30]; Note: Text[30])
    var
        Row: Record "LT CM Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Name := Name;
        Row.Note := Note;
        Row.Insert(false);
    end;

    local procedure LogRows() Result: Text
    var
        LogRow: Record "LT CM Log Row";
    begin
        if LogRow.FindSet() then
            repeat
                Result += LogRow.Txt + ';';
            until LogRow.Next() = 0;
    end;

    // Item 31: a table extension procedure assigns CurrFieldNo, then calls Modify(true); the base OnModify reads it.
    [Test]
    procedure Item31_TableExtension_AssignsCurrFieldNo()
    var
        Row: Record "LT CM Row";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        SeedRow(1, 'n', '');
        Row.Get(1);
        Row.CmAssignCurrFieldNoThenModify(10);
        Observer.Observe('modify after ext assigns 10', Log.Take());
        Observer.Finish();
    end;

    // Item 33: Rec.Validate on a field with a TableRelation and an OnValidate trigger, value not in the related table.
    [Test]
    procedure Item33_Validate_BadRelation_TriggerRuns()
    var
        Row: Record "LT CM Row";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Row.Id := 1;
        asserterror Row.Validate(Rel, 'NOPE');
        Observer.ObserveError('validate NOPE');
        Observer.Observe('log', Log.Take());
        Observer.Observe('value after', Row.Rel);
        Observer.Finish();
    end;

    // Item 33: the same through FieldRef.Validate(Value), and FieldRef.Validate() without a value on an assigned bad value.
    [Test]
    procedure Item33_FieldRefValidate_BadRelation()
    var
        Row: Record "LT CM Row";
        RecRef: RecordRef;
        Fld: FieldRef;
        Parent: Record "LT CM Parent";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Row.Id := 1;
        RecRef.GetTable(Row);
        Fld := RecRef.Field(Row.FieldNo(Rel));
        asserterror Fld.Validate('NOPE');
        Observer.ObserveError('fieldref validate NOPE');
        Observer.Observe('log 1', Log.Take());
        Fld.Value := 'NOPE2';
        asserterror Fld.Validate();
        Observer.ObserveError('fieldref validate() on NOPE2');
        Observer.Observe('log 2', Log.Take());
        Parent.Code := 'P1';
        Parent.Insert();
        Fld.Validate('P1');
        Observer.Observe('log 3 good value', Log.Take());
        Observer.Observe('value 3', Format(Fld.Value));
        Fld := RecRef.Field(Row.FieldNo("Rel False"));
        Fld.Validate('NOPE3');
        Observer.Observe('log 4 relation false', Log.Take());
        Observer.Observe('value 4', Format(Fld.Value));
        Observer.Finish();
    end;

    // Item 34: ValidateTableRelation = true and = false on a table field, and the three forms on a tableextension field.
    [Test]
    procedure Item34_ValidateTableRelation_Property()
    var
        Row: Record "LT CM Row";
        InsRow: Record "LT CM Ins Row";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        asserterror Row.Validate("Rel True", 'NOPE');
        Observer.ObserveError('table true');
        Row.Validate("Rel False", 'NOPE');
        Observer.Observe('table false value', Row."Rel False");
        Log.Take();
        asserterror InsRow.Validate("Ext Rel", 'NOPE');
        Observer.ObserveError('ext default');
        asserterror InsRow.Validate("Ext Rel True", 'NOPE');
        Observer.ObserveError('ext true');
        InsRow.Validate("Ext Rel False", 'NOPE');
        Observer.Observe('ext false value', InsRow."Ext Rel False");
        Observer.Finish();
    end;

    // Item 35: fields set by a table extension's OnBeforeInsert, OnInsert and OnAfterInsert; in memory and in the database.
    [Test]
    procedure Item35_TableExtensionInsertTriggers_WhatIsStored()
    var
        InsRow: Record "LT CM Ins Row";
        Stored: Record "LT CM Ins Row";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        InsRow.Id := 1;
        InsRow.Insert(true);
        Observer.Observe('true memory', InsRow."Set By Before" + '|' + InsRow."Set By Insert" + '|' + InsRow."Set By After");
        Stored.Get(1);
        Observer.Observe('true stored', Stored."Set By Before" + '|' + Stored."Set By Insert" + '|' + Stored."Set By After");
        Clear(InsRow);
        InsRow.Id := 2;
        InsRow.Insert(false);
        Observer.Observe('false memory', InsRow."Set By Before" + '|' + InsRow."Set By Insert" + '|' + InsRow."Set By After");
        Stored.Get(2);
        Observer.Observe('false stored', Stored."Set By Before" + '|' + Stored."Set By Insert" + '|' + Stored."Set By After");
        Clear(InsRow);
        InsRow.Id := 3;
        InsRow.Insert();
        Stored.Get(3);
        Observer.Observe('no argument stored', Stored."Set By Before" + '|' + Stored."Set By Insert" + '|' + Stored."Set By After");
        Finish35(Observer);
    end;

    local procedure Finish35(var Observer: Codeunit "Probe Observer")
    var
        InsRow: Record "LT CM Ins Row";
        Stored: Record "LT CM Ins Row";
    begin
        // A Modify after Insert(true) stores what OnAfterInsert left in the variable.
        InsRow.Id := 4;
        InsRow.Insert(true);
        InsRow.Modify();
        Stored.Get(4);
        Observer.Observe('true then modify stored', Stored."Set By Before" + '|' + Stored."Set By Insert" + '|' + Stored."Set By After");
        Observer.Finish();
    end;

    // Item 36: inside OnInsert, a row of another table inserted with the SystemId of the row being inserted, found by GetBySystemId.
    [Test]
    procedure Item36_GetBySystemId_InsideOnInsert()
    var
        Src: Record "LT CM Src";
        Backup: Record "LT CM Backup";
        Observer: Codeunit "Probe Observer";
        Mode: Integer;
    begin
        Reset();
        for Mode := 1 to 3 do begin
            Clear(Src);
            Src.Id := Mode;
            Src.Name := 'n' + Format(Mode);
            Src.Mode := Mode;
            Src.Insert(true);
            Observer.Observe('mode ' + Format(Mode), Log.Take());
            Backup.Get(Mode);
            Observer.Observe('mode ' + Format(Mode) + ' stored same sysid', Format(Backup.SystemId = Src.SystemId));
        end;
        Observer.Finish();
    end;

    // Item 37: triggers of a temporary record write to a real table and delete a real related row.
    [Test]
    procedure Item37_TemporaryRecord_TriggersTouchRealTables()
    var
        TempRow: Record "LT CM Temp Row" temporary;
        RealRow: Record "LT CM Temp Row";
        Parent: Record "LT CM Parent";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Parent.Code := '1';
        Parent.Insert();
        Parent.Code := '2';
        Parent.Insert();
        Parent.Code := '3';
        Parent.Insert();
        RealRow.Id := 9;
        RealRow.Insert(false);

        TempRow.Id := 1;
        TempRow.Insert(true);
        TempRow.Modify(true);
        TempRow.Delete(true);
        Observer.Observe('real log after insert, modify, delete (true)', LogRows());
        Observer.Observe('real parents after delete(true)', ParentCodes());

        TempRow.Id := 2;
        TempRow.Insert(false);
        TempRow.Id := 3;
        TempRow.Insert(false);
        TempRow.Get(2);
        TempRow.Delete(false);
        Observer.Observe('real parents after delete(false)', ParentCodes());
        TempRow.DeleteAll(true);
        Observer.Observe('real log after DeleteAll(true)', LogRows());
        Observer.Observe('real parents after DeleteAll(true)', ParentCodes());
        TempRow.Id := 4;
        TempRow.Insert(false);
        TempRow.DeleteAll();
        Observer.Observe('real rows after temp DeleteAll()', Format(RealRow.Count()));
        Observer.Observe('temp rows after DeleteAll()', Format(TempRow.Count()));
        Observer.Finish();
    end;

    local procedure ParentCodes() Result: Text
    var
        Parent: Record "LT CM Parent";
    begin
        if Parent.FindSet() then
            repeat
                Result += Parent.Code + ',';
            until Parent.Next() = 0;
    end;

    // Item 38: xRec inside OnValidate: the value before Validate, unchanged by assignments to Rec and by a nested Validate.
    [Test]
    procedure Item38_XRecInsideOnValidateAndOnModify()
    var
        Row: Record "LT CM Row";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        SeedRow(1, 'old', 'oldnote');
        Row.Get(1);
        Row.Validate(Name, 'new');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('after validate', Row.Name + '|' + Row.Note);
        Row.Modify(true);
        Observer.Observe('modify log', Log.Take());
        Observer.Observe('after modify', Row.Note);
        Row.Get(1);
        Observer.Observe('stored after modify', Row.Name + '|' + Row.Note);
        Observer.Finish();
    end;

    // Item 39: Rec and xRec in OnBeforeModify / OnAfterModify subscribers and the OnModify trigger.
    [Test]
    procedure Item39_ModifyEvents_RecAndXRec()
    var
        Row: Record "LT CM Row";
        Subs: Codeunit "LT CM Modify Subs";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        SeedRow(1, 'stored', '');
        BindSubscription(Subs);
        // (a) Get, assign, Modify.
        Row.Get(1);
        Row.Name := 'a';
        Row.Modify(true);
        Observer.Observe('a get assign modify', Log.Take());
        // (b) a record never read: only the key and the new value set.
        Clear(Row);
        Row.Id := 1;
        Row.Name := 'b';
        Row.Modify(true);
        Observer.Observe('b never read', Log.Take());
        // (c) Get, Validate a field, Modify.
        Row.Get(1);
        Row.Validate(Amount, 5);
        Row.Name := 'c';
        Row.Modify(true);
        Observer.Observe('c validate then modify', Log.Take());
        UnbindSubscription(Subs);
        Observer.Finish();
    end;

    // Item 39: the same events for an edit through a card TestPage.
    [Test]
    procedure Item39_ModifyEvents_PageEdit()
    var
        Card: TestPage "LT CM Card";
        Subs: Codeunit "LT CM Modify Subs";
        Row: Record "LT CM Row";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        SeedRow(1, 'stored', '');
        BindSubscription(Subs);
        Row.Get(1);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('pg');
        Card.Close();
        UnbindSubscription(Subs);
        Observer.Observe('page edit', Log.Take());
        Observer.Finish();
    end;

    // Item 40: a new row through a list TestPage, without a filter, with a filter the new key is outside, and inside.
    [Test]
    procedure Item40_PageInsert_FilteredView()
    var
        Row: Record "LT CM Row";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Observer.Observe('no filter', Format(TryNewRow('', 9)));
        Observer.ObserveError('no filter');
        Observer.Observe('no filter log', Log.Take());
        Observer.Observe('no filter stored', Format(Row.Get(9)));
        Observer.Observe('filter 1..5, key 7', Format(TryNewRow('1..5', 7)));
        Observer.ObserveError('filter 1..5, key 7');
        Observer.Observe('filter 1..5, key 7 log', Log.Take());
        Observer.Observe('filter 1..5, key 7 stored', Format(Row.Get(7)));
        Observer.Observe('filter 1..5, key 3', Format(TryNewRow('1..5', 3)));
        Observer.ObserveError('filter 1..5, key 3');
        Observer.Observe('filter 1..5, key 3 log', Log.Take());
        Observer.Observe('filter 1..5, key 3 stored', Format(Row.Get(3)));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryNewRow(Filter: Text; Id: Integer)
    var
        List: TestPage "LT CM List";
    begin
        List.OpenEdit();
        if Filter <> '' then
            List.Filter.SetFilter(Id, Filter);
        List.New();
        List.Id.SetValue(Id);
        List.Amount.SetValue(1);
        List.Close();
    end;
}
