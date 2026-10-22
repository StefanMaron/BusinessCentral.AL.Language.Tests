// @expect AL0428 | Cannot specify RequestFilterHeadingML and RequestFilterHeading property at the same time. Use only the RequestFilterHeading property.
// @expect AL0428 | Cannot specify RequestFilterHeadingML and RequestFilterHeading property at the same time. Use only the RequestFilterHeading property.
xmlport 50826 "MNC Y XP 6"
{
    Format = Xml;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; Integer)
            {
                RequestFilterHeading = 'a';
                RequestFilterHeadingML = ENU = 'a';
                fieldelement(N; Rw.Number) { }
            }
        }
    }
}
