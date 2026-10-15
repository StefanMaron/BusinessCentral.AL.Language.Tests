// Probe (observe only): FlowFields over SystemRowVersion (min / max), type pairs BigInteger -> Integer and Average Integer -> BigInteger, two conditions on one source field,
// and a minus sign before min / max / lookup.
// Settles docs/probes-needed.md rows 78, 79, 84, 85 (batch 4). Object ids 68040 - 68042.
// Rows 78 and 79 are about BC 29: the values depend on the BC version of the tier (run them on every tier and keep the answer per tier).

table 68040 "W4 CF Line"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Doc; Code[10]) { }
        field(3; Tag; Code[10]) { }
        field(4; Qty; Integer) { }
        field(5; Big; BigInteger) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 68041 "W4 CF Head"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "No."; Code[10]) { }
        field(10; SrvMin; BigInteger) { FieldClass = FlowField; CalcFormula = min("W4 CF Line".SystemRowVersion where(Doc = field("No."))); Editable = false; }
        field(11; SrvMax; BigInteger) { FieldClass = FlowField; CalcFormula = max("W4 CF Line".SystemRowVersion where(Doc = field("No."))); Editable = false; }
        field(12; BigToInt; Integer) { FieldClass = FlowField; CalcFormula = sum("W4 CF Line".Big where(Doc = field("No."))); Editable = false; }
        field(13; AvgIntToBig; BigInteger) { FieldClass = FlowField; CalcFormula = average("W4 CF Line".Qty where(Doc = field("No."))); Editable = false; }
        field(14; SumIntToBig; BigInteger) { FieldClass = FlowField; CalcFormula = sum("W4 CF Line".Qty where(Doc = field("No."))); Editable = false; }
        field(15; MaxBigToInt; Integer) { FieldClass = FlowField; CalcFormula = max("W4 CF Line".Big where(Doc = field("No."))); Editable = false; }
        field(16; LookupBigToInt; Integer) { FieldClass = FlowField; CalcFormula = lookup("W4 CF Line".Big where(Id = const(1))); Editable = false; }
        field(20; TwoFilters; Integer) { FieldClass = FlowField; CalcFormula = sum("W4 CF Line".Qty where(Doc = field("No."), Tag = filter('<>A'), Tag = filter('<>B'))); Editable = false; }
        field(21; TwoConsts; Integer) { FieldClass = FlowField; CalcFormula = sum("W4 CF Line".Qty where(Doc = field("No."), Tag = const('A'), Tag = const('B'))); Editable = false; }
        field(22; FieldThenConst; Integer) { FieldClass = FlowField; CalcFormula = sum("W4 CF Line".Qty where(Doc = field("No."), Doc = const('D2'))); Editable = false; }
        field(23; FieldThenFilter; Integer) { FieldClass = FlowField; CalcFormula = sum("W4 CF Line".Qty where(Doc = field("No."), Doc = filter('D1|D2'))); Editable = false; }
        field(24; ConstThenField; Integer) { FieldClass = FlowField; CalcFormula = sum("W4 CF Line".Qty where(Doc = const('D2'), Doc = field("No."))); Editable = false; }
        field(25; FilterThenField; Integer) { FieldClass = FlowField; CalcFormula = sum("W4 CF Line".Qty where(Doc = filter('D1|D2'), Doc = field("No."))); Editable = false; }
        field(30; NegMin; Integer) { FieldClass = FlowField; CalcFormula = -min("W4 CF Line".Qty where(Doc = field("No."))); Editable = false; }
        field(31; NegMax; Integer) { FieldClass = FlowField; CalcFormula = -max("W4 CF Line".Qty where(Doc = field("No."))); Editable = false; }
        field(32; NegLookup; Integer) { FieldClass = FlowField; CalcFormula = -lookup("W4 CF Line".Qty where(Id = const(2))); Editable = false; }
        field(33; NegSum; Integer) { FieldClass = FlowField; CalcFormula = -sum("W4 CF Line".Qty where(Doc = field("No."))); Editable = false; }
        field(34; NegCount; Integer) { FieldClass = FlowField; CalcFormula = -count("W4 CF Line" where(Doc = field("No."))); Editable = false; }
        field(35; NegAvg; Decimal) { FieldClass = FlowField; CalcFormula = -average("W4 CF Line".Qty where(Doc = field("No."))); Editable = false; }
        field(36; PosMin; Integer) { FieldClass = FlowField; CalcFormula = min("W4 CF Line".Qty where(Doc = field("No."))); Editable = false; }
        field(37; PosMax; Integer) { FieldClass = FlowField; CalcFormula = max("W4 CF Line".Qty where(Doc = field("No."))); Editable = false; }
        field(38; PosLookup; Integer) { FieldClass = FlowField; CalcFormula = lookup("W4 CF Line".Qty where(Id = const(2))); Editable = false; }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 68042 "W4 CalcFields Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(var Head: Record "W4 CF Head")
    var
        Line: Record "W4 CF Line";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        AddLine(1, 'D1', 'A', 2, 10);
        AddLine(2, 'D1', 'B', 4, 20);
        AddLine(3, 'D1', 'C', 6, 40);
        AddLine(4, 'D2', 'A', 8, 80);
        Head."No." := 'D1';
        Head.Insert();
    end;

    local procedure AddLine(Id: Integer; Doc: Code[10]; Tag: Code[10]; Qty: Integer; Big: BigInteger)
    var
        Line: Record "W4 CF Line";
    begin
        Line.Id := Id;
        Line.Doc := Doc;
        Line.Tag := Tag;
        Line.Qty := Qty;
        Line.Big := Big;
        Line.Insert();
    end;

    // CalcFields of a FlowField by number; a read only, so a TryFunction is allowed.
    [TryFunction]
    local procedure TryCalc(var Head: Record "W4 CF Head"; FieldNo: Integer; var Result: Text)
    var
        RR: RecordRef;
        FR: FieldRef;
    begin
        RR.GetTable(Head);
        FR := RR.Field(FieldNo);
        FR.CalcField();
        Result := Format(FR.Value());
    end;

    local procedure Outcome(Ok: Boolean; Value: Text): Text
    begin
        if Ok then
            exit('ok:[' + Value + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure SystemRowVersion_MinMax()
    var
        Head: Record "W4 CF Head";
        Line1: Record "W4 CF Line";
        Line3: Record "W4 CF Line";
        MinText: Text;
        MaxText: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Head);
        Line1.Get(1);
        Line3.Get(3);
        // The value itself differs from run to run: observe that it was calculated and how it relates to the rows.
        if TryCalc(Head, 10, MinText) then begin
            Observer.Observe('min_outcome', 'ok');
            Observer.Observe('min_equals_line1_rowversion', Format(Head.SrvMin = Line1.SystemRowVersion));
        end else begin
            Observer.Observe('min_outcome', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        if TryCalc(Head, 11, MaxText) then begin
            Observer.Observe('max_outcome', 'ok');
            Observer.Observe('max_equals_line3_rowversion', Format(Head.SrvMax = Line3.SystemRowVersion));
        end else begin
            Observer.Observe('max_outcome', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Expect('min_outcome', 'error:Table content in the W4 CF Head table on SQL Server contains a value that is not compatible with the corresponding data type that is defined for the table.\r\\r\Field: SrvMin\r\Type: BigInteger\r\SQL type: timestamp\r\\r\The table design may have been changed outside Business Central.|NDBCS:IncompatibleSqlType');
        Observer.Expect('max_outcome', 'error:Table content in the W4 CF Head table on SQL Server contains a value that is not compatible with the corresponding data type that is defined for the table.\r\\r\Field: SrvMax\r\Type: BigInteger\r\SQL type: timestamp\r\\r\The table design may have been changed outside Business Central.|NDBCS:IncompatibleSqlType');
        Observer.Verify();
    end;

    [Test]
    procedure BigIntegerSource_IntoIntegerFlowField()
    var
        Head: Record "W4 CF Head";
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Head);
        Observer.Observe('sum_big_into_int', Outcome(TryCalc(Head, 12, Result), Result));
        ClearLastError();
        Observer.Observe('max_big_into_int', Outcome(TryCalc(Head, 15, Result), Result));
        ClearLastError();
        Observer.Observe('lookup_big_into_int', Outcome(TryCalc(Head, 16, Result), Result));
        ClearLastError();
        Observer.Expect('sum_big_into_int', 'ok:[70]');
        Observer.Expect('max_big_into_int', 'ok:[40]');
        Observer.Expect('lookup_big_into_int', 'ok:[10]');
        Observer.Verify();
    end;

    [Test]
    procedure IntegerSource_IntoBigIntegerFlowField()
    var
        Head: Record "W4 CF Head";
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Head);
        Observer.Observe('sum_int_into_bigint', Outcome(TryCalc(Head, 14, Result), Result));
        ClearLastError();
        Observer.Observe('average_int_into_bigint', Outcome(TryCalc(Head, 13, Result), Result));
        ClearLastError();
        Observer.Expect('sum_int_into_bigint', 'ok:[12]');
        Observer.Expect('average_int_into_bigint', 'ok:[4]');
        Observer.Verify();
    end;

    [Test]
    procedure TwoConditionsOnOneSourceField()
    var
        Head: Record "W4 CF Head";
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        // D1 lines: A=2, B=4, C=6; D2 line: A=8. Every FlowField sums Qty.
        // both conditions: 6 (C only); only the last: 8 (A and C of D1); only the first: 10 (B and C).
        Seed(Head);
        Observer.Observe('two_filters_ne_A_ne_B', Outcome(TryCalc(Head, 20, Result), Result));
        ClearLastError();
        // both: 0; only the last (B): 4; only the first (A): 2.
        Observer.Observe('two_consts_A_B', Outcome(TryCalc(Head, 21, Result), Result));
        ClearLastError();
        // both: 0; last (D2): 8; first (link, D1): 12.
        Observer.Observe('field_then_const_D2', Outcome(TryCalc(Head, 22, Result), Result));
        ClearLastError();
        // the pinned shape: the filter replaces the link, D1|D2 gives 20.
        Observer.Observe('field_then_filter', Outcome(TryCalc(Head, 23, Result), Result));
        ClearLastError();
        // the order reversed.
        Observer.Observe('const_D2_then_field', Outcome(TryCalc(Head, 24, Result), Result));
        ClearLastError();
        Observer.Observe('filter_then_field', Outcome(TryCalc(Head, 25, Result), Result));
        ClearLastError();
        Observer.Expect('two_filters_ne_A_ne_B', 'ok:[8]');
        Observer.Expect('two_consts_A_B', 'ok:[4]');
        Observer.Expect('field_then_const_D2', 'ok:[8]');
        Observer.Expect('field_then_filter', 'ok:[20]');
        Observer.Expect('const_D2_then_field', 'ok:[0]');
        Observer.Expect('filter_then_field', 'ok:[12]');
        Observer.Verify();
    end;

}
