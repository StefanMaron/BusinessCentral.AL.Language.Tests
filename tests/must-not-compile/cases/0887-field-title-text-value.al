// @expect AL0220 | Syntax error, boolean literal expected. Use 'true' or 'false'.
// Page field Title given text instead of a Boolean.
table 50890 "MNC AA T890"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T890"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50890 "MNC AA P890"
{
    PageType = Card;
    SourceTable = "MNC AA T890";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(T; Rec.Txt) { Title = 'abc'; }
        }
    }
}
