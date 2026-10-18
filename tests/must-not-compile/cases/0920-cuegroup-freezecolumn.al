// @expect AL0314 | The property 'FreezeColumn' is only valid in controls of type 'Repeater'
// FreezeColumn is a repeater property: a cue group refuses it (an unknown field name does not matter, the container is refused first).
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
                FreezeColumn = NoSuchField;
                field(Fld; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}
