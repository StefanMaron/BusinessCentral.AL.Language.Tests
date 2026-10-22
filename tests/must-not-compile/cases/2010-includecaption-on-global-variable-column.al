// @expect AL0385 | IncludeCaption can be set to true only if the source of the column is a named field.
// IncludeCaption = true on a report column whose source is a global Integer variable, not a field (writer QS; 0015 is an expression).
// A field written with its data item name, also one of a child, a parent or an earlier sibling data item, compiles
// (errors/lt-ms-refusals-138/P138ColCaptionQualified.al, tests QS_*).
table 50000 "MNC Cap Row"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

report 50001 "MNC Cap Variable"
{
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "MNC Cap Row")
        {
            column(Counter; GCounter)
            {
                IncludeCaption = true;
            }
        }
    }

    var
        GCounter: Integer;
}
