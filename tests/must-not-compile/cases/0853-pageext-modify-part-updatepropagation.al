// @expect AL0246 | The property 'UpdatePropagation' cannot be customized.
// A page extension cannot change UpdatePropagation of a part with modify.
table 59853 "MNC Z Row 0853"
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
page 51853 "MNC Z Part 0853"
{
    PageType = ListPart;
    SourceTable = "MNC Z Row 0853";
    layout { area(Content) { repeater(R) { field(Name; Rec.Name) { } } } }
}
page 52853 "MNC Z Card 0853"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0853";
    layout { area(Content) { field(Name; Rec.Name) { } part(Pt; "MNC Z Part 0853") { } } }
}
pageextension 54853 "MNC Z Ext 0853" extends "MNC Z Card 0853"
{
    layout { modify(Pt) { UpdatePropagation = Both; } }
}
