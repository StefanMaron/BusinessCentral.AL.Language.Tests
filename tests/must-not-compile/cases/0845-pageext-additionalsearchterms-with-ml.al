// @expect AL0428 | Cannot specify AdditionalSearchTermsML and AdditionalSearchTerms property at the same time. Use only the AdditionalSearchTerms property.
// @expect AL0428 | Cannot specify AdditionalSearchTermsML and AdditionalSearchTerms property at the same time. Use only the AdditionalSearchTerms property.
// AdditionalSearchTerms and AdditionalSearchTermsML cannot both be set in a page extension.
table 59845 "MNC Z Row 0845"
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
page 53845 "MNC Z List 0845"
{
    PageType = List;
    SourceTable = "MNC Z Row 0845";
    layout { area(Content) { repeater(R) { field(Name; Rec.Name) { } } } }
}
pageextension 54845 "MNC Z Ext 0845" extends "MNC Z List 0845"
{
    AdditionalSearchTerms = 'zeta';
    AdditionalSearchTermsML = ENU = 'zeta', DEU = 'eta';
}
