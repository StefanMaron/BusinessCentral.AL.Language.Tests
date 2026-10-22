// @expect AL0169 | The option value 'MSDOS' is not valid
// Encoding = MSDOS on an xmlport (Encoding takes UTF8 or UTF16).
xmlport 50110 "MNC XmlPort Encoding Msdos"
{
    Format = Xml;
    Encoding = MSDOS;
    schema
    {
        textelement(Root) { }
    }
}
