// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-run-method
// Scope: in-scope
// Fixtures used: RRE Row (60866), RRE Log (60867), RRE ProcessingOnly Report (60868), RRE Layout Report (60869)
//
// Migrated from AL Runner tests/runner-extras/report-run-execution (RreTests.Codeunit.al).
//
// LEAVE-BEHIND: the source test method InstanceRun_NonProcessingOnly_ThrowsOutOfScopeForRendering
// is deliberately NOT migrated — it pins a runner-specific OutOfScope-throwing contract
// (no service tier to render with) and stays untouched in
// tests/runner-extras/report-run-execution as a runner-specific behaviour test. The
// "RRE Layout Report" object it used is still migrated below because
// InstanceSaveAsXml_ExecutesTriggersAndBody (kept) also uses it.
//
/// <summary>
/// Control experiment for report EXECUTION entry points.
///
/// Observed while fixing the Integer virtual table: a probe report did not execute
/// at all through Report.Run() — OnPreReport never fired, nothing was raised and
/// nothing was written. That is a silent no-op, and it matters because a report
/// that never runs produces no PDF and raises no error.
///
/// That probe was ProcessingOnly with no rendering layout, so the no-op might have
/// been specific to that shape rather than general. These tests separate the
/// possibilities over a REAL table with REAL stored rows, so no virtual-table
/// provider is involved:
///
///   shape A (ProcessingOnly, no layout)  vs  shape B (layout, columns)
///   instance .SaveAs(Xml)  vs  static Report.SaveAs(Xml)
///
/// Each assertion names the entry point, so a fix cannot repair one path while
/// silently leaving another a no-op.
/// </summary>
codeunit 60870 "RRE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "RRE Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row.Name := 'first';
        Row.Insert();
        Row.Init();
        Row."Entry No." := 2;
        Row.Name := 'second';
        Row.Insert();
        Row.Init();
        Row."Entry No." := 3;
        Row.Name := 'third';
        Row.Insert();
    end;

    [Test]
    procedure InstanceSaveAsXml_ExecutesTriggersAndBody()
    var
        Probe: Report "RRE Layout Report";
        TempBlob: Codeunit "Temp Blob";
        ResultOutStream: OutStream;
    begin
        // The dataset (Xml) path is in scope and is what a real consumer drives.
        Initialize();
        Clear(Probe);
        TempBlob.CreateOutStream(ResultOutStream);
        Probe.SaveAs('', ReportFormat::Xml, ResultOutStream);

        if not Probe.DidPreReportRun() then
            Error('instance SaveAs(Xml): OnPreReport never fired — the report did not execute at all.');
        if Probe.RowsProcessed() <> 3 then
            Error('instance SaveAs(Xml): expected 3 body executions, got %1', Probe.RowsProcessed());
    end;

    [Test]
    procedure StaticSaveAsXml_ProducesADatasetNamingTheRows()
    var
        TempBlob: Codeunit "Temp Blob";
        ResultOutStream: OutStream;
        ResultInStream: InStream;
        Dataset: Text;
        Line: Text;
    begin
        // The static form cannot report through report globals, so assert on the OUTPUT:
        // a dataset that actually names a seeded row proves the body ran.
        Initialize();
        TempBlob.CreateOutStream(ResultOutStream);
        Report.SaveAs(Report::"RRE Layout Report", '', ReportFormat::Xml, ResultOutStream);

        TempBlob.CreateInStream(ResultInStream);
        while not ResultInStream.EOS() do begin
            ResultInStream.ReadText(Line);
            Dataset += Line;
        end;

        if Dataset = '' then
            Error('Report.SaveAs(Xml) wrote an EMPTY stream — the report produced no dataset at all.');
        if StrPos(Dataset, 'second') = 0 then
            Error('Report.SaveAs(Xml) dataset does not contain the seeded row "second" — the data item body did not run. Dataset was: %1', CopyStr(Dataset, 1, 300));
    end;
}
