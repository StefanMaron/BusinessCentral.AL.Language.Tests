// @expect AL0220 | Syntax error, boolean literal expected. Use 'true' or 'false'.
// A page extension sets the page property InsertAllowed to a variable instead of a literal true or false.
table 51280 "MNC BD T1280"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51280 "MNC BD P1280"
{
    PageType = List;
    SourceTable = "MNC BD T1280";
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
pageextension 51281 "MNC BD X1280" extends "MNC BD P1280"
{
    InsertAllowed = Allowed;

    var
        Allowed: Boolean;
}
