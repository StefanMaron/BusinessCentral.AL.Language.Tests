// @expect AL0591 | The property CuegroupLayout is only supported on CueGroup.
// Page group CuegroupLayout on a normal group.
table 50913 "MNC AA T913"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T913"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50913 "MNC AA P913"
{
    PageType = Card;
    SourceTable = "MNC AA T913";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            group(G) { CuegroupLayout = Wide; field(Cue; Rec.Amt) { } }
        }
    }
}
