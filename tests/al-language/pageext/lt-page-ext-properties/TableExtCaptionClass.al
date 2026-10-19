// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: own table 72304, tableextension 72305, page 72306, codeunit 72307
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 72304 "LT P123 CCBase"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

tableextension 72305 "LT P123 CCBase Ext" extends "LT P123 CCBase"
{
    fields
    {
        field(72303; CapClassed; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Plain caption';
            CaptionClass = '3,Class caption';
        }
    }
}

page 72306 "LT P123 CCBase Page"
{
    PageType = Card;
    SourceTable = "LT P123 CCBase";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(CapClassed; Rec.CapClassed) { ApplicationArea = All; }
        }
    }
}

codeunit 72307 "LT P123 CaptionClass Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P123_ExtFieldCaptionClass()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P123 CCBase";
        P: TestPage "LT P123 CCBase Page";
    begin
        T.DeleteAll();
        T.Init(); T.Id := 1; T.Insert();
        Observer.Observe('fieldcaption', T.FieldCaption(CapClassed));
        P.OpenEdit();
        Observer.Observe('page field caption', P.CapClassed.Caption());
        Observer.Expect('fieldcaption', 'Class caption');
        Observer.Expect('page field caption', 'Class caption');
        Observer.Verify();
    end;
}
