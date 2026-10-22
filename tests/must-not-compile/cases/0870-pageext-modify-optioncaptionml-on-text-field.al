// @expect AL0843 | The property 'OptionCaptionML' can only be used if the field's type is 'Option'.
// OptionCaptionML on a Text field.
table 59870 "MNC Z Row 0870"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 52870 "MNC Z Card 0870"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0870";
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
pageextension 54870 "MNC Z Ext 0870" extends "MNC Z Card 0870"
{
    layout { modify(Name) { OptionCaptionML = ENU = 'a,b'; } }
}
