// @expect AL0124 | The property 'AutoCalcField' cannot be used in this context
xmlport 50817 "MNC Y XP 7"
{
    Format = Xml;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; Integer)
            {
                AutoCalcField = N;
                fieldelement(N; Rw.Number) { }
            }
        }
    }
}
