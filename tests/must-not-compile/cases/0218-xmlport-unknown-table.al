// @expect AL0185 | Table 'MNC No Such Table' is missing
// An xmlport tableelement names a table that does not exist.
xmlport 50023 "MNC X218"
{
    schema
    {
        textelement(Root)
        {
            tableelement(Item; "MNC No Such Table")
            {
            }
        }
    }
}
