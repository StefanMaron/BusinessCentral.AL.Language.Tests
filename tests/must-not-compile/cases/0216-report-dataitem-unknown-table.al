// @expect AL0185 | Table 'MNC No Such Table' is missing
// A report dataitem names a table that does not exist.
report 50021 "MNC R216"
{
    dataset
    {
        dataitem(Item; "MNC No Such Table")
        {
        }
    }
}
