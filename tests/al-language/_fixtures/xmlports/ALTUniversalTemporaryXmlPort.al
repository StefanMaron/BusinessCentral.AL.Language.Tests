// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-usetemporary-xmlport-property
// Scope: fixture XmlPort for UseTemporary import coverage
// Fixture table: ALT Universal (60000)

xmlport 60029 "ALT Temp Universal XmlPort"
{
    Caption = 'ALT Universal Temporary XmlPort';
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Universals)
        {
            tableelement(Universal; "ALT Universal")
            {
                UseTemporary = true;
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

                trigger OnAfterInsertRecord()
                var
                    Persisted: Record "ALT Universal";
                begin
                    Persisted.Init();
                    Persisted.TransferFields(Universal, false);
                    Persisted."Entry No." := Universal."Entry No." + 1000;
                    Persisted."Description Field" := 'temp-copy';
                    Persisted.Insert();
                end;
            }
        }
    }
}
