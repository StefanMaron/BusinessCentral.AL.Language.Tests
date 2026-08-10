// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope (documented BC-on-Linux platform limitation)
// Fixtures used: RSS Sample (60871), RSS Fixture Report (60872); shared Assert (60021)
//
// CLAIM: Report.SaveAs against an RDLC layout, format Pdf, returns false with
// GetLastErrorText() set on BC-on-Linux -- the Windows Reporting Service RDLC
// renderer is stubbed out on that platform (bc-linux StartupHook.cs Patch #19;
// see MsDyn365Bc.On.Linux issue #28). This is a platform limitation, not
// documented Cloud SaaS behavior -- real BC SaaS runs on Windows and actually
// renders RDLC. If BC-on-Linux ever implements this, this test starts failing
// (SaveAs stops returning false) and should flip to asserting the real
// rendered content, matching the Xml SaveAs test in TestReportSaveAsStream.al.

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
    procedure SaveAsPdf_RdlcLayout_ReturnsFalseWithLastErrorTextOnLinux()
    var
        Sample: Record "RSS Sample";
        BlobRec: Record "RSS Sample";
        OutStr: OutStream;
        Ok: Boolean;
    begin
        Initialize();
        Sample."Entry No." := 1;
        Sample.Description := 'RSSPDF-9f1c2b3a';
        Sample.Amount := 42.5;
        Sample.Insert();

        BlobRec."Blob Data".CreateOutStream(OutStr);
        Ok := Report.SaveAs(Report::"RSS Fixture Report", '', ReportFormat::Pdf, OutStr);

        Assert.IsFalse(Ok, 'Report.SaveAs(Pdf) must return false on BC-on-Linux -- RDLC rendering is not implemented there');
        Assert.ExpectedError('RDLC report rendering is not implemented on Linux BC');
    end;
}
