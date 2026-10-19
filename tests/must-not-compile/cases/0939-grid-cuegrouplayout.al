// @expect AL0591 | The property CuegroupLayout is only supported on CueGroup.
// CuegroupLayout is a cue group property: a grid refuses it.
table 50900 "MNC AB Table"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50901 "MNC AB Page"
{
    PageType = Card;
    SourceTable = "MNC AB Table";
    layout
    {
        area(Content)
        {
            grid(Ct)
            {
                CuegroupLayout = Wide;
                field(Fld; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}
