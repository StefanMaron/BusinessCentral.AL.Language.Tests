// @expect AL0591 | The property GridLayout is only supported on Grid.
// Page group GridLayout on a normal group.
table 50916 "MNC AA T916"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T916"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50916 "MNC AA P916"
{
    PageType = Card;
    SourceTable = "MNC AA T916";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            group(G) { GridLayout = Rows; field(F; Rec.Txt) { } }
        }
    }
}
