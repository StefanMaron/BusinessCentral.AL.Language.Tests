// @expect AL0666 | 'Modifying Editable from Extensions' is not available in runtime version '16.0'. The supported runtime versions are: '1.0' until, but not including '10.1'
// A page extension cannot change Editable of a base part with modify (runtime 16.0).
table 59684 "MNC U 684"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Dec; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51684 "MNC U Part 684"
{
    PageType = ListPart;
    SourceTable = "MNC U 684";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } field(Txt; Rec.Txt) { } field(Dec; Rec.Dec) { } } } }
}
page 52684 "MNC U Card 684"
{
    PageType = Card;
    SourceTable = "MNC U 684";
    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { }
            field(Dec; Rec.Dec) { }
            part(Pt; "MNC U Part 684") {  }
            
        }
    }
}
pageextension 53684 "MNC U Ext 684" extends "MNC U Card 684"
{
    layout { modify(Pt) { Editable = false; } }
}
