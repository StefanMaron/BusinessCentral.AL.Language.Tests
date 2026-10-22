// @expect AL0637 | The property 'NavigationPageId' must be defined on a page of pagetype 'API'
// Page field NavigationPageId on a Card page with a TableRelation field.
table 50883 "MNC AA T883"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T883"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50883 "MNC AA P883"
{
    PageType = Card;
    SourceTable = "MNC AA T883";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(T; Rec.Rel) { NavigationPageId = "MNC AA P883"; }
        }
    }
}
