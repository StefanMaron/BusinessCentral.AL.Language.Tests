// @expect AL0246 | The property 'UpdatePropagation' cannot be customized
// A page extension cannot change UpdatePropagation of a base part with modify.
table 59686 "MNC U 686"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Dec; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51686 "MNC U Part 686"
{
    PageType = ListPart;
    SourceTable = "MNC U 686";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } field(Txt; Rec.Txt) { } field(Dec; Rec.Dec) { } } } }
}
page 52686 "MNC U Card 686"
{
    PageType = Card;
    SourceTable = "MNC U 686";
    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { }
            field(Dec; Rec.Dec) { }
            part(Pt; "MNC U Part 686") { UpdatePropagation = Both; }
            
        }
    }
}
pageextension 53686 "MNC U Ext 686" extends "MNC U Card 686"
{
    layout { modify(Pt) { UpdatePropagation = SubPart; } }
}
