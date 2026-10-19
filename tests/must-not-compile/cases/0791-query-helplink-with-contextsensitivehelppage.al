// @expect AL0543 | The manifest property 'contextSensitiveHelpUrl' must be set in order to use the property 'ContextSensitiveHelpPage'.
// @expect AL0428 | Cannot specify HelpLink and ContextSensitiveHelpPage property at the same time. Use only the ContextSensitiveHelpPage property.
// @expect AL0428 | Cannot specify HelpLink and ContextSensitiveHelpPage property at the same time. Use only the ContextSensitiveHelpPage property.
// HelpLink and ContextSensitiveHelpPage together.
query 59990 "MNC X Q" { HelpLink = 'https://example.com'; ContextSensitiveHelpPage = 'abc'; elements { dataitem(C; Customer) { column(No; "No.") { } } } }
