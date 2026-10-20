// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoveragelog-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); declares codeunits 86163-86165; calls test procedures of codeunit 67334 "W6 Code Coverage Ids"
// Probe: writer PX, probes-needed "Platform tables and session facts": Code Coverage Test Lookup "Method ID" of procedures with different and
// equal signatures, in one codeunit and in two; Tests Run "Method ID" and "Test ID" in a second test codeunit and across recordings.
// Line numbers in lines_a/lines_b count from the first line of the object text (for the first object of the file, the file start).
// Rule seen (BC 29 local): a Test Lookup Method ID is the Method Id of the procedure's Trigger/Function row in Code Coverage; equal for the same
// name and signature in two codeunits (NoArgs), different for different names with one signature. Tests Run rows have their own Method ID and
// Test ID per test procedure. A new CodeCoverageLog(true, ...) without clearing keeps only the rows of the new recording.
// BC versions: 27, 28, 29

codeunit 86164 "LT PX CC Target A"
{
    procedure NoArgs()
    begin
    end;

    procedure IntArg(X: Integer)
    begin
        if X = 0 then
            exit;
    end;

    procedure TextArgReturns(T: Text): Integer
    begin
        exit(StrLen(T));
    end;

    procedure SameSigOne()
    begin
    end;

    procedure SameSigTwo()
    begin
    end;
}

codeunit 86165 "LT PX CC Target B"
{
    procedure NoArgs()
    begin
    end;
}

