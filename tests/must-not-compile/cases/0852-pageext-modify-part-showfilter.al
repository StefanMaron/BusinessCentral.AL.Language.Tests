// @expect AL0246 | The property 'ShowFilter' cannot be customized.
// A page extension cannot change ShowFilter of a part with modify.
table 59852 "MNC Z Row 0852"
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
page 51852 "MNC Z Part 0852"
{
    PageType = ListPart;
    SourceTable = "MNC Z Row 0852";
    layout { area(Content) { repeater(R) { field(Name; Rec.Name) { } } } }
}
page 52852 "MNC Z Card 0852"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0852";
    layout { area(Content) { field(Name; Rec.Name) { } part(Pt; "MNC Z Part 0852") { } } }
}
pageextension 54852 "MNC Z Ext 0852" extends "MNC Z Card 0852"
{
    layout { modify(Pt) { ShowFilter = false; } }
}
