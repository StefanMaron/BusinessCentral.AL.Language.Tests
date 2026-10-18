// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// Fixtures used: Probe Observer (codeunit 69160); table "LT AB Row" (77000), codeunit "LT AB Log" (77050), layout file FixtureLayout.rdlc of the app root; own report 77090, report extension 77091, test codeunit 77092
// Facts: OnPreRendering of a report extension: whether and when it runs (against the OnPreReport of the report and the rendering), its RenderingPayload argument, and whether a change to the argument reaches the output.

report 77090 "LT AB Render Report"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = RdlcLayout;

    dataset
    {
        dataitem(T; "LT AB Row")
        {
            column(EntryNo; Id) { }
            column(Description; Name) { }
            column(Amount; Level) { }
        }
    }

    rendering
    {
        layout(RdlcLayout)
        {
            Type = RDLC;
            LayoutFile = './FixtureLayout.rdlc';
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('report OnPreReport');
    end;

    trigger OnPostReport()
    begin
        Log.Add('report OnPostReport');
    end;

    var
        Log: Codeunit "LT AB Log";
}

reportextension 77091 "LT AB Render Report Ext" extends "LT AB Render Report"
{
    trigger OnPreRendering(var RenderingPayload: JsonObject)
    begin
        Log.Add('ext OnPreRendering keys=' + Format(RenderingPayload.Keys().Count()));
        RenderingPayload.Add('LTABKey', 'LTABValue');
    end;

    var
        Log: Codeunit "LT AB Log";
}

codeunit 77092 "LT AB Render Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT AB Row";
        Log: Codeunit "LT AB Log";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Insert();
        Commit();
        Log.Reset();
    end;

    [Test]
    procedure SaveAsPdf()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutStr);
        asserterror Report.SaveAs(Report::"LT AB Render Report", '', ReportFormat::Pdf, OutStr);
        Observer.ObserveError('saveas-pdf');
        Observer.Observe('log', Log.Dump());
        Observer.Observe('has-output', Format(TempBlob.Length() > 0));
        Observer.Finish();
    end;

    [Test]
    procedure SaveAsWord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutStr);
        asserterror Report.SaveAs(Report::"LT AB Render Report", '', ReportFormat::Word, OutStr);
        Observer.ObserveError('saveas-word');
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure SaveAsXml()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutStr);
        asserterror Report.SaveAs(Report::"LT AB Render Report", '', ReportFormat::Xml, OutStr);
        Observer.ObserveError('saveas-xml');
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure RunWithoutOutput()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
    begin
        Seed();
        asserterror Report.Run(Report::"LT AB Render Report");
        Observer.ObserveError('run');
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;
}
