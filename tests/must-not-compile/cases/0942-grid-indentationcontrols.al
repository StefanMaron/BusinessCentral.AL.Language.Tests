// @expect AL0314 | The property 'IndentationControls' is only valid in controls of type 'Repeater'
// IndentationControls is a repeater property: a grid refuses it.
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
                IndentationControls = Fld;
                field(Fld; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}
