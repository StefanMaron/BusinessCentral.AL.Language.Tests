// @expect AL0167 | The Property 'IsPreview' can only be used if the property 'PageType' is set with any of the values of: 'PromptDialog,ConfigurationDialog'
// IsPreview is allowed on PromptDialog and ConfigurationDialog pages only.
table 59688 "MNC U 688"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Dec; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 59688 "MNC U Preview 688"
{
    PageType = Card;
    SourceTable = "MNC U 688";
    IsPreview = true;
    layout { area(Content) { field(Txt; Rec.Txt) { } } }
}
