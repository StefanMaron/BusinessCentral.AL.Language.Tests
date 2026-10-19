// @expect AL0124 | The property 'SourceTable' cannot be used in this context. Verify the property is available for the current object type.
// SourceTable on a codeunit.
table 50120 "MNC T305"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; D; Date) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 50121 "MNC C305"
{
    SourceTable = "MNC T305";
}
