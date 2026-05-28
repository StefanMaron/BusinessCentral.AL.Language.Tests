// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/xmlporttextelement/devenv-onbeforepassvariable-xmlporttextelement-trigger
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/xmlporttextelement/devenv-onafterassignvariable-xmlporttextelement-trigger
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/xmlportfieldelement/devenv-onafterassignfield-xmlportfieldelement-trigger
// Scope: fixture XmlPort for unbound text/attribute and trigger-driven mutation coverage
// Fixture table: ALT Universal (60000)

xmlport 60025 "ALT Variable XmlPort"
{
    Caption = 'ALT Variable XmlPort';
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Universals)
        {
            tableelement(Universal; "ALT Universal")
            {
                XmlName = 'Universal';

                textattribute(NoteAttr)
                {
                    trigger OnBeforePassVariable()
                    begin
                        NoteAttr := CopyStr(UpperCase(Universal."Text Field"), 1, MaxStrLen(NoteAttr));
                    end;

                    trigger OnAfterAssignVariable()
                    begin
                        Universal."Description Field" := NoteAttr;
                    end;
                }

                fieldelement(EntryNo; Universal."Entry No.")
                {
                }
                fieldelement(IntegerValue; Universal."Integer Field")
                {
                    trigger OnAfterAssignField()
                    begin
                        Universal."Integer Field" := Universal."Integer Field" * 10;
                    end;
                }

                textelement(DisplayText)
                {
                    trigger OnBeforePassVariable()
                    begin
                        DisplayText := StrSubstNo('TXT:%1', Universal."Text Field");
                    end;

                    trigger OnAfterAssignVariable()
                    begin
                        Universal."Text Field" := CopyStr(CopyStr(DisplayText, 5), 1, MaxStrLen(Universal."Text Field"));
                    end;
                }
            }
        }
    }
}
