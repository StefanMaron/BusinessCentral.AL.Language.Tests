// @expect AL0345 | The source of a Column or Filter must be a field defined on the table referenced by its parent DataItem
// @expect AL0353 | A Column must have a valid data source or have the 'Method' property set to 'Count'
// A query column over a field the table lacks.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } field(2; Name; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 50001 "MNC Query"
{
    elements
    {
        dataitem(Row; "MNC Table")
        {
            column(X; NoSuchField) { }
        }
    }
}
