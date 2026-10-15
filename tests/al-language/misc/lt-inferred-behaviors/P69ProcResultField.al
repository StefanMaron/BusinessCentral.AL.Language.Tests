// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-return-values
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 71160, codeunit 71161
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles GitHub issue #69 (Inferred behaviors waiting for a pin): a field read off a procedure result
// Facts: GetRec(Code).Field when the row does not exist, a record that was Init'ed inside the procedure (InitValue), nested in expressions, with a quoted field name, from a var-less temporary record, chained twice
// BC versions: 29 (27 and 28 by CI)

table 71160 "LT P69 Ret Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; "Quoted Name"; Text[30]) { }
        field(3; Qty; Decimal) { InitValue = 7; }
        field(4; Flag; Boolean) { InitValue = true; }
        field(5; Kind; Option) { OptionMembers = Zero,One,Two; InitValue = Two; }
        field(6; "Posted On"; Date) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 71161 "LT P69 Proc Result Field"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure GetRow(CodeValue: Code[10]): Record "LT P69 Ret Row"
    var
        Row: Record "LT P69 Ret Row";
    begin
        if not Row.Get(CodeValue) then
            Row.Init();
        exit(Row);
    end;

    local procedure InitOnly(): Record "LT P69 Ret Row"
    var
        Row: Record "LT P69 Ret Row";
    begin
        Row.Init();
        exit(Row);
    end;

    local procedure InitWithKey(CodeValue: Code[10]): Record "LT P69 Ret Row"
    var
        Row: Record "LT P69 Ret Row";
    begin
        Row.Init();
        Row.Code := CodeValue;
        exit(Row);
    end;

    local procedure Temp(): Record "LT P69 Ret Row" temporary
    var
        Row: Record "LT P69 Ret Row" temporary;
    begin
        Row.Code := 'TMP';
        Row."Quoted Name" := 'temporary';
        Row.Insert();
        exit(Row);
    end;

    local procedure Seed()
    var
        Row: Record "LT P69 Ret Row";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row."Quoted Name" := 'alpha';
        Row.Qty := 2.5;
        Row.Flag := false;
        Row.Kind := Row.Kind::One;
        Row."Posted On" := DMY2Date(5, 6, 2021);
        Row.Insert();
    end;

    [Test]
    procedure ProcResult_ExistingRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('code', GetRow('A').Code);
        Observer.Observe('quoted', GetRow('A')."Quoted Name");
        Observer.Observe('qty', Format(GetRow('A').Qty));
        Observer.Observe('flag', Format(GetRow('A').Flag));
        Observer.Observe('kind', Format(GetRow('A').Kind));
        Observer.Observe('date', Format(GetRow('A')."Posted On", 0, 9));
        Observer.Observe('qty_expr', Format(GetRow('A').Qty * 2 + 1));
        Observer.Observe('text_expr', GetRow('A')."Quoted Name" + '-' + GetRow('A').Code);
        Observer.Observe('compare', Format(GetRow('A').Qty > 2));
        Observer.Observe('date_expr', Format(GetRow('A')."Posted On" + 1, 0, 9));
        Observer.Observe('strlen', Format(StrLen(GetRow('A')."Quoted Name")));
        Observer.Expect('code', 'A');
        Observer.Expect('quoted', 'alpha');
        Observer.Expect('qty', '2.5');
        Observer.Expect('flag', 'No');
        Observer.Expect('kind', 'One');
        Observer.Expect('date', '2021-06-05');
        Observer.Expect('qty_expr', '6');
        Observer.Expect('text_expr', 'alpha-A');
        Observer.Expect('compare', 'Yes');
        Observer.Expect('date_expr', '2021-06-06');
        Observer.Expect('strlen', '5');
        Observer.Verify();
    end;

    [Test]
    procedure ProcResult_MissingRowInit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('code', GetRow('NONE').Code);
        Observer.Observe('quoted', GetRow('NONE')."Quoted Name");
        Observer.Observe('qty_initvalue', Format(GetRow('NONE').Qty));
        Observer.Observe('flag_initvalue', Format(GetRow('NONE').Flag));
        Observer.Observe('kind_initvalue', Format(GetRow('NONE').Kind));
        Observer.Observe('date', Format(GetRow('NONE')."Posted On", 0, 9));
        Observer.Observe('qty_expr', Format(GetRow('NONE').Qty * 2));
        Observer.Observe('text_len', Format(StrLen(GetRow('NONE')."Quoted Name")));
        Observer.Expect('code', '');
        Observer.Expect('quoted', '');
        Observer.Expect('qty_initvalue', '7');
        Observer.Expect('flag_initvalue', 'Yes');
        Observer.Expect('kind_initvalue', 'Two');
        Observer.Expect('date', '');
        Observer.Expect('qty_expr', '14');
        Observer.Expect('text_len', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ProcResult_InitOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('code', InitOnly().Code);
        Observer.Observe('qty', Format(InitOnly().Qty));
        Observer.Observe('flag', Format(InitOnly().Flag));
        Observer.Observe('kind', Format(InitOnly().Kind));
        Observer.Observe('kind_ordinal', Format(InitOnly().Kind, 0, 2));
        Observer.Observe('with_key_code', InitWithKey('KEY').Code);
        Observer.Observe('with_key_qty', Format(InitWithKey('KEY').Qty));
        Observer.Observe('with_key_name', InitWithKey('KEY')."Quoted Name");
        Observer.Expect('code', '');
        Observer.Expect('qty', '7');
        Observer.Expect('flag', 'Yes');
        Observer.Expect('kind', 'Two');
        Observer.Expect('kind_ordinal', '2');
        Observer.Expect('with_key_code', 'KEY');
        Observer.Expect('with_key_qty', '7');
        Observer.Expect('with_key_name', '');
        Observer.Verify();
    end;

    [Test]
    procedure ProcResult_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P69 Ret Row";
    begin
        Seed();
        Observer.Observe('code', Temp().Code);
        Observer.Observe('name', Temp()."Quoted Name");
        Observer.Observe('qty', Format(Temp().Qty));
        Observer.Observe('stored_rows', Format(Row.Count()));
        Observer.Observe('is_temporary', Format(Temp().IsTemporary()));
        Observer.Expect('code', 'TMP');
        Observer.Expect('name', 'temporary');
        Observer.Expect('qty', '7');
        Observer.Expect('stored_rows', '1');
        Observer.Expect('is_temporary', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ProcResult_MethodOnResult()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('tablename', GetRow('A').TableName());
        Observer.Observe('count', Format(GetRow('A').Count()));
        Observer.Observe('fieldno', Format(GetRow('A').FieldNo(Qty)));
        Observer.Observe('getfilters', GetRow('A').GetFilters());
        Observer.Observe('rowcount_missing', Format(GetRow('NONE').Count()));
        Observer.Expect('tablename', 'LT P69 Ret Row');
        Observer.Expect('count', '1');
        Observer.Expect('fieldno', '3');
        Observer.Expect('getfilters', '');
        Observer.Expect('rowcount_missing', '1');
        Observer.Verify();
    end;
}
