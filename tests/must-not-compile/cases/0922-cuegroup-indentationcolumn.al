// @expect AL0314 | The property 'IndentationColumn' is only valid in controls of type 'Repeater'
// IndentationColumn is a repeater property: a cue group refuses it.
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
                IndentationColumn = Rec.Id;
                field(Fld; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}
