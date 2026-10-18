// @expect AL0246 | The property 'DrillDown' cannot be customized
// A page extension cannot change DrillDown of a base field with modify.
table 59681 "MNC U 681"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Dec; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51681 "MNC U Part 681"
{
    PageType = ListPart;
    SourceTable = "MNC U 681";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } field(Txt; Rec.Txt) { } field(Dec; Rec.Dec) { } } } }
}
page 52681 "MNC U Card 681"
{
    PageType = Card;
    SourceTable = "MNC U 681";
    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { }
            field(Dec; Rec.Dec) { }
            part(Pt; "MNC U Part 681") {  }
            
        }
    }
}
pageextension 53681 "MNC U Ext 681" extends "MNC U Card 681"
{
    layout { modify(Txt) { DrillDown = false; } }
}
