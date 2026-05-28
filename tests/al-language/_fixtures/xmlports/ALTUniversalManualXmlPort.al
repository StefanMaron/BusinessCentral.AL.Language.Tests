// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosave-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/xmlporttableelement/devenv-onbeforeinsertrecord-xmlporttableelement-trigger
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/xmlporttableelement/devenv-onbeforemodifyrecord-xmlporttableelement-trigger
// Scope: fixture XmlPort for AutoSave=false manual insert/modify coverage
// Fixture table: ALT Universal (60000)

xmlport 60028 "ALT Universal Manual XmlPort"
{
    Caption = 'ALT Universal Manual XmlPort';
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Universals)
        {
            tableelement(Universal; "ALT Universal")
            {
                AutoSave = false;
                AutoUpdate = true;
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

                trigger OnAfterInitRecord()
                begin
                    Universal."Description Field" := 'init';
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Universal."Description Field" := CopyStr(StrSubstNo('manual-insert-%1', Universal."Text Field"), 1, MaxStrLen(Universal."Description Field"));
                    Universal.Insert();
                end;

                trigger OnAfterInsertRecord()
                var
                    Persisted: Record "ALT Universal";
                begin
                    Persisted.Get(Universal."Entry No.");
                    Persisted."Description Field" := CopyStr(Persisted."Description Field" + '-after', 1, MaxStrLen(Persisted."Description Field"));
                    Persisted.Modify();
                end;

                trigger OnBeforeModifyRecord()
                var
                    Persisted: Record "ALT Universal";
                begin
                    Persisted.Get(Universal."Entry No.");
                    Persisted."Integer Field" := Universal."Integer Field";
                    Persisted."Text Field" := Universal."Text Field";
                    Persisted."Description Field" := 'manual-modify';
                    Persisted.Modify();
                end;

                trigger OnAfterModifyRecord()
                var
                    Persisted: Record "ALT Universal";
                begin
                    Persisted.Get(Universal."Entry No.");
                    Persisted."Description Field" := CopyStr(Persisted."Description Field" + '-after', 1, MaxStrLen(Persisted."Description Field"));
                    Persisted.Modify();
                end;
            }
        }
    }
}
