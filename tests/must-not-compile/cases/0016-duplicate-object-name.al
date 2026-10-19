// @expect AL0197 | An application object of type 'Codeunit' with name 'MNC Same Name' is already declared by the extension
// @expect AL0197 | An application object of type 'Codeunit' with name 'MNC Same Name' is already declared by the extension
// Two codeunits of the same name in one app.
codeunit 50000 "MNC Same Name"
{
}

codeunit 50001 "MNC Same Name"
{
}
