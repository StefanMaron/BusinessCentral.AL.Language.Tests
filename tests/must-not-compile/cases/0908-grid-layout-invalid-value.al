// @expect AL0169 | The option value 'Cells' is not valid
// Page grid GridLayout with an unknown value.
table 50915 "MNC AA T915"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T915"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50915 "MNC AA P915"
{
    PageType = Card;
    SourceTable = "MNC AA T915";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            grid(G) { GridLayout = Cells; group(R) { field(F; Rec.Txt) { } } }
        }
    }
}
