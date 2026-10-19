// @expect AL0270 | The control 'NoSuchControl' is not found in the target 'MNC Z Card 0866'
// modify() names a control that the customized page does not have.
table 59866 "MNC Z Row 0866"
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
page 52866 "MNC Z Card 0866"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0866";
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
pagecustomization "MNC Z Cust 0866" customizes "MNC Z Card 0866"
{
    layout { modify(NoSuchControl) { Editable = false; } }
}
