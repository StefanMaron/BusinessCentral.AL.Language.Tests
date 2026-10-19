// @expect AL0779 | It is not allowed to call `ModifyAll` on a field of FieldClass='FlowField'.
// @expect AL0779 | It is not allowed to call `ModifyAll` on a field of FieldClass='FlowField'.
// ModifyAll on a FlowField (Sum and Lookup) is refused with AL0779 (corpus #664 item 4; the tracker named AL0780).
// ModifyAll on a FlowFilter field, and a plain assignment or Validate on a FlowField or FlowFilter, compile with no diagnostic.
table 51370 "MNC BM T1370"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Amt; Decimal) { }
        field(3; SumFF; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC BM T1370".Amt); }
        field(4; FFi; Code[20]) { FieldClass = FlowFilter; }
        field(5; LookFF; Code[20]) { FieldClass = FlowField; CalcFormula = lookup("MNC BM T1370".Id); }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 51370 "MNC BM C1370"
{
    procedure P()
    var
        r: Record "MNC BM T1370";
    begin
        r.ModifyAll(SumFF, 5);
        r.ModifyAll(LookFF, '2000');
        r.ModifyAll(FFi, '2000');
        r.LookFF := '2000';
        r.SumFF := 1;
        r.FFi := 'X';
        r.Validate(LookFF, '2000');
    end;
}
