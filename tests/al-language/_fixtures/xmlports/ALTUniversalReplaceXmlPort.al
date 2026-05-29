// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoreplace-property
// Scope: fixture XmlPort for AutoReplace semantics
// Fixture table: ALT Universal (60000)

xmlport 60027 "ALT Universal Replace XmlPort"
{
    Caption = 'ALT Universal Replace XmlPort';
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Universals)
        {
            tableelement(Universal; "ALT Universal")
            {
                AutoReplace = true;
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
