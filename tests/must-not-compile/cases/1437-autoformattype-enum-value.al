// @expect AL0114 | Syntax error, integer literal expected.
// AutoFormatType set to a value of the enum "Auto Format" (microsoft/AL issue 5321): a syntax error, the property takes an integer
// literal only. The full text goes on with "Provide a numeric value (e.g., 0, 1, 42).".
enumextension 51437 "MNC BP EE1437" extends "Auto Format"
{
    value(51437; BpCustom) { }
}
table 51437 "MNC BP T1437"
{
    fields
    {
        field(1; Id; Integer) { }
        field(50000; X; Decimal) { AutoFormatType = "Auto Format"::BpCustom; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
