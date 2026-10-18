// @expect AL0428 | Cannot specify PromotedActionCategoriesML and PromotedActionCategories property at the same time. Use only the PromotedActionCategories property.
// @expect AL0428 | Cannot specify PromotedActionCategoriesML and PromotedActionCategories property at the same time. Use only the PromotedActionCategories property.
// PromotedActionCategories and PromotedActionCategoriesML cannot both be set on a page.
table 59844 "MNC Z Row 0844"
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
page 52844 "MNC Z Card 0844"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0844";
    PromotedActionCategories = 'One,Two';
    PromotedActionCategoriesML = ENU = 'One,Two', DEU = 'Eins,Zwei';
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
