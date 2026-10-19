// @expect AL0169 | The option value 'None' is not valid
// UpdatePropagation knows Both and SubPart only.
table 59685 "MNC U 685"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Dec; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51685 "MNC U Part 685"
{
    PageType = ListPart;
    SourceTable = "MNC U 685";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } field(Txt; Rec.Txt) { } field(Dec; Rec.Dec) { } } } }
}
page 52685 "MNC U Card 685"
{
    PageType = Card;
    SourceTable = "MNC U 685";
    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { }
            field(Dec; Rec.Dec) { }
            part(Pt; "MNC U Part 685") { UpdatePropagation = None; }
            
        }
    }
}
