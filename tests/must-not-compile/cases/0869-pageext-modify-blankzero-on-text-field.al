// @expect AL0844 | The property 'BlankZero' can only be used if the field's type is one of these values: 'BigInteger,Boolean,Integer,Decimal,Duration,Enum,Option'.
// BlankZero on a Text field of a page extension (a number property).
table 59869 "MNC Z Row 0869"
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
page 52869 "MNC Z Card 0869"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0869";
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
pageextension 54869 "MNC Z Ext 0869" extends "MNC Z Card 0869"
{
    layout { modify(Name) { BlankZero = true; } }
}
