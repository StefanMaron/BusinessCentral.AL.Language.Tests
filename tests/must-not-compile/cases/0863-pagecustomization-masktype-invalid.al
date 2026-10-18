// @expect AL0169 | The option value 'Hidden' is not valid. Check the enum definition for valid values.
// MaskType knows None and Concealed only.
table 59863 "MNC Z Row 0863"
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
page 52863 "MNC Z Card 0863"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0863";
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
pagecustomization "MNC Z Cust 0863" customizes "MNC Z Card 0863"
{
    layout { modify(Name) { MaskType = Hidden; } }
}
