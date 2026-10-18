// @expect AL0543 | The manifest property 'contextSensitiveHelpUrl' must be set in order to use the property 'ContextSensitiveHelpPage'.
// @expect AL0428 | Cannot specify HelpLink and ContextSensitiveHelpPage property at the same time. Use only the ContextSensitiveHelpPage property.
// @expect AL0428 | Cannot specify HelpLink and ContextSensitiveHelpPage property at the same time. Use only the ContextSensitiveHelpPage property.
report 50813 "MNC Y RP Help Both"
{
    ProcessingOnly = true;
    requestpage
    {
        HelpLink = 'https://example.com';
        ContextSensitiveHelpPage = 'abc';
        layout { area(Content) { field(F; Fv) { ApplicationArea = All; } } }
    }
    var
        Fv: Integer;
}
