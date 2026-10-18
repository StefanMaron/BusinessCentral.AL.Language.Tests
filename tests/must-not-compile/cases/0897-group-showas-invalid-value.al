// @expect AL0169 | The option value 'Menu' is not valid
// Page action group ShowAs with an unknown value.
table 50904 "MNC AA T904"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T904"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50904 "MNC AA P904"
{
    PageType = Card;
    SourceTable = "MNC AA T904";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }
    actions
    {
        area(Processing)
        {
            group(G) { ShowAs = Menu; action(A) { } }
        }
    }
}
