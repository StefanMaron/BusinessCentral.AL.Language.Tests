// @expect AL0171 | The property value 'count("MNC BS Calc")' on property 'CalcFormula' is not valid.
// @expect AL0171 | The property value 'sum("MNC BS Calc".B)' on property 'CalcFormula' is not valid.
// Corpus issue #668 item 90: modify() of a base table field in a table extension cannot set CalcFormula, on a FlowField (Fl) or on a normal
// field (A).
table 51499 "MNC BS Calc"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Integer) { }
        field(3; B; Decimal) { }
        field(4; Fl; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC BS Calc".B); }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

tableextension 51499 "MNC BS Calc Ext" extends "MNC BS Calc"
{
    fields
    {
        modify(Fl) { CalcFormula = count("MNC BS Calc"); }
        modify(A) { CalcFormula = sum("MNC BS Calc".B); }
    }
}
