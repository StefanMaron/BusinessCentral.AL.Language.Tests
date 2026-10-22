// @expect AL0591 | The property TreeInitialState is only supported on Repeater.
// TreeInitialState is a repeater property: a cue group refuses it.
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
            cuegroup(Ct)
            {
                TreeInitialState = CollapseAll;
                field(Fld; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}
