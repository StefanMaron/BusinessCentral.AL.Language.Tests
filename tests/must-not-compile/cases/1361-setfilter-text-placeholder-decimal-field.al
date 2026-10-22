// @expect AL0193 | Argument 3: cannot convert from 'Text' to the type of Argument 1 'Decimal'
// SetFilter on a Decimal field with a %1 placeholder whose value is a Text constant.
table 51361 "MNC BL T1361"
{
    fields
    {
        field(1; "No."; Integer) { }
        field(2; Amount; Decimal) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}
codeunit 51361 "MNC BL C1361"
{
    procedure Probe()
    var
        Row: Record "MNC BL T1361" temporary;
    begin
        Row.SetFilter(Amount, '%1', 'NOT-A-NUMBER');
    end;
}
