// @expect AL0843 | The property 'OptionCaptionML' can only be used if the field's type is 'Option'.
// Page field OptionCaptionML on a Text field.
table 50887 "MNC AA T887"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T887"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50887 "MNC AA P887"
{
    PageType = Card;
    SourceTable = "MNC AA T887";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(T; Rec.Txt) { OptionCaptionML = ENU = 'A,B'; }
        }
    }
}
