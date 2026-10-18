// @expect AL0103 | Constant value '2147483648' is outside the range for an Integer
xmlport 50814 "MNC Y XP 4"
{
    Format = Xml;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            textelement(Tx) { Width = 2147483648; }
        }
    }
}
