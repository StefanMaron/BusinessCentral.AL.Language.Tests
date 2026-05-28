// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-schema
// Scope: fixture XmlPort for nested tableelement and attribute coverage
// Fixture tables: ALT Parent (60004), ALT Child (60005)

xmlport 60024 "ALT Parent Child XmlPort"
{
    Caption = 'ALT Parent Child XmlPort';
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Parents)
        {
            tableelement(Parent; "ALT Parent")
            {
                XmlName = 'Parent';

                fieldelement(ParentEntryNo; Parent."Entry No.")
                {
                }
                fieldelement(ParentCode; Parent.Code)
                {
                }

                tableelement(Child; "ALT Child")
                {
                    LinkTable = Parent;
                    LinkFields = "Parent Entry No." = FIELD("Entry No.");
                    XmlName = 'Child';

                    fieldelement(ChildEntryNo; Child."Entry No.")
                    {
                    }
                    fieldelement(ChildCode; Child.Code)
                    {
                        fieldattribute(Amount; Child.Amount)
                        {
                        }
                    }
                }
            }
        }
    }
}
