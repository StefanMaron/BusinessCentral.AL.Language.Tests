// @expect AL0353 | A Column must have a valid data source or have the 'Method' property set to 'Count'
// A query column with Method = Count that names a source field.
table 50104 "MNC Count Row"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 50105 "MNC Count With Source"
{
    elements
    {
        dataitem(Row; "MNC Count Row")
        {
            column(Cnt; Id) { Method = Count; }
        }
    }
}
