// @expect AL0808 | You cannot set the 'Editable' property to 'true' for Control 'Name' in the page customization 'MNC Z Cust 0860'. Reason: 'The source table field has AllowInCustomizations set to 'ToBeClassified'.'.
// A page customization cannot set Editable = true on a control whose source field has AllowInCustomizations ToBeClassified.
table 59860 "MNC Z Row 0860"
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
page 52860 "MNC Z Card 0860"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0860";
    layout { area(Content) { field(Name; Rec.Name) { Editable = false; } } }
}
pagecustomization "MNC Z Cust 0860" customizes "MNC Z Card 0860"
{
    layout { modify(Name) { Editable = true; } }
}
