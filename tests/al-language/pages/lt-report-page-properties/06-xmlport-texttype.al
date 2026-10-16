// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

xmlport 72165 "LT P121 XP TextType"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textattribute(BigAttr)
            {
                TextType = BigText;

                trigger OnBeforePassVariable()
                begin
                    BigAttr.AddText('big out');
                end;

                trigger OnAfterAssignVariable()
                begin
                    Log.Add('big=' + Format(BigAttr.Length()));
                end;
            }
            textattribute(TxtAttr)
            {
                TextType = Text;

                trigger OnBeforePassVariable()
                begin
                    TxtAttr := 'txt out';
                end;

                trigger OnAfterAssignVariable()
                begin
                    Log.Add('txt=' + TxtAttr);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT P121 Log";

}

codeunit 72166 "LT P121 XP TextType Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P121_Export()
    var
        Helper: Codeunit "LT P121 Helper";
        Log: Codeunit "LT P121 Log";
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Observer.Observe('xml', Helper.ExportText(Xmlport::"LT P121 XP TextType"));
        Observer.ObserveError('af65');
        Observer.Expect('af65|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af65|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure P121_Import()
    var
        Helper: Codeunit "LT P121 Helper";
        Log: Codeunit "LT P121 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Helper.ImportText(Xmlport::"LT P121 XP TextType", '<Root BigAttr="bigvalue" TxtAttr="textvalue"/>');
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'val Txt=x#T#62;big=8;txt=textvalue;');
        Observer.Verify();
    end;

}
