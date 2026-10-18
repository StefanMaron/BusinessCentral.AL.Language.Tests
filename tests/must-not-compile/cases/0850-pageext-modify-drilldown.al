// @expect AL0246 | The property 'DrillDown' cannot be customized.
// A page extension cannot change DrillDown with modify.
table 59850 "MNC Z Row 0850"
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
page 52850 "MNC Z Card 0850"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0850";
    layout { area(Content) { field(Name; Rec.Name) { } field(Amount; Rec.Amount) { } } }
}
pageextension 54850 "MNC Z Ext 0850" extends "MNC Z Card 0850"
{
    layout { modify(Amount) { DrillDown = false; } }
}
