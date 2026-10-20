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

    local procedure DumpRuns(): Text
    var
        TestsRun: Record "Code Coverage Tests Run";
        TestLookup: Record "Code Coverage Test Lookup";
        Result: Text;
    begin
        if TestsRun.FindSet() then
            repeat
                Result += StrSubstNo('[%1 obj=%2 methodid=%3 testid=%4:', TestsRun."Method Name", TestsRun."Object ID", TestsRun."Method ID", TestsRun."Test ID");
                TestLookup.SetRange("Test ID", TestsRun."Test ID");
                if TestLookup.FindSet() then
                    repeat
                        Result += StrSubstNo(' %1 %2 %3', TestLookup."Object Type", TestLookup."Object ID", TestLookup."Method ID");
                    until TestLookup.Next() = 0;
                Result += '] ';
            until TestsRun.Next() = 0;
        exit(Result);
    end;

    local procedure DumpLookups(): Text
    var
        TestLookup: Record "Code Coverage Test Lookup";
        Result: Text;
    begin
        if TestLookup.FindSet() then
            repeat
                Result += StrSubstNo('(%1 %2 %3 test %4) ', TestLookup."Object Type", TestLookup."Object ID", TestLookup."Method ID", TestLookup."Test ID");
            until TestLookup.Next() = 0;
        exit(Result + 'count=' + Format(TestLookup.Count()));
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
        Observer.Observe('runs', DumpRuns());
        Observer.Observe('lookups', DumpLookups());
        Observer.Observe('lines_a', DumpLineMethodIds(Codeunit::"LT PX CC Target A"));
        Observer.Observe('lines_b', DumpLineMethodIds(Codeunit::"LT PX CC Target B"));
        Initialize();
        Observer.Expect('runs', '[PxRunsASameOne obj=86163 methodid=-1803411697 testid=-1910502296: Codeunit 86164 -130816186] [PxRunsBNoArgs obj=86163 methodid=667973114 testid=-1527742205: Codeunit 86165 1569086646] [PxRunsATextArg obj=86163 methodid=-652159326 testid=113543347: Codeunit 86164 -1663764975] [PxRunsAIntArg obj=86163 methodid=-133430896 testid=174429217: Codeunit 86164 -370288627] [PxRunsANoArgs obj=86163 methodid=1797822318 testid=568644803: Codeunit 86164 1569086646] [PxRunsASameTwo obj=86163 methodid=-450565804 testid=2025528333: Codeunit 86164 -1760197669] ');
        Observer.Expect('lookups', '(Codeunit 86164 -1760197669 test 2025528333) (Codeunit 86164 -1663764975 test 113543347) (Codeunit 86164 -370288627 test 174429217) (Codeunit 86164 -130816186 test -1910502296) (Codeunit 86164 1569086646 test 568644803) (Codeunit 86165 1569086646 test -1527742205) count=6');
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
        Observer.Observe('first', DumpRuns());
        CodeCoverageLog(true, false);
        PxRunsBNoArgs();
        CodeCoverageLog(false, false);
        Observer.Observe('second_without_reset', DumpRuns());
        Initialize();
        Observer.Expect('first', '[MethodA obj=67334 methodid=915199647 testid=-1061756221:] [PxRunsANoArgs obj=86163 methodid=1797822318 testid=568644803: Codeunit 86164 1569086646] ');
        Observer.Expect('second_without_reset', '[PxRunsBNoArgs obj=86163 methodid=667973114 testid=-1527742205: Codeunit 86165 1569086646] ');
        Observer.Verify();
    end;
}
