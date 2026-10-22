// @expect AL0155 | A member of type ReportColumn with name 'A' is already defined in Report 'MNC Report' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// @expect AL0155 | A member of type ReportColumn with name 'A' is already defined in Report 'MNC Report' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// Two report columns of one name.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } field(2; Name; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

report 50001 "MNC Report"
{
    dataset
    {
        dataitem(Row; "MNC Table")
        {
            column(A; Id) { }
            column(A; Name) { }
        }
    }
}
