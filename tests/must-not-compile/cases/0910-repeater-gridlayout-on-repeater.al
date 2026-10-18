// @expect AL0591 | The property GridLayout is only supported on Grid.
// Page repeater GridLayout.
table 50917 "MNC AA T917"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T917"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50917 "MNC AA P917"
{
    PageType = List;
    SourceTable = "MNC AA T917";
    layout
    {
        area(Content)
        {
            repeater(R) { GridLayout = Rows; field(Id2; Rec.Id) { } }
        }
    }
}
