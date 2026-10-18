// @expect AL0543 | The manifest property 'contextSensitiveHelpUrl' must be set in order to use the property 'ContextSensitiveHelpPage'.
// ContextSensitiveHelpPage needs the manifest property contextSensitiveHelpUrl (app.json has none).
table 59841 "MNC Z Row 0841"
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
page 52841 "MNC Z Card 0841"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0841";
    ContextSensitiveHelpPage = 'lt-z-help';
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
