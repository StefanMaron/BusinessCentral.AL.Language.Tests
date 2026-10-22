// @expect AL0185 | Page 'MNC Z No Such Page' is missing
// LookupPageId must name an existing page.
table 59855 "MNC Z Row 0855"
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
page 52855 "MNC Z Card 0855"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0855";
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
pageextension 54855 "MNC Z Ext 0855" extends "MNC Z Card 0855"
{
    layout { modify(Name) { LookupPageId = "MNC Z No Such Page"; } }
}
