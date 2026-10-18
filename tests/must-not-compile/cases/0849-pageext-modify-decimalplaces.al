// @expect AL0246 | The property 'DecimalPlaces' cannot be customized. This property is read-only in the current context.
// A page extension cannot change DecimalPlaces with modify.
table 59849 "MNC Z Row 0849"
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
page 52849 "MNC Z Card 0849"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0849";
    layout { area(Content) { field(Name; Rec.Name) { } field(Amount; Rec.Amount) { } } }
}
pageextension 54849 "MNC Z Ext 0849" extends "MNC Z Card 0849"
{
    layout { modify(Amount) { DecimalPlaces = 4 : 4; } }
}
