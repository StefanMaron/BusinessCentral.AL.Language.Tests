// @expect AL0220 | Syntax error, boolean literal expected. Use 'true' or 'false'.
// Page action separator IsHeader given text instead of a Boolean.
table 50905 "MNC AA T905"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T905"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50905 "MNC AA P905"
{
    PageType = Card;
    SourceTable = "MNC AA T905";
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
            group(G) { separator(S) { IsHeader = 'yes'; } }
        }
    }
}
