// @expect AL0591 | The property TreeInitialState is only supported on Repeater.
// Page group TreeInitialState on a normal group.
table 50923 "MNC AA T923"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T923"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50923 "MNC AA P923"
{
    PageType = Card;
    SourceTable = "MNC AA T923";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            group(G) { TreeInitialState = ExpandAll; field(F; Rec.Txt) { } }
        }
    }
}
