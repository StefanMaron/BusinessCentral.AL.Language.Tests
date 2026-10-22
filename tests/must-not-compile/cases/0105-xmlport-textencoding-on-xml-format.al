// @expect AL0167 | The Property 'TextEncoding' can only be used if the property 'Format' is set with any of the values of: 'VariableText,FixedText'
// TextEncoding on an xmlport whose Format is Xml (it needs VariableText or FixedText).
xmlport 50109 "MNC XmlPort TextEncoding Xml"
{
    Format = Xml;
    TextEncoding = UTF8;
    schema
    {
        textelement(Root) { }
    }
}
