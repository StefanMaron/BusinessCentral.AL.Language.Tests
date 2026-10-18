// @expect AL0223 | The Property 'ClearViews' can only be used if the property 'PageType' is set to 'List'
// ClearViews is for list pages only.
table 59861 "MNC Z Row 0861"
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
page 52861 "MNC Z Card 0861"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0861";
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
pagecustomization "MNC Z Cust 0861" customizes "MNC Z Card 0861"
{
    ClearViews = true;
}
