// @expect AL0314 | The property 'FreezeColumn' is only valid in controls of type 'Repeater'
// Page group FreezeColumn on a normal group.
table 50919 "MNC AA T919"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T919"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50919 "MNC AA P919"
{
    PageType = Card;
    SourceTable = "MNC AA T919";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            group(G) { FreezeColumn = F; field(F; Rec.Txt) { } }
        }
    }
}
