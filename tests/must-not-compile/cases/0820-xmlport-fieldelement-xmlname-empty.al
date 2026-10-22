// @expect AL0373 | The XML name cannot be empty.
xmlport 50810 "MNC Y XP 0"
{
    Format = Xml;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; Integer)
            {
                fieldelement(N; Rw.Number) { XmlName = ''; }
            }
        }
    }
}
