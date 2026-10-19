namespace ALLanguage.IsolationProbe;

// What a test runner resets between the [Test] methods of ONE test codeunit (AL Runner #4826).
//
// Run by the Windows nightly twice: under "Isol Probe Runner Function" (61300,
// TestIsolation = Function) and under the control "Isol Probe Runner Codeunit" (61301).
// OnRun counts itself and inserts a row; T1 sets an AL global, a call counter, a
// SingleInstance field and a row; T2-T7 each read one of them back. The methods are named
// T1..T7 so declaration order and name order agree.
//
// Each assertion states ONE reading: the test codeunit instance is reused across its test
// methods, and Function isolation rolls back the database after each one. A failure message
// carries the observed value, so a red row is itself the measurement:
//   T2 observed 0      -> the AL global was reset: a fresh instance per test.
//   T3 observed 1      -> the same, counted: no earlier test ran on this instance.
//   T4 observed 0      -> SingleInstance state was reset between tests.
//   T5 found the row   -> the database was NOT rolled back after T1 (expected under 61301).
//   T6 no ONRUN row    -> the per-test rollback also discarded what OnRun wrote.
//   T7 observed 0 / 2+ -> OnRun did not run on this instance / ran more than once.
codeunit 61302 "Isol Probe Fixture"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GlobalMark: Integer;
        CallCount: Integer;
        OnRunCount: Integer;

    trigger OnRun()
    var
        ProbeRow: Record "Isol Probe Row";
    begin
        OnRunCount += 1;
        if not ProbeRow.Get('ONRUN') then begin
            ProbeRow."Key" := 'ONRUN';
            ProbeRow.Insert();
        end;
    end;

    [Test]
    procedure T1_SetsGlobalCounterSingleInstanceAndRow()
    var
        ProbeRow: Record "Isol Probe Row";
        ProbeSingleInstance: Codeunit "Isol Probe Single Instance";
    begin
        CallCount += 1;
        GlobalMark := 4826;
        ProbeSingleInstance.SetMark(4826);
        if ProbeRow.Get('MARK') then
            ProbeRow.Delete();
        ProbeRow."Key" := 'MARK';
        ProbeRow.Insert();

        ExpectInteger(1, CallCount, 'T1 must be the first test to run on its instance');
        if not ProbeRow.Get('MARK') then
            Error('T1 could not read back the row it inserted');
    end;

    [Test]
    procedure T2_GlobalSetByT1IsStillSet()
    begin
        CallCount += 1;
        ExpectInteger(4826, GlobalMark, 'AL global set to 4826 by T1 (0 means a fresh codeunit instance per test)');
    end;

    [Test]
    procedure T3_CallCounterCountsEveryEarlierTest()
    begin
        CallCount += 1;
        ExpectInteger(3, CallCount, 'call counter incremented by T1, T2 and T3 (1 means a fresh codeunit instance per test)');
    end;

    [Test]
    procedure T4_SingleInstanceSetByT1IsStillSet()
    var
        ProbeSingleInstance: Codeunit "Isol Probe Single Instance";
    begin
        CallCount += 1;
        ExpectInteger(4826, ProbeSingleInstance.GetMark(), 'SingleInstance mark set to 4826 by T1 (0 means SingleInstance state was reset)');
    end;

    [Test]
    procedure T5_RowInsertedByT1IsRolledBack()
    var
        ProbeRow: Record "Isol Probe Row";
    begin
        CallCount += 1;
        if ProbeRow.Get('MARK') then
            Error('The row T1 inserted is still there in T5: the database was not rolled back after T1 (expected under TestIsolation = Codeunit, not Function)');
    end;

    [Test]
    procedure T6_RowInsertedByOnRunIsStillThere()
    var
        ProbeRow: Record "Isol Probe Row";
    begin
        CallCount += 1;
        if not ProbeRow.Get('ONRUN') then
            Error('The row OnRun inserted is gone in T6: the per-test rollback returned to the state before OnRun, not after it');
    end;

    [Test]
    procedure T7_OnRunRanOnceOnThisInstance()
    begin
        CallCount += 1;
        ExpectInteger(1, OnRunCount, 'OnRun executions counted on the instance T7 runs on (0 means OnRun ran on a different instance)');
    end;

    local procedure ExpectInteger(Expected: Integer; Actual: Integer; What: Text)
    begin
        if Actual <> Expected then
            Error('%1: expected %2, observed %3', What, Expected, Actual);
    end;
}
