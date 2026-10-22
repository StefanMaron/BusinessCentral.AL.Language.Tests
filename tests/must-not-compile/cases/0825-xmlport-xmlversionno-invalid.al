// @expect AL0169 | The option value 'V20' is not valid
xmlport 50825 "MNC Y XP Version"
{
    Format = Xml;
    UseRequestPage = false;
    XmlVersionNo = V20;
    schema { textelement(Root) { } }
}