codeunit 86163 "LT PX Code Coverage Ids"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        CodeCoverage: Record "Code Coverage";
        TestLookup: Record "Code Coverage Test Lookup";
        TestsRun: Record "Code Coverage Tests Run";
    begin
        CodeCoverageLog(false, false);
        CodeCoverageLog(false, true);
        CodeCoverage.DeleteAll();
        TestLookup.DeleteAll();
        TestsRun.DeleteAll();
    end;

    // helper tests: each calls one target procedure while a recording test runs them; they observe nothing.
    [Test]
    procedure PxRunsANoArgs()
    var
        A: Codeunit "LT PX CC Target A";
    begin
        A.NoArgs();
    end;

    [Test]
    procedure PxRunsAIntArg()
    var
        A: Codeunit "LT PX CC Target A";
    begin
        A.IntArg(1);
    end;

    [Test]
    procedure PxRunsATextArg()
    var
        A: Codeunit "LT PX CC Target A";
    begin
        if A.TextArgReturns('ab') = 0 then
            Error('unreachable');
    end;

    [Test]
    procedure PxRunsASameOne()
    var
        A: Codeunit "LT PX CC Target A";
    begin
        A.SameSigOne();
    end;

    [Test]
    procedure PxRunsASameTwo()
    var
        A: Codeunit "LT PX CC Target A";
    begin
        A.SameSigTwo();
    end;

    [Test]
    procedure PxRunsBNoArgs()
    var
        B: Codeunit "LT PX CC Target B";
    begin
        B.NoArgs();
    end;

    // Rows in the order of Names (Tests Run is keyed by its Test ID, a number that changes from run to run, so neither the Test ID nor
    // the row order is asserted). The Test Lookup rows of a run are found through its Test ID. testids_distinct: every row has its own one.
    local procedure DumpRuns(Names: Text): Text
    var
        TestsRun: Record "Code Coverage Tests Run";
        TestLookup: Record "Code Coverage Test Lookup";
        Seen: List of [Integer];
        Name: Text;
        Result: Text;
        Distinct: Boolean;
    begin
        Distinct := true;
        foreach Name in Names.Split(',') do begin
            TestsRun.SetRange("Method Name", Name);
            if TestsRun.FindSet() then
                repeat
                    if Seen.Contains(TestsRun."Test ID") then
                        Distinct := false;
                    Seen.Add(TestsRun."Test ID");
                    Result += StrSubstNo('[%1 obj=%2 methodid=%3:', TestsRun."Method Name", TestsRun."Object ID", TestsRun."Method ID");
                    TestLookup.SetRange("Test ID", TestsRun."Test ID");
                    if TestLookup.FindSet() then
                        repeat
                            Result += StrSubstNo(' %1 %2 %3', TestLookup."Object Type", TestLookup."Object ID", TestLookup."Method ID");
                        until TestLookup.Next() = 0;
                    Result += '] ';
                until TestsRun.Next() = 0;
        end;
        TestsRun.Reset();
        exit(Result + StrSubstNo('rows=%1 testids_distinct=%2', TestsRun.Count(), Distinct));
    end;

    local procedure DumpLookups(): Text
    var
        TestLookup: Record "Code Coverage Test Lookup";
    begin
        exit('count=' + Format(TestLookup.Count()));
    end;

    local procedure DumpLineMethodIds(ObjectId: Integer): Text
    var
        CodeCoverage: Record "Code Coverage";
        Result: Text;
    begin
        CodeCoverage.SetRange("Object Type", CodeCoverage."Object Type"::Codeunit);
        CodeCoverage.SetRange("Object ID", ObjectId);
        if CodeCoverage.FindSet() then
            repeat
                Result += StrSubstNo('L%1:%2/%3 ', CodeCoverage."Line No.", CodeCoverage."Line Type", CodeCoverage."Method Id");
            until CodeCoverage.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure PX_MethodIds_OfSixProcedures_TwoCodeunits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        PxRunsANoArgs();
        PxRunsAIntArg();
        PxRunsATextArg();
        PxRunsASameOne();
        PxRunsASameTwo();
        PxRunsBNoArgs();
        CodeCoverageLog(false, false);
        Observer.Observe('runs', DumpRuns('PxRunsANoArgs,PxRunsAIntArg,PxRunsATextArg,PxRunsASameOne,PxRunsASameTwo,PxRunsBNoArgs'));
        Observer.Observe('lookups', DumpLookups());
        Observer.Observe('lines_a', DumpLineMethodIds(Codeunit::"LT PX CC Target A"));
        Observer.Observe('lines_b', DumpLineMethodIds(Codeunit::"LT PX CC Target B"));
        Initialize();
        Observer.Expect('runs', '[PxRunsANoArgs obj=86163 methodid=1797822318: Codeunit 86164 1569086646] [PxRunsAIntArg obj=86163 methodid=-133430896: Codeunit 86164 -370288627] [PxRunsATextArg obj=86163 methodid=-652159326: Codeunit 86164 -1663764975] [PxRunsASameOne obj=86163 methodid=-1803411697: Codeunit 86164 -130816186] [PxRunsASameTwo obj=86163 methodid=-450565804: Codeunit 86164 -1760197669] [PxRunsBNoArgs obj=86163 methodid=667973114: Codeunit 86165 1569086646] rows=6 testids_distinct=Yes');
        Observer.Expect('lookups', 'count=6');
        Observer.Expect('lines_a', 'L0:Object/-1 L14:Trigger/Function/1569086646 L15:Empty/-1 L16:Empty/-1 L18:Trigger/Function/-370288627 L19:Empty/-1 L20:Code/-370288627 L21:Code/-370288627 L22:Empty/-1 L24:Trigger/Function/-1663764975 L25:Empty/-1 L26:Code/-1663764975 L27:Empty/-1 L29:Trigger/Function/-130816186 L30:Empty/-1 L31:Empty/-1 L33:Trigger/Function/-1760197669 L34:Empty/-1 L35:Empty/-1 ');
        Observer.Expect('lines_b', 'L0:Object/-1 L4:Trigger/Function/1569086646 L5:Empty/-1 L6:Empty/-1 ');
        Observer.Verify();
    end;

    [Test]
    procedure PX_TestIds_TwoRecordings_AndAnotherTestCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        W6: Codeunit "W6 Code Coverage Ids";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        PxRunsANoArgs();
        W6.MethodA();
        CodeCoverageLog(false, false);
        Observer.Observe('first', DumpRuns('MethodA,PxRunsANoArgs,PxRunsBNoArgs'));
        CodeCoverageLog(true, false);
        PxRunsBNoArgs();
        CodeCoverageLog(false, false);
        Observer.Observe('second_without_reset', DumpRuns('MethodA,PxRunsANoArgs,PxRunsBNoArgs'));
        Initialize();
        Observer.Expect('first', '[MethodA obj=67334 methodid=915199647:] [PxRunsANoArgs obj=86163 methodid=1797822318: Codeunit 86164 1569086646] rows=2 testids_distinct=Yes');
        Observer.Expect('second_without_reset', '[PxRunsBNoArgs obj=86163 methodid=667973114: Codeunit 86165 1569086646] rows=1 testids_distinct=Yes');
        Observer.Verify();
    end;
}
