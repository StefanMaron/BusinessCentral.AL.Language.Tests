// @expect AL0185 | Page 'MNC Z No Such Page' is missing
// CardPageId must name an existing page.
table 59854 "MNC Z Row 0854"
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
page 53854 "MNC Z List 0854"
{
    PageType = List;
    SourceTable = "MNC Z Row 0854";
    layout { area(Content) { repeater(R) { field(Name; Rec.Name) { } } } }
}
pageextension 54854 "MNC Z Ext 0854" extends "MNC Z List 0854"
{
    CardPageId = "MNC Z No Such Page";
}
