// @expect AL0169 | The option value 'Medium' is not valid. Check the enum definition for valid values.
// Page cuegroup CuegroupLayout with the value Medium.
table 50912 "MNC AA T912"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T912"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50912 "MNC AA P912"
{
    PageType = Card;
    SourceTable = "MNC AA T912";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            cuegroup(C) { CuegroupLayout = Medium; field(Cue; Rec.Amt) { } }
        }
    }
}
