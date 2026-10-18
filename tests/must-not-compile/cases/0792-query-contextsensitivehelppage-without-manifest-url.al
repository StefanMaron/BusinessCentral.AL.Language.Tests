// @expect AL0543 | The manifest property 'contextSensitiveHelpUrl' must be set in order to use the property 'ContextSensitiveHelpPage'.
// ContextSensitiveHelpPage needs contextSensitiveHelpUrl in app.json.
query 59990 "MNC X Q" { ContextSensitiveHelpPage = 'abc'; elements { dataitem(C; Customer) { column(No; "No.") { } } } }
