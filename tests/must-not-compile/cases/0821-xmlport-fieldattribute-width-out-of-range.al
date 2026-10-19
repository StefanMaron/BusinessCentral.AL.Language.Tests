// @expect AL0103 | Constant value '2147483648' is outside the range for an Integer
xmlport 50811 "MNC Y XP 1"
{
    Format = Xml;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; Integer)
            {
                fieldattribute(N; Rw.Number) { Width = 2147483648; }
            }
        }
    }
}
