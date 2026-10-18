// @expect AL0219 | Syntax error, string literal expected
// Page field CharAllowed given a number instead of text.
table 50881 "MNC AA T881"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T881"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50881 "MNC AA P881"
{
    PageType = Card;
    SourceTable = "MNC AA T881";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(T; Rec.Txt) { CharAllowed = 5; }
        }
    }
}
