// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// Namespaces with an empty prefix written as '' (with UseDefaultNamespace = true): a prefix is an identifier, so '' is a syntax error.
// The quoted identifier "" compiles; what it exports is asserted in tests/al-language/xmlport/lt-dg-xmlport-leads/DgXmlPortLeads.al (Item108_NamespaceRules).
xmlport 51856 "MNC DG Ns Empty Prefix"
{
    Format = Xml;
    Namespaces = '' = 'urn:a';
    UseDefaultNamespace = true;
    schema
    {
        textelement(Root) { }
    }
}
