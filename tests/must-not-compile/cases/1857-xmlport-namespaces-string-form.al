// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// Namespaces written as one string 'prefix=uri' (the form of microsoft/AL issue 246): the property takes prefix = 'uri' pairs, so a string is a syntax error.
xmlport 51857 "MNC DG Ns String Form"
{
    Format = Xml;
    Namespaces = 'soap=http://schemas.xmlsoap.org/soap/envelope/';
    schema
    {
        textelement(Root) { }
    }
}
