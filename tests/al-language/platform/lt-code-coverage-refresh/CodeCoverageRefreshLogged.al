// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoveragerefresh-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); the Code Coverage table 2000000049 is a platform virtual table (risky: kept in its own file); test codeunit 72829
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Code Coverage row counts and No. of Hits before and after CodeCoverageRefresh while logging is on, after logging stopped, and CodeCoverageRefresh without logging ever started
// BC versions: 29 (27 and 28 by CI)
// Risky: Code Coverage table may not compile in the Cloud app

codeunit 72829 "LT CodeCoverage Refresh"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Reset()
    var
        CodeCoverage: Record "Code Coverage";
    begin
        CodeCoverageLog(false, false);
        CodeCoverage.DeleteAll();
    end;

    local procedure Work(Value: Integer): Integer
    begin
        if Value > 1 then
            exit(Value * 2);
        exit(Value);
    end;

    local procedure RowCount(): Integer
    var
        CodeCoverage: Record "Code Coverage";
    begin
        exit(CodeCoverage.Count());
    end;

    local procedure OwnRows(var CodeCoverage: Record "Code Coverage")
    begin
        CodeCoverage.Reset();
        CodeCoverage.SetRange("Object Type", CodeCoverage."Object Type"::Codeunit);
        CodeCoverage.SetRange("Object ID", Codeunit::"LT CodeCoverage Refresh");
    end;

    local procedure OwnHits(): Integer
    var
        CodeCoverage: Record "Code Coverage";
        Hits: Integer;
    begin
        OwnRows(CodeCoverage);
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Code);
        if CodeCoverage.FindSet() then
            repeat
                Hits += CodeCoverage."No. of Hits";
            until CodeCoverage.Next() = 0;
        exit(Hits);
    end;

    local procedure OwnHitLines(): Integer
    var
        CodeCoverage: Record "Code Coverage";
    begin
        OwnRows(CodeCoverage);
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Code);
        CodeCoverage.SetFilter("No. of Hits", '>0');
        exit(CodeCoverage.Count());
    end;

    [Test]
    procedure CodeCoverageRefresh_WhileLogging_Result()
    var
        Observer: Codeunit "Probe Observer";
        RowsBefore: Integer;
        HitsBefore: Integer;
        LinesBefore: Integer;
        Dummy: Integer;
    begin
        Reset();
        Observer.Observe('log on', Format(CodeCoverageLog(true, false)));
        Dummy := Work(3);
        Dummy := Work(1);
        RowsBefore := RowCount();
        HitsBefore := OwnHits();
        LinesBefore := OwnHitLines();
        Observer.Observe('rows before nonzero', Format(RowsBefore > 0));
        Observer.Observe('hits before nonzero', Format(HitsBefore > 0));
        Observer.Observe('hit lines before nonzero', Format(LinesBefore > 0));
        CodeCoverageRefresh();
        Observer.Observe('rows same after refresh', Format(RowCount() = RowsBefore));
        Observer.Observe('hit lines same after refresh', Format(OwnHitLines() = LinesBefore));
        Observer.Observe('hits not lower after refresh', Format(OwnHits() >= HitsBefore));
        Observer.Observe('hits grew by more than 100', Format(OwnHits() > HitsBefore + 100));
        Observer.Observe('logging still on', Format(CodeCoverageLog()));
        CodeCoverageLog(false, false);
        Observer.Expect('log on', 'Yes');
        Observer.Expect('rows before nonzero', 'No');
        Observer.Expect('hits before nonzero', 'No');
        Observer.Expect('hit lines before nonzero', 'No');
        Observer.Expect('rows same after refresh', 'No');
        Observer.Expect('hit lines same after refresh', 'No');
        Observer.Expect('hits not lower after refresh', 'Yes');
        Observer.Expect('hits grew by more than 100', 'No');
        Observer.Expect('logging still on', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CodeCoverageRefresh_AfterLoggingStopped_Result()
    var
        Observer: Codeunit "Probe Observer";
        RowsBefore: Integer;
        HitsBefore: Integer;
        Dummy: Integer;
    begin
        Reset();
        CodeCoverageLog(true, false);
        Dummy := Work(5);
        CodeCoverageLog(false, false);
        RowsBefore := RowCount();
        HitsBefore := OwnHits();
        CodeCoverageRefresh();
        Observer.Observe('rows same', Format(RowCount() = RowsBefore));
        Observer.Observe('hits same', Format(OwnHits() = HitsBefore));
        Observer.Observe('logging off', Format(CodeCoverageLog()));
        Observer.Expect('rows same', 'Yes');
        Observer.Expect('hits same', 'Yes');
        Observer.Expect('logging off', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure CodeCoverageRefresh_NeverLogging_Result()
    var
        Observer: Codeunit "Probe Observer";
        Dummy: Integer;
    begin
        Reset();
        Dummy := Work(4);
        Observer.Observe('rows before', Format(RowCount()));
        CodeCoverageRefresh();
        Observer.Observe('rows after', Format(RowCount()));
        Observer.Observe('own hit lines after', Format(OwnHitLines()));
        Observer.Observe('logging', Format(CodeCoverageLog()));
        Observer.Expect('rows before', '0');
        Observer.Expect('rows after', '0');
        Observer.Expect('own hit lines after', '0');
        Observer.Expect('logging', 'No');
        Observer.Verify();
    end;
}
