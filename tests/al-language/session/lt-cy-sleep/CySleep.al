// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-sleep-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained test codeunit 85546
// Probe: corpus issue 670: Sleep(n) waits at least n milliseconds (measured with CurrentDateTime) and Sleep(0) returns without an error.
// Not asserted (Linux suspect, queued for the Windows check): Sleep(-2) and Sleep(-1000) on the BC 29 Linux container end the test with
// "Unexpected CLR exception thrown.: System.ArgumentOutOfRangeException: The value needs to be either -1 (signifying an infinite timeout), 0 or
// a positive integer. (Parameter 'millisecondsDelay')", which a TryFunction does not catch. The probe is NegativeSleepProbe below (not a test).
// Sleep(-1) is not probed: the platform treats -1 as an infinite timeout, and a test that never ends would block the run.
// BC versions: 27.5, 28.5, 29.0
codeunit 85546 "LT CY Sleep"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySleep(Ms: Integer)
    begin
        Sleep(Ms);
    end;

    local procedure SleepResult(Ms: Integer): Text
    begin
        ClearLastError();
        if TrySleep(Ms) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ElapsedAtLeast(Ms: Integer): Boolean
    var
        Start: DateTime;
    begin
        Start := CurrentDateTime();
        Sleep(Ms);
        exit(CurrentDateTime() - Start >= Ms);
    end;

    [Test]
    procedure CY_Sleep_MinimumDuration_And_EdgeValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('sleep 100 waits at least 100 ms', Format(ElapsedAtLeast(100)));
        Observer.Observe('sleep 250 waits at least 250 ms', Format(ElapsedAtLeast(250)));
        Observer.Observe('sleep 0', SleepResult(0));
        Observer.Expect('sleep 100 waits at least 100 ms', 'Yes');
        Observer.Expect('sleep 250 waits at least 250 ms', 'Yes');
        Observer.Expect('sleep 0', 'ok');
        Observer.Verify();
    end;

    // Linux suspect probe, kept for the Windows check (not a [Test]): see the header.
    procedure NegativeSleepProbe(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('sleep -2', SleepResult(-2));
        Observer.Observe('sleep -1000', SleepResult(-1000));
    end;
}
