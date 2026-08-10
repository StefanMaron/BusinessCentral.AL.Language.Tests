// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: RSS Sample (60871), RSS Fixture Report (60872); shared Assert (60021)
//
// CLAIM: Report.SaveAs against an RDLC layout, format Pdf, returns true but produces an
// EMPTY blob on BC-on-Linux -- observed and reproducible on both BC 27.5 and BC 28.3.
// SaveAs does not throw or report an error; it silently returns no rendered content.
// This looks like a gap in BC-on-Linux's RDLC-to-PDF rendering pipeline rather than
// documented Cloud behavior -- flagged upstream (MsDyn365Bc.On.Linux). If that's fixed,
// this test should start failing here (HasValue() becomes true) and needs updating to
// assert the real rendered content, matching the Xml SaveAs test in TestReportSaveAsStream.al.

codeunit 60878 "Test Report SaveAs Pdf"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Sample: Record "RSS Sample";
    begin
        Sample.DeleteAll();
    end;

    [Test]
    procedure SaveAsPdf_RdlcLayout_ReturnsTrueWithEmptyBlobOnLinux()
    var
        Sample: Record "RSS Sample";
        BlobRec: Record "RSS Sample";
        OutStr: OutStream;
    begin
        Initialize();
        Sample."Entry No." := 1;
        Sample.Description := 'RSSPDF-9f1c2b3a';
        Sample.Amount := 42.5;
        Sample.Insert();

        BlobRec."Blob Data".CreateOutStream(OutStr);
        Assert.IsTrue(
            Report.SaveAs(Report::"RSS Fixture Report", '', ReportFormat::Pdf, OutStr),
            'Report.SaveAs(Pdf) must return true -- it does not surface a rendering failure as an error');

        Assert.IsFalse(
            BlobRec."Blob Data".HasValue(),
            'Report.SaveAs(Pdf) currently produces an empty blob on BC-on-Linux -- see comment above');
    end;
}
