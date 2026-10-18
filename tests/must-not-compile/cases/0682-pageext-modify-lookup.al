// @expect AL0246 | The property 'Lookup' cannot be customized
// A page extension cannot change Lookup of a base field with modify.
table 59682 "MNC U 682"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Dec; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51682 "MNC U Part 682"
{
    PageType = ListPart;
    SourceTable = "MNC U 682";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } field(Txt; Rec.Txt) { } field(Dec; Rec.Dec) { } } } }
}
page 52682 "MNC U Card 682"
{
    PageType = Card;
    SourceTable = "MNC U 682";
    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { }
            field(Dec; Rec.Dec) { }
            part(Pt; "MNC U Part 682") {  }
            
        }
    }
}
pageextension 53682 "MNC U Ext 682" extends "MNC U Card 682"
{
    layout { modify(Txt) { Lookup = false; } }
}
