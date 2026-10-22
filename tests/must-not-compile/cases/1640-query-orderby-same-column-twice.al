// @expect AL0350 | The column 'Department' cannot be used multiple times when defining the order of the resulting dataset
// A query OrderBy names the same column twice (once ascending, once descending). Corpus issue 667 item 96.
table 50164 "MNC OrderBy Twice Row"
{
    fields { field(1; Id; Integer) { } field(2; Department; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 50165 "MNC OrderBy Twice"
{
    OrderBy = ascending(Department), descending(Department);
    elements
    {
        dataitem(Row; "MNC OrderBy Twice Row")
        {
            column(Department; Department) { }
        }
    }
}
