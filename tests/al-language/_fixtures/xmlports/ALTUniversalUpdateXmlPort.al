// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoupdate-property
// Scope: fixture XmlPort for AutoUpdate semantics
// Fixture table: ALT Universal (60000)

xmlport 60026 "ALT Universal Update XmlPort"
{
    Caption = 'ALT Universal Update XmlPort';
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Universals)
        {
            tableelement(Universal; "ALT Universal")
            {
                AutoUpdate = true;
                XmlName = 'Universal';

                fieldelement(EntryNo; Universal."Entry No.")
                {
                }
                fieldelement(IntegerValue; Universal."Integer Field")
                {
                }
            }
        }
    }
}
