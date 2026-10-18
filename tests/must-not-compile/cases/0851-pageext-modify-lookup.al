// @expect AL0246 | The property 'Lookup' cannot be customized.
// A page extension cannot change Lookup with modify.
table 59851 "MNC Z Row 0851"
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
page 52851 "MNC Z Card 0851"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0851";
    layout { area(Content) { field(Name; Rec.Name) { } field(Amount; Rec.Amount) { } } }
}
pageextension 54851 "MNC Z Ext 0851" extends "MNC Z Card 0851"
{
    layout { modify(Name) { Lookup = true; } }
}
