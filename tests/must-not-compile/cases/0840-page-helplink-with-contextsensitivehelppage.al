// @expect AL0543 | The manifest property 'contextSensitiveHelpUrl' must be set in order to use the property 'ContextSensitiveHelpPage'.
// @expect AL0428 | Cannot specify HelpLink and ContextSensitiveHelpPage property at the same time. Use only the ContextSensitiveHelpPage property.
// @expect AL0428 | Cannot specify HelpLink and ContextSensitiveHelpPage property at the same time. Use only the ContextSensitiveHelpPage property.
// HelpLink and ContextSensitiveHelpPage cannot both be set on a page.
table 59840 "MNC Z Row 0840"
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
page 52840 "MNC Z Card 0840"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0840";
    HelpLink = 'https://example.com/help';
    ContextSensitiveHelpPage = 'lt-z-help';
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
