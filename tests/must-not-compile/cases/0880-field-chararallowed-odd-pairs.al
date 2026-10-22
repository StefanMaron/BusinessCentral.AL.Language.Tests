// @expect AL0131 | The property CharAllowed must be specified in pairs of characters. The first character in the pair must be equal to or less than the second.
// Page field CharAllowed: a range with one character (odd count).
table 50880 "MNC AA T880"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T880"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50880 "MNC AA P880"
{
    PageType = Card;
    SourceTable = "MNC AA T880";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(T; Rec.Txt) { CharAllowed = 'a'; }
        }
    }
}
