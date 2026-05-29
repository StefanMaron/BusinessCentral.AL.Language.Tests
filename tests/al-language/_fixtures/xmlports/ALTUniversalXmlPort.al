// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-data-type
// Scope: fixture XmlPort used by XmlPort coverage tests
// Fixture table: ALT Universal (60000)

xmlport 60023 "ALT Universal XmlPort"
{
    Caption = 'ALT Universal XmlPort';
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            XmlName = 'Universals';

            tableelement(Universal; "ALT Universal")
            {
                XmlName = 'Universal';

                fieldelement(EntryNo; Universal."Entry No.")
                {
                }
                fieldelement(IntegerValue; Universal."Integer Field")
                {
                }
                fieldelement(TextValue; Universal."Text Field")
                {
                }
            }
        }
    }
}
