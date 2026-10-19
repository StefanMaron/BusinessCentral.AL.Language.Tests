// @expect AL0246 | The property 'ShowFilter' cannot be customized
// A page extension cannot change ShowFilter of a base part with modify.
table 59683 "MNC U 683"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Dec; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51683 "MNC U Part 683"
{
    PageType = ListPart;
    SourceTable = "MNC U 683";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } field(Txt; Rec.Txt) { } field(Dec; Rec.Dec) { } } } }
}
page 52683 "MNC U Card 683"
{
    PageType = Card;
    SourceTable = "MNC U 683";
    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { }
            field(Dec; Rec.Dec) { }
            part(Pt; "MNC U Part 683") {  }
            
        }
    }
}
pageextension 53683 "MNC U Ext 683" extends "MNC U Card 683"
{
    layout { modify(Pt) { ShowFilter = false; } }
}
