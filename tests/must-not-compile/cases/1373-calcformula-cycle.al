// @expect AL0896 | The field 'A' cannot be defined because it has a calculation formula that leads to a cycle. The field 'A (2)' from table 'MNC BM T1373 (51373)' is involved in the cycle.
// @expect AL0896 | The field 'B' cannot be defined because it has a calculation formula that leads to a cycle. The field 'B (3)' from table 'MNC BM T1373 (51373)' is involved in the cycle.
// @expect AL0896 | The field 'C' cannot be defined because it has a calculation formula that leads to a cycle. The field 'C (4)' from table 'MNC BM T1373 (51373)' is involved in the cycle.
// @expect AL0896 | The field 'D' cannot be defined because it has a calculation formula that leads to a cycle. The field 'D (5)' from table 'MNC BM T1373 (51373)' is involved in the cycle.
// Corpus #664 item 9. A FlowField whose CalcFormula refers to itself (Sum of itself; a Count whose filter names the field itself)
// or to a second FlowField that refers back is refused with AL0896, one diagnostic per field in the cycle.
table 51373 "MNC BM T1373"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; A; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC BM T1373".A); }
        field(3; B; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC BM T1373".C); }
        field(4; C; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC BM T1373".B); }
        field(5; D; Integer) { FieldClass = FlowField; CalcFormula = count("MNC BM T1373" where(D = const(1))); }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
