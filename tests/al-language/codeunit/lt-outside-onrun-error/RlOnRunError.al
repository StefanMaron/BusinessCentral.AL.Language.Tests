// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-application
// Scope: in-scope
// Probe: AL Runner issue 5748 (writer RL). A test codeunit whose OnRun trigger raises an error: what Microsoft's test runner records for the
//   codeunit and its test methods. Pinned elsewhere: a declared OnRun runs once, before the first test (codeunit/TestTestCodeunitOnRun.al).
// "LT RL OnRun Error" (88221) raises in OnRun; "LT RL OnRun Ok" (88220) is the control with an OnRun that does not raise. The reader
//   (88225, a higher id, so the runner reaches it after both) reads the runner's rows in "Test Method Line" (table 130450 of Microsoft's
//   Test Runner app) for the two codeunits: per row the line type, function name, result, error preview and error code.
// BC versions: 27 - 29

codeunit 88220 "LT RL OnRun Ok"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    [Test]
    procedure OkOnRunFirst()
    begin
    end;

    [Test]
    procedure OkOnRunSecond()
    begin
    end;
}

codeunit 88221 "LT RL OnRun Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        Error('LT RL onrun boom');
    end;

    [Test]
    procedure AfterThrowingOnRun()
    begin
    end;

    [Test]
    procedure AfterThrowingOnRunTwo()
    begin
    end;
}

codeunit 88225 "LT RL OnRun Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RunnerLinesOfOnRunCodeunits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('ok codeunit', Lines(Codeunit::"LT RL OnRun Ok"));
        Observer.Observe('error codeunit', Lines(Codeunit::"LT RL OnRun Error"));
        Observer.Finish();
    end;

    // One entry per "Test Method Line" row of the codeunit, in key order (Test Suite, Line No.):
    //   <line type>:<function>:<result>:<error preview>:<error code>
    local procedure Lines(CodeunitId: Integer): Text
    var
        RecRef: RecordRef;
        Result: Text;
    begin
        RecRef.Open(130450);
        RecRef.Field(4).SetRange(CodeunitId);
        if RecRef.FindSet() then
            repeat
                if Result <> '' then
                    Result += ' ; ';
                Result += Format(RecRef.Field(3).Value()) + ':' + Format(RecRef.Field(6).Value()) + ':' + Format(RecRef.Field(8).Value()) + ':' +
                  Format(RecRef.Field(50).Value()) + ':' + Format(RecRef.Field(51).Value());
            until RecRef.Next() = 0;
        if Result = '' then
            exit('<no rows>');
        exit(Result);
    end;
}
