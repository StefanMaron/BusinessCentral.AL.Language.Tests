// @expect AL0169 | The option value 'Hidden' is not valid
// MaskType knows None and Concealed only.
table 59856 "MNC Z Row 0856"
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
page 52856 "MNC Z Card 0856"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0856";
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
pageextension 54856 "MNC Z Ext 0856" extends "MNC Z Card 0856"
{
    layout { modify(Name) { MaskType = Hidden; } }
}
