// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-settable-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained tables 70304, 70305 and codeunit 70306
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: RecordRef.SetTable(Rec) / GetTable(Rec) when the RecordRef holds another table; temporary and non temporary records in each direction; error start and code; whether buffer and filters move
// BC versions: 29 (27 and 28 by CI)

table 70304 "LT P81 RR A"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 70305 "LT P81 RR B"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 70306 "LT P81 RecordRef Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        A: Record "LT P81 RR A";
        B: Record "LT P81 RR B";
    begin
        A.DeleteAll();
        B.DeleteAll();
        A.Code := 'A1';
        A.Name := 'a-one';
        A.Qty := 1;
        A.Insert();
        A.Code := 'A2';
        A.Name := 'a-two';
        A.Qty := 2;
        A.Insert();
        B.Code := 'B1';
        B.Name := 'b-one';
        B.Qty := 10;
        B.Insert();
    end;

    [TryFunction]
    local procedure TrySetTableB(var RecRef: RecordRef; var B: Record "LT P81 RR B")
    begin
        RecRef.SetTable(B);
    end;

    [TryFunction]
    local procedure TrySetTableA(var RecRef: RecordRef; var A: Record "LT P81 RR A")
    begin
        RecRef.SetTable(A);
    end;

    [TryFunction]
    local procedure TryGetTableB(var RecRef: RecordRef; var B: Record "LT P81 RR B")
    begin
        RecRef.GetTable(B);
    end;

    local procedure ErrStart(): Text
    begin
        exit(CopyStr(GetLastErrorText(), 1, 40) + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure SetTable_OtherTable_Error()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT P81 RR A";
        B: Record "LT P81 RR B";
        RecRef: RecordRef;
    begin
        Seed();
        A.FindFirst();
        RecRef.GetTable(A);
        if TrySetTableB(RecRef, B) then
            Observer.Observe('settable_b', 'no error')
        else
            Observer.Observe('settable_b', ErrStart());
        Observer.Observe('text_has_table_a', Format(GetLastErrorText().Contains('LT P81 RR A')));
        Observer.Observe('text_has_table_b', Format(GetLastErrorText().Contains('LT P81 RR B')));
        Observer.Observe('b_code_after', B.Code);
        Observer.Observe('recref_number_ok', Format(RecRef.Number = Database::"LT P81 RR A"));
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_OtherTable_ReplacesRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT P81 RR A";
        B: Record "LT P81 RR B";
        RecRef: RecordRef;
    begin
        Seed();
        A.FindFirst();
        B.FindFirst();
        RecRef.GetTable(A);
        Observer.Observe('number_a', Format(RecRef.Number = Database::"LT P81 RR A"));
        RecRef.GetTable(B);
        Observer.Observe('number_b', Format(RecRef.Number = Database::"LT P81 RR B"));
        Observer.Observe('name_field', Format(RecRef.Field(2).Value));
        Observer.Observe('code_field', Format(RecRef.Field(1).Value));
        Observer.Finish();
    end;

    [Test]
    procedure SetTable_ClosedRecordRef_Error()
    var
        Observer: Codeunit "Probe Observer";
        B: Record "LT P81 RR B";
        RecRef: RecordRef;
    begin
        Seed();
        if TrySetTableB(RecRef, B) then
            Observer.Observe('settable_closed', 'no error')
        else
            Observer.Observe('settable_closed', ErrStart());
        Observer.Finish();
    end;

    [Test]
    procedure SetTable_OpenedOtherTable_Error()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT P81 RR A";
        RecRef: RecordRef;
    begin
        Seed();
        RecRef.Open(Database::"LT P81 RR B");
        if TrySetTableA(RecRef, A) then
            Observer.Observe('settable_a', 'no error')
        else
            Observer.Observe('settable_a', ErrStart());
        Observer.Finish();
    end;

    [Test]
    procedure TempToTemp_BufferAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        T1: Record "LT P81 RR A" temporary;
        T2: Record "LT P81 RR A" temporary;
        RecRef: RecordRef;
    begin
        Seed();
        T1.Code := 'T1';
        T1.Name := 'temp-one';
        T1.Qty := 5;
        T1.Insert();
        T1.Code := 'T2';
        T1.Name := 'temp-two';
        T1.Qty := 6;
        T1.Insert();
        T1.SetRange(Qty, 6, 9);
        T1.FindFirst();
        RecRef.GetTable(T1);
        Observer.Observe('recref_temp', Format(RecRef.IsTemporary()));
        Observer.Observe('recref_count', Format(RecRef.Count()));
        Observer.Observe('recref_filters', RecRef.GetFilters());
        RecRef.SetTable(T2);
        Observer.Observe('t2_temp', Format(T2.IsTemporary()));
        Observer.Observe('t2_count', Format(T2.Count()));
        Observer.Observe('t2_filters', T2.GetFilters());
        Observer.Observe('t2_name', T2.Name);
        Observer.Observe('t2_code', T2.Code);
        Observer.Finish();
    end;

    [Test]
    procedure TempRecord_GetTable_IntoNonTemporaryRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        T1: Record "LT P81 RR A" temporary;
        RecRef: RecordRef;
    begin
        Seed();
        T1.Code := 'T1';
        T1.Name := 'temp-one';
        T1.Insert();
        RecRef.Open(Database::"LT P81 RR A");
        Observer.Observe('opened_temp', Format(RecRef.IsTemporary()));
        Observer.Observe('opened_count', Format(RecRef.Count()));
        RecRef.GetTable(T1);
        Observer.Observe('after_gettable_temp', Format(RecRef.IsTemporary()));
        Observer.Observe('after_gettable_count', Format(RecRef.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure NonTempRecord_GetTable_IntoTemporaryRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT P81 RR A";
        RecRef: RecordRef;
    begin
        Seed();
        RecRef.Open(Database::"LT P81 RR A", true);
        Observer.Observe('opened_temp', Format(RecRef.IsTemporary()));
        Observer.Observe('opened_count', Format(RecRef.Count()));
        A.FindFirst();
        RecRef.GetTable(A);
        Observer.Observe('after_gettable_temp', Format(RecRef.IsTemporary()));
        Observer.Observe('after_gettable_count', Format(RecRef.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure TempRecordRef_SetTable_IntoNonTemporaryRecord()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT P81 RR A";
        RecRef: RecordRef;
    begin
        Seed();
        RecRef.Open(Database::"LT P81 RR A", true);
        RecRef.Field(1).Value := 'R1';
        RecRef.Field(2).Value := 'ref-temp';
        RecRef.Insert();
        if TrySetTableA(RecRef, A) then
            Observer.Observe('settable', 'no error')
        else
            Observer.Observe('settable', ErrStart());
        Observer.Observe('a_temp', Format(A.IsTemporary()));
        Observer.Observe('a_count', Format(A.Count()));
        Observer.Observe('a_name', A.Name);
        Observer.Finish();
    end;

    [Test]
    procedure NonTempRecordRef_SetTable_IntoTemporaryRecord()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT P81 RR A";
        T: Record "LT P81 RR A" temporary;
        RecRef: RecordRef;
    begin
        Seed();
        A.FindFirst();
        RecRef.GetTable(A);
        if TrySetTableA(RecRef, T) then
            Observer.Observe('settable', 'no error')
        else
            Observer.Observe('settable', ErrStart());
        Observer.Observe('t_temp', Format(T.IsTemporary()));
        Observer.Observe('t_count', Format(T.Count()));
        Observer.Observe('t_name', T.Name);
        Observer.Finish();
    end;

    [Test]
    procedure NonTempToNonTemp_BufferAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT P81 RR A";
        A2: Record "LT P81 RR A";
        RecRef: RecordRef;
    begin
        Seed();
        A.SetRange(Qty, 2, 3);
        A.FindFirst();
        RecRef.GetTable(A);
        Observer.Observe('recref_filters', RecRef.GetFilters());
        Observer.Observe('recref_count', Format(RecRef.Count()));
        RecRef.SetTable(A2);
        Observer.Observe('a2_filters', A2.GetFilters());
        Observer.Observe('a2_count', Format(A2.Count()));
        Observer.Observe('a2_code', A2.Code);
        Observer.Observe('a2_name', A2.Name);
        Observer.Observe('a2_temp', Format(A2.IsTemporary()));
        Observer.Finish();
    end;

    [Test]
    procedure SetTable_UnsavedBuffer_Moves()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT P81 RR A";
        A2: Record "LT P81 RR A";
        RecRef: RecordRef;
    begin
        Seed();
        A.Code := 'NEW';
        A.Name := 'not inserted';
        A.Qty := 77;
        RecRef.GetTable(A);
        Observer.Observe('field_name', Format(RecRef.Field(2).Value));
        Observer.Observe('field_qty', Format(RecRef.Field(3).Value));
        RecRef.Field(3).Value := 78;
        RecRef.SetTable(A2);
        Observer.Observe('a2_code', A2.Code);
        Observer.Observe('a2_name', A2.Name);
        Observer.Observe('a2_qty', Format(A2.Qty));
        Observer.Observe('a_qty_still', Format(A.Qty));
        Observer.Observe('db_has_new', Format(A.Get('NEW')));
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_TempRecord_NoFilterOnRecRefWhenRecordFiltered()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P81 RR A" temporary;
        T2: Record "LT P81 RR A" temporary;
        RecRef: RecordRef;
    begin
        T.Code := 'X1';
        T.Qty := 1;
        T.Insert();
        T.Code := 'X2';
        T.Qty := 2;
        T.Insert();
        T.SetFilter(Qty, '>1');
        RecRef.GetTable(T);
        Observer.Observe('recref_count', Format(RecRef.Count()));
        RecRef.Reset();
        Observer.Observe('recref_count_after_reset', Format(RecRef.Count()));
        Observer.Observe('t_filters_after_recref_reset', T.GetFilters());
        RecRef.SetTable(T2);
        Observer.Observe('t2_count', Format(T2.Count()));
        Observer.Observe('t2_filters', T2.GetFilters());
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_TempRecord_RecRefChangesVisibleInRecord()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P81 RR A" temporary;
        RecRef: RecordRef;
    begin
        T.Code := 'X1';
        T.Qty := 1;
        T.Insert();
        RecRef.GetTable(T);
        RecRef.Field(1).Value := 'X9';
        RecRef.Field(3).Value := 9;
        RecRef.Insert();
        Observer.Observe('t_count', Format(T.Count()));
        Observer.Observe('recref_count', Format(RecRef.Count()));
        Observer.Observe('t_has_x9', Format(T.Get('X9')));
        Observer.Finish();
    end;

    local procedure RecRefCountDb(): Integer
    var
        A: Record "LT P81 RR A";
    begin
        exit(A.Count());
    end;

    [Test]
    procedure GetTable_Variant_OfOtherTable_ThenSetTable()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT P81 RR A";
        B: Record "LT P81 RR B";
        V: Variant;
        RecRef: RecordRef;
    begin
        Seed();
        A.FindFirst();
        V := A;
        RecRef.GetTable(V);
        Observer.Observe('number_ok', Format(RecRef.Number = Database::"LT P81 RR A"));
        if TrySetTableB(RecRef, B) then
            Observer.Observe('settable_b', 'no error')
        else
            Observer.Observe('settable_b', ErrStart());
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_IntoRecRefOfSameTable_KeepsOldFilters()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT P81 RR A";
        A2: Record "LT P81 RR A";
        RecRef: RecordRef;
    begin
        Seed();
        RecRef.Open(Database::"LT P81 RR A");
        RecRef.Field(3).SetRange(1);
        Observer.Observe('before', RecRef.GetFilters());
        A.FindFirst();
        RecRef.GetTable(A);
        Observer.Observe('after_unfiltered_gettable', RecRef.GetFilters());
        A2.SetRange(Qty, 2);
        RecRef.GetTable(A2);
        Observer.Observe('after_filtered_gettable', RecRef.GetFilters());
        Observer.Observe('count', Format(RecRef.Count()));
        Observer.Finish();
    end;
}
