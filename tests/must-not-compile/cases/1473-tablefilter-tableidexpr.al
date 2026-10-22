// @expect AL0124 | The property 'TableIDExpr' cannot be used in this context.
// TableIDExpr on a TableFilter field of a table (corpus issue 668 item 66). A TableFilter field without the property compiles
// (tests/al-language/records/W4PlatformAndMeta.al, tests/al-language/types/ProbeTypeFormsAndFilters.al).
table 51475 "MNC BR T1473"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; "Table No."; Integer) { }
        field(3; Flt; TableFilter) { TableIDExpr = "Table No."; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
