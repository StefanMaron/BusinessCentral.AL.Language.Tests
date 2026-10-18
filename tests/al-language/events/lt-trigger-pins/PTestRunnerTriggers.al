// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testrunner-codeunits
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunits 67284-67288
// RISKY (runtime): a test that runs a codeunit of Subtype = TestRunner while the corpus runs under Microsoft's top-level runner; what a test sees is observed.
//
// The triggers OnBeforeTestRun (its Boolean result decides whether the test method runs) and OnAfterTestRun (it receives the success flag) of a test runner codeunit, and a runner without them.
// BC versions: 27, 28, 29
codeunit 67284 "LT P Runner Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];
        FailSubject: Boolean;
        SkipMethod: Text;

    procedure Reset()
    begin
        Clear(Entries);
        FailSubject := false;
        SkipMethod := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure Joined(): Text
    var
        E: Text;
        R: Text;
    begin
        foreach E in Entries do
            R += E + ';';
        exit(R);
    end;

    procedure SetFailSubject(Value: Boolean)
    begin
        FailSubject := Value;
    end;

    procedure GetFailSubject(): Boolean
    begin
        exit(FailSubject);
    end;

    procedure SetSkipMethod(Value: Text)
    begin
        SkipMethod := Value;
    end;

    procedure GetSkipMethod(): Text
    begin
        exit(SkipMethod);
    end;
}

codeunit 67285 "LT P Runner Subject"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PSubjectOne()
    var
        Log: Codeunit "LT P Runner Log";
    begin
        Log.Add('body One');
    end;

    [Test]
    procedure PSubjectTwo()
    var
        Log: Codeunit "LT P Runner Log";
    begin
        Log.Add('body Two');
        if Log.GetFailSubject() then
            Error('LT P subject failed on purpose');
    end;
}

codeunit 67286 "LT P Runner With Triggers"
{
    Subtype = TestRunner;

    trigger OnRun()
    var
        Log: Codeunit "LT P Runner Log";
    begin
        Log.Add('runner OnRun');
        Codeunit.Run(Codeunit::"LT P Runner Subject");
    end;

    trigger OnBeforeTestRun(CodeunitId: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    var
        Log: Codeunit "LT P Runner Log";
    begin
        Log.Add(StrSubstNo('before %1 %2 %3 %4', CodeunitId, CodeunitName, FunctionName, Format(FunctionTestPermissions)));
        exit(FunctionName <> Log.GetSkipMethod());
    end;

    trigger OnAfterTestRun(CodeunitId: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    var
        Log: Codeunit "LT P Runner Log";
    begin
        Log.Add(StrSubstNo('after %1 %2 %3 %4', CodeunitId, CodeunitName, FunctionName, Format(IsSuccess)));
    end;
}

codeunit 67287 "LT P Runner Without Triggers"
{
    Subtype = TestRunner;

    trigger OnRun()
    var
        Log: Codeunit "LT P Runner Log";
    begin
        Log.Add('plain runner OnRun');
        Codeunit.Run(Codeunit::"LT P Runner Subject");
    end;
}

codeunit 67288 "LT P Runner Triggers Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRun(RunnerId: Integer)
    begin
        Codeunit.Run(RunnerId);
    end;

    local procedure RunRunner(var Observer: Codeunit "Probe Observer"; RunnerId: Integer)
    var
        Log: Codeunit "LT P Runner Log";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryRun(RunnerId);
        Observer.Observe('run_ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('run_error');
        Observer.Observe('log', Log.Joined());
    end;

    [Test]
    procedure PRunner_Triggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P Runner Log";
    begin
        Log.Reset();
        RunRunner(Observer, Codeunit::"LT P Runner With Triggers");
        Observer.Finish();
    end;

    [Test]
    procedure PRunner_BeforeTestRunSkipsAndAfterReportsFailure()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P Runner Log";
    begin
        Log.Reset();
        Log.SetSkipMethod('PSubjectOne');
        Log.SetFailSubject(true);
        RunRunner(Observer, Codeunit::"LT P Runner With Triggers");
        Log.Reset();
        Observer.Finish();
    end;

    [Test]
    procedure PRunner_WithoutTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P Runner Log";
    begin
        Log.Reset();
        RunRunner(Observer, Codeunit::"LT P Runner Without Triggers");
        Observer.Finish();
    end;
}
