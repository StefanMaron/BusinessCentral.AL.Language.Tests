// @expect AL0246 | The property 'DecimalPlaces' cannot be customized
// A page extension cannot change DecimalPlaces of a base field with modify.
table 59680 "MNC U 680"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Dec; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51680 "MNC U Part 680"
{
    PageType = ListPart;
    SourceTable = "MNC U 680";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } field(Txt; Rec.Txt) { } field(Dec; Rec.Dec) { } } } }
}
page 52680 "MNC U Card 680"
{
    PageType = Card;
    SourceTable = "MNC U 680";
    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { }
            field(Dec; Rec.Dec) { }
            part(Pt; "MNC U Part 680") {  }
            
        }
    }
}
pageextension 53680 "MNC U Ext 680" extends "MNC U Card 680"
{
    layout { modify(Dec) { DecimalPlaces = 4 : 4; } }
}
