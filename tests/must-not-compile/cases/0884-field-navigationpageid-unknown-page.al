// @expect AL0185 | Page 'MNC AA Missing' is missing
// Page field NavigationPageId names a page that does not exist.
table 50884 "MNC AA T884"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T884"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50884 "MNC AA P884"
{
    PageType = API;
    SourceTable = "MNC AA T884";
    APIPublisher = 'aa';
    APIGroup = 'aa';
    APIVersion = 'v1.0';
    EntityName = 'aa';
    EntitySetName = 'aas';
    DelayedInsert = true;
    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(rel; Rec.Rel) { NavigationPageId = "MNC AA Missing"; }
            }
        }
    }
}
