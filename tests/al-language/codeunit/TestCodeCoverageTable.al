// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoveragelog-method
// Scope: in-scope
// Fixtures used: none (the Code Coverage table 2000000049 is a platform virtual table)
// Note: the companion to codeunit 60339 "Test Code Coverage Start Stop", which pins the
//       single-session state transitions. This codeunit pins two things 60339 does not:
//       the multi-session spelling CODECOVERAGELOG(TRUE, TRUE), and what the Code Coverage
//       table holds once recording stops.
//
//       Written for AlRunner#4468, where the runner started recording for the first time
//       and began serving the three code-coverage virtual tables through the platform's own
//       providers. The line-rows arm is the one a runner can only pass by projecting real AL
//       source; the DeleteAll arm is the one it must pass WITHOUT source, which is what makes
//       the pair discriminating.
// BC versions: 24+

codeunit 60341 "Test Code Coverage Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        CodeCoverage: Record "Code Coverage";
    begin
        CodeCoverageLog(false, false);
        CodeCoverageLog(false, true);
        CodeCoverage.DeleteAll();
    end;

    local procedure DoubleIfAboveOne(Value: Integer): Integer
    begin
        if Value > 1 then
            exit(Value * 2);
        exit(Value);
    end;

    [Test]
    procedure CodeCoverageLog_MultiSession_StartThenQuery_ReportsRecording()
    begin
        Initialize();

        // [WHEN] multi-session recording is started
        // [THEN] the call reports back the requested state
        Assert.IsTrue(CodeCoverageLog(true, true), 'CODECOVERAGELOG(TRUE, TRUE) must return the requested state, TRUE.');

        // [THEN] and the query form reports that the session is recording
        Assert.IsTrue(CodeCoverageLog(), 'CODECOVERAGELOG() must answer true once multi-session recording has started.');

        // [THEN] stopping it returns the session to not-recording
        Assert.IsFalse(CodeCoverageLog(false, true), 'CODECOVERAGELOG(FALSE, TRUE) must return the requested state, FALSE.');
        Assert.IsFalse(CodeCoverageLog(), 'CODECOVERAGELOG() must answer false once multi-session recording has stopped.');
    end;

    [Test]
    procedure CodeCoverage_AfterRecording_HasHitLineForCoveredCodeunit()
    var
        CodeCoverage: Record "Code Coverage";
    begin
        Initialize();

        // [GIVEN] a procedure of this codeunit ran while recording
        CodeCoverageLog(true, false);
        Assert.AreEqual(6, DoubleIfAboveOne(3), 'the recorded procedure must run.');
        CodeCoverageLog(false, false);

        // [THEN] the Code Coverage table holds a code line of this codeunit that was hit
        CodeCoverage.SetRange("Object Type", CodeCoverage."Object Type"::Codeunit);
        CodeCoverage.SetRange("Object ID", Codeunit::"Test Code Coverage Table");
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Code);
        CodeCoverage.SetFilter("No. of Hits", '>0');
        Assert.IsFalse(CodeCoverage.IsEmpty(), 'recording must leave a hit code line for the codeunit that ran.');
    end;

    [Test]
    procedure CodeCoverage_DeleteAll_AfterRecording_LeavesTableEmpty()
    var
        CodeCoverage: Record "Code Coverage";
    begin
        Initialize();

        // [GIVEN] something was recorded
        CodeCoverageLog(true, false);
        DoubleIfAboveOne(3);
        CodeCoverageLog(false, false);

        // [WHEN] the table is emptied
        CodeCoverage.DeleteAll();

        // [THEN] nothing is left, and reading it does not fail
        Assert.IsTrue(CodeCoverage.IsEmpty(), 'Code Coverage must be empty after DeleteAll.');
    end;
}
