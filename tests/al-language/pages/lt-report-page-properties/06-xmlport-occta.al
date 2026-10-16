// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

xmlport 72159 "LT P121 XP TextAttrOcc"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textattribute(OptAttr)
            {
                Occurrence = Optional;

                trigger OnAfterAssignVariable()
                begin
                    Log.Add('opt=' + OptAttr);
                end;
            }
            textattribute(ReqAttr)
            {
                Occurrence = Required;

                trigger OnAfterAssignVariable()
                begin
                    Log.Add('req=' + ReqAttr);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT P121 Log";

}

codeunit 72160 "LT P121 XP TextAttrOcc Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P121_Import()
    var
        Helper: Codeunit "LT P121 Helper";
        Log: Codeunit "LT P121 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Helper.ImportText(Xmlport::"LT P121 XP TextAttrOcc", '<Root OptAttr="o" ReqAttr="r"/>');
        Observer.Observe('log_both', Log.Take());
        Helper.ImportText(Xmlport::"LT P121 XP TextAttrOcc", '<Root ReqAttr="r2"/>');
        Observer.Observe('log_no_optional', Log.Take());
        asserterror Helper.ImportText(Xmlport::"LT P121 XP TextAttrOcc", '<Root OptAttr="o3"/>');
        Observer.ObserveError('missing_required');
        Observer.Observe('log_after_error', Log.Take());
        Observer.Expect('log_both', 'val Qty=1;val Qty=2;opt=o;req=r;');
        Observer.Expect('log_no_optional', 'req=r2;');
        Observer.Expect('missing_required|text', 'Imported XML cannot validate with the schema: The required attribute ''ReqAttr'' is missing.');
        Observer.Expect('missing_required|code', 'XmlPortInvalidXml');
        Observer.Expect('log_after_error', '');
        Observer.Verify();
    end;

}
