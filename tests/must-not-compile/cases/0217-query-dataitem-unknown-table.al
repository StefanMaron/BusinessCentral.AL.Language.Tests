// @expect AL0185 | Table 'MNC No Such Table' is missing
// @expect AL0352 | Queries must define at least one Column.
// A query dataitem names a table that does not exist.
query 50022 "MNC Q217"
{
    elements
    {
        dataitem(Item; "MNC No Such Table")
        {
        }
    }
}
