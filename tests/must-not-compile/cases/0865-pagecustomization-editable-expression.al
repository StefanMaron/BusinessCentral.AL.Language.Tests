// @expect AL0161 | 'Flag' is inaccessible due to its protection level
// A page customization cannot name a variable of the page it customizes in an expression.
table 59865 "MNC Z Row 0865"
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
page 52865 "MNC Z Card 0865"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0865";
    layout { area(Content) { field(Name; Rec.Name) { Editable = Flag; } } }
    var Flag: Boolean;
}
pagecustomization "MNC Z Cust 0865" customizes "MNC Z Card 0865"
{
    layout { modify(Name) { Editable = Flag; } }
}
