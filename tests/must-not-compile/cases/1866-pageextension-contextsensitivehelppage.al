// @expect AL0543 | The manifest property 'contextSensitiveHelpUrl' must be set in order to use the property 'ContextSensitiveHelpPage'.
// Corpus issue 663 item 14: ContextSensitiveHelpPage on a page extension needs the manifest property contextSensitiveHelpUrl, which the corpus
// apps do not set (the request page case is 0812).
pageextension 51870 "MNC DH PE 1866" extends "Customer Card" { ContextSensitiveHelpPage = 'dh-help'; }
