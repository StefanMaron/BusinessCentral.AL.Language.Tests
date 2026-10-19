// @expect AL0103 | Constant value '2147483648' is outside the range for an Integer
xmlport 50813 "MNC Y XP 3"
{
    Format = Xml;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; Integer)
            {
                textattribute(Tx) { Width = 2147483648; }
            }
        }
    }
}
