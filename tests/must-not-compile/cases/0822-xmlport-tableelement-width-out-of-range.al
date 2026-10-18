// @expect AL0103 | Constant value '2147483648' is outside the range for an Integer
xmlport 50812 "MNC Y XP 2"
{
    Format = Xml;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; Integer)
            {
                Width = 2147483648;
                fieldelement(N; Rw.Number) { }
            }
        }
    }
}
