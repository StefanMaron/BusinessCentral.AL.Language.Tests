// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: RSS Sample (60871), RSS Fixture Report (60872); shared Assert (60021)
//
// CLAIM: Report.SaveAs against an RDLC layout, format Pdf, works in Cloud. External
// rendering was previously assumed (wrongly) to be out-of-scope; this proves the real
// behavior against a stream target -- never a canned or empty PDF.

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
    procedure SaveAsPdf_RdlcLayout_ReturnsNonEmptyStream()
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
            'Report.SaveAs(Pdf) must return true against a real RDLC layout in Cloud');

        Assert.IsTrue(
            BlobRec."Blob Data".HasValue(), 'Report.SaveAs(Pdf) must produce a non-empty PDF stream');
    end;
}
