// @expect AL0314 | The property 'IndentationControls' is only valid in controls of type 'Repeater'
// Page group IndentationControls on a normal group.
table 50921 "MNC AA T921"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T921"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50921 "MNC AA P921"
{
    PageType = Card;
    SourceTable = "MNC AA T921";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            group(G) { IndentationControls = F; field(F; Rec.Txt) { } }
        }
    }
}
