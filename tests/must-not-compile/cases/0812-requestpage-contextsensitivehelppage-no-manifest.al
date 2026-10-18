// @expect AL0543 | The manifest property 'contextSensitiveHelpUrl' must be set in order to use the property 'ContextSensitiveHelpPage'.
// ContextSensitiveHelpPage needs the manifest property contextSensitiveHelpUrl, which the corpus apps do not set.
report 50812 "MNC Y RP Help"
{
    ProcessingOnly = true;
    requestpage
    {
        ContextSensitiveHelpPage = 'abc';
        layout { area(Content) { field(F; Fv) { ApplicationArea = All; } } }
    }
    var
        Fv: Integer;
}
