// @expect AL0815 | The source of a column cannot be a flow filter.
// @expect AL0353 | A Column must have a valid data source or have the 'Method' property set to 'Count'
// A query column whose source is a FlowFilter field. microsoft/AL issue 7338 reported that this compiled and failed at run time;
// the compiler now rejects it. Corpus issue 667 item 94.
table 50166 "MNC FlowFilter Col Row"
{
    fields { field(1; Id; Integer) { } field(2; "Date Filter"; Date) { FieldClass = FlowFilter; } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 50167 "MNC FlowFilter Col"
{
    elements
    {
        dataitem(Row; "MNC FlowFilter Col Row")
        {
            column(Id; Id) { }
            column(DateFilter; "Date Filter") { }
        }
    }
}
