// @expect AL0232 | The property value on field 'Width' must be positive or zero.
// Width must be within the allowed range (a negative value).
table 59858 "MNC Z Row 0858"
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
page 52858 "MNC Z Card 0858"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0858";
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
pageextension 54858 "MNC Z Ext 0858" extends "MNC Z Card 0858"
{
    layout { modify(Name) { Width = -1; } }
}
