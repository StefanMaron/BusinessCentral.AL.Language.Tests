// @expect AL0133 | Argument 1: cannot convert from 'Record "MNC T1784"' to 'var Variant'
// Corpus issue 670 item 79 (microsoft/AL#5030): a Record cannot be passed to a var Variant parameter. Assign it to a Variant variable first
// (tests/al-language/misc/lt-cx-odd-leads/CxVariants.al, VariantVarParameter_HoldingRecord).
table 50784 "MNC T1784"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

codeunit 50784 "MNC C1784"
{
    procedure Probe()
    var
        Row: Record "MNC T1784";
    begin
        Take(Row);
    end;

    procedure Take(var V: Variant)
    begin
    end;
}
