// @expect AL0385 | IncludeCaption can be set to true only if the source of the column is a named field.
// IncludeCaption = true on a report column whose source is an expression, not a named field.
table 50000 "MNC Row"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

report 50001 "MNC Report Caption"
{
    dataset
    {
        dataitem(Row; "MNC Row")
        {
            column(IdText; Format(Id))
            {
                IncludeCaption = true;
            }
        }
    }
}
