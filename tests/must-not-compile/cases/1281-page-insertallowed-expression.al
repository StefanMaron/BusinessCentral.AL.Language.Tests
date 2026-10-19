// @expect AL0220 | Syntax error, boolean literal expected. Use 'true' or 'false'.
// A page sets the page property InsertAllowed to an expression instead of a literal true or false.
table 51281 "MNC BD T1281"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51281 "MNC BD P1281"
{
    PageType = List;
    SourceTable = "MNC BD T1281";
    InsertAllowed = 1 = 1;
    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { }
            }
        }
    }
}
