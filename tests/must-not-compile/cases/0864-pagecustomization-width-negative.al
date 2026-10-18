// @expect AL0232 | The property value on field 'Width' must be positive or zero.
// Width must be within the allowed range (a negative value).
table 59864 "MNC Z Row 0864"
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
page 52864 "MNC Z Card 0864"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0864";
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
pagecustomization "MNC Z Cust 0864" customizes "MNC Z Card 0864"
{
    layout { modify(Name) { Width = -1; } }
}
