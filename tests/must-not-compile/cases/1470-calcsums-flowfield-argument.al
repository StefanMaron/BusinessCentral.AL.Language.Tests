// @expect AL0827 | Argument 1: The argument 1 of field class FlowField is not supported. Allowed field class types are 'Normal'.
// @expect AL0827 | Argument 2: The argument 2 of field class FlowField is not supported. Allowed field class types are 'Normal'.
// Record.CalcSums with a Sum FlowField as the only argument, and as the second argument after a normal Decimal field (corpus issue 668 item 61).
table 51470 "MNC BR T1470 Line"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Amt; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
table 51471 "MNC BR T1470 Head"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Plain; Decimal) { }
        field(3; Total; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC BR T1470 Line".Amt); }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 51470 "MNC BR C1470"
{
    procedure Sums()
    var
        Head: Record "MNC BR T1470 Head";
    begin
        Head.CalcSums(Total);
        Head.CalcSums(Plain, Total);
    end;
}
