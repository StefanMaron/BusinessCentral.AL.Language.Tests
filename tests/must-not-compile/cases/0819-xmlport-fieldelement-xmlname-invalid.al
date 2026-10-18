// @expect AL0359 | The XML node name is not valid. Name cannot begin with the '1' character, hexadecimal value 0x31.
xmlport 50819 "MNC Y XP 9"
{
    Format = Xml;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; Integer)
            {
                fieldelement(N; Rw.Number) { XmlName = '1bad name'; }
            }
        }
    }
}
