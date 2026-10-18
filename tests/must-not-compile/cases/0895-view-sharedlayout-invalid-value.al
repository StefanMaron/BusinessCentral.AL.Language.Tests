// @expect AL0220 | Syntax error, boolean literal expected
// Page view SharedLayout given text instead of a Boolean.
table 50902 "MNC AA T902"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T902"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50902 "MNC AA P902"
{
    PageType = List;
    SourceTable = "MNC AA T902";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }
    views
    {
        view(V) { SharedLayout = 'maybe'; }
    }
}
