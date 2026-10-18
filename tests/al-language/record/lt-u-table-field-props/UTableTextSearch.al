// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-optimizefortextsearch-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (issue 599): the MaxLength option of Caption on a table and a field. OptimizeForTextSearch is not probed: a table with it cannot be published to the OnPrem containers (no SQL Server Full-Text Search). Object ids 69580 and 69584.

table 69580 "LT U Text Search"
{
    DataClassification = SystemMetadata;
    Caption = 'Text search caption', MaxLength = 5;

    fields
    {
        field(1; Id; Integer) { }
        field(3; Txt; Text[30])
        {
            Caption = 'Text field caption', MaxLength = 4;
        }
        field(4; Plain; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69584 "LT U Text Search Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure MaxLength_CaptionLongerThanLimit()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT U Text Search";
    begin
        Observer.Observe('table_caption', Rec.TableCaption());
        Observer.Observe('table_caption_length', Format(StrLen(Rec.TableCaption())));
        Observer.Observe('field_caption', Rec.FieldCaption(Txt));
        Observer.Observe('field_caption_length', Format(StrLen(Rec.FieldCaption(Txt))));
        Observer.Finish();
    end;
}
