// @expect AL0591 | The property CuegroupLayout is only supported on CueGroup.
// Page repeater CuegroupLayout.
table 50914 "MNC AA T914"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T914"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50914 "MNC AA P914"
{
    PageType = List;
    SourceTable = "MNC AA T914";
    layout
    {
        area(Content)
        {
            repeater(R) { CuegroupLayout = Wide; field(Id2; Rec.Id) { } }
        }
    }
}
