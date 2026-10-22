// @expect AL0124 | The property 'OrderBy' cannot be used in this context
// OrderBy written on a query dataitem (it belongs to the query object).
table 50106 "MNC OrderBy Row"
{
    fields { field(1; Id; Integer) { } field(2; Other; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 50107 "MNC OrderBy On Dataitem"
{
    elements
    {
        dataitem(Row; "MNC OrderBy Row")
        {
            OrderBy = ascending(Other);
            column(Id; Id) { }
            column(Other; Other) { }
        }
    }
}
