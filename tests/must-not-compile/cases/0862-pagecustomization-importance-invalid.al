// @expect AL0169 | The option value 'Low' is not valid. Check the enum definition for valid values.
// Importance knows Standard, Promoted and Additional only.
table 59862 "MNC Z Row 0862"
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
page 52862 "MNC Z Card 0862"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0862";
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
pagecustomization "MNC Z Cust 0862" customizes "MNC Z Card 0862"
{
    layout { modify(Name) { Importance = Low; } }
}
