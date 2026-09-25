// Fixture for TestCodeunitTryFunctionNoExitReturn (codeunit 60349).
//
// Every method here has NO `exit` anywhere in its body. They differ in ONE thing:
// whether the declaration carries [TryFunction]. That is the distinction the tests
// exist to pin, because the two shapes look identical in AL source — neither
// declares a return type, neither contains an `exit` — and they return OPPOSITE
// values.
//
// The [TryFunction] bodies mirror Codeunit 2000 "Time Series Management"
// .GetMLForecastCredentials: a discarded cross-codeunit call followed by a byref
// write, under [NonDebuggable] + [TryFunction] + [Scope('OnPrem')].

codeunit 60366 "ALTTryFunctionNoExitProbe"
{
    var
        Callee: Codeunit "ALTImplicitReturnCallee";

    // ── [TryFunction], no exit, no error ────────────────────────────────────────
    // A TryFunction's Boolean is synthesized by the attribute and means "the body
    // completed without raising", so falling off the end answers TRUE.

    [TryFunction]
    procedure TryEmptyBody()
    begin
    end;

    [TryFunction]
    procedure TryAfterCallOutThenByRefWrite(var Sink: Text)
    begin
        Callee.DoVoidWork();
        Sink := Sink + '/suffix';
    end;

    // Codeunit 2000 also carries [NonDebuggable], so the test measures that
    // combination rather than [TryFunction] alone.
    //
    // Its third attribute, [Scope('OnPrem')], is deliberately NOT reproduced: a
    // Cloud-target app cannot call an OnPrem-scoped method at all -- `error AL0296:
    // The application object or method '...' has scope 'OnPrem' and cannot be used
    // for 'Cloud' development`, measured on this file. That is a compile-time
    // visibility rule with no bearing on what the synthesized return answers, which
    // is what these tests are about.
    [NonDebuggable]
    [TryFunction]
    procedure TryNonDebuggableAfterCallOut(var Sink: Text)
    begin
        Callee.DoVoidWork();
        Sink := Sink + '/suffix';
    end;

    // Discards a TRUE the callee returned, then falls off the end. The answer is
    // true either way here, so this pins that the discarded value is irrelevant
    // rather than coincidentally agreeing.
    [TryFunction]
    procedure TryAfterDiscardingTrueFromAnotherCodeunit()
    var
        Ignored: Boolean;
    begin
        Ignored := Callee.ReturnsTrue();
    end;

    // ── [TryFunction], no exit, body RAISES ─────────────────────────────────────
    // The negative direction: the same no-exit shape answers FALSE when the body
    // errors, which is what makes the true above a statement about completion
    // rather than a constant.

    [TryFunction]
    procedure TryRaisesAfterByRefWrite(var Sink: Text)
    begin
        Callee.DoVoidWork();
        Sink := Sink + '/suffix';
        Error('ALTTryFunctionNoExitProbe deliberate failure');
    end;

    // ── The SAME bodies WITHOUT [TryFunction] ───────────────────────────────────
    // Declared `: Boolean` explicitly, since without the attribute there is no
    // synthesized return type. These are the control: identical bodies, no
    // attribute, and AL's implicit default return governs — so they answer FALSE.

    procedure PlainBoolEmptyBody(): Boolean
    begin
    end;

    procedure PlainBoolAfterCallOutThenByRefWrite(var Sink: Text): Boolean
    begin
        Callee.DoVoidWork();
        Sink := Sink + '/suffix';
    end;
}
