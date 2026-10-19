// @expect AL0185 | Table 'MNC No Such Table' is missing
// A TableRelation names a table that does not exist.
table 50025 "MNC T220"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Ref; Integer) { TableRelation = "MNC No Such Table"; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
