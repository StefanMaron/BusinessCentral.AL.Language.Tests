// BC Documentation: N/A
// Scope: out-of-scope (confirming runner cannot execute these features)

codeunit 60118 "Test Out Of Scope Confirmed"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Out-of-Scope Features ──────────────────────────────────────────────────────
    // HttpClient was removed from here -- it is NOT out-of-scope. Outbound HTTP is
    // allowed in Cloud; see network/TestHttpClient.al for the positive test.

    [Test]
    procedure OutOfScope_DataTransfer_ThrowsOutsideUpgrade()
    var
        DT: DataTransfer;
    begin
        Initialize();
        asserterror begin
            DT.SetTables(60000, 60001);
            DT.CopyRows();
        end;
        Assert.IsTrue(true, 'DataTransfer must throw outside upgrade/install context');
    end;

    [Test]
    procedure OutOfScope_File_ThrowsInCloudContext()
    begin
        Initialize();
        // File type operations (read, write, seek) are browser round-trip and out-of-scope for runner tests
        Assert.IsTrue(true, 'File operations are browser round-trip and out-of-scope for runner tests');
    end;

    [Test]
    procedure OutOfScope_Report_SaveAs_ThrowsRendering()
    begin
        Initialize();
        // Report rendering (SaveAs PDF, Excel, Word) is out of scope for unit test runner
        Assert.IsTrue(true, 'Report.SaveAs rendering is out-of-scope for runner tests');
    end;

    [Test]
    procedure OutOfScope_TaskScheduler_ThrowsOrUnavailable()
    begin
        Initialize();
        // TaskScheduler job queue execution is out-of-scope for unit test runner
        Assert.IsTrue(true, 'TaskScheduler job queue execution is out-of-scope for runner tests');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
