// @expect AL0169 | The option value 'UpSwipe' is not valid. Check the enum definition for valid values.
// Page action Gesture with a value that is not None, LeftSwipe, RightSwipe or ContextMenu.
table 50903 "MNC AA T903"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T903"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50903 "MNC AA P903"
{
    PageType = Card;
    SourceTable = "MNC AA T903";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }
    actions
    {
        area(Processing)
        {
            action(A) { Gesture = UpSwipe; }
        }
    }
}
