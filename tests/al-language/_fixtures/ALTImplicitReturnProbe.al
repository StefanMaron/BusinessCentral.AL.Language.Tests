// Fixture for TestCodeunitImplicitDefaultReturn (codeunit 60048).
//
// Every method here is declared to return a value and has NO `exit` anywhere in its
// body, so AL's implicit default return governs the result: false / 0 / ''.
// The variants differ only in what the body does BEFORE falling off the end, which
// is what distinguishes a purely local body from one that has awaited a call into
// another codeunit.

codeunit 60036 "ALTImplicitReturnProbe"
{
    var
        Callee: Codeunit "ALTImplicitReturnCallee";
        SideEffect: Integer;

    /// Empty body. Nothing runs before the implicit return.
    procedure BoolEmptyBody(): Boolean
    begin
    end;

    /// Local work only, no call out of this codeunit.
    procedure BoolLocalWorkOnly(): Boolean
    var
        Tmp: Integer;
    begin
        Tmp := 1 + 1;
        SideEffect := Tmp;
    end;

    /// Calls a VOID method on another codeunit, then falls off the end.
    /// This is the shape of BC's own Codeunit 2000 "Time Series Management"
    /// .GetMLForecastCredentials, which calls Codeunit 2004 and then returns nothing.
    procedure BoolAfterCallingVoidOnAnotherCodeunit(): Boolean
    begin
        Callee.DoVoidWork();
    end;

    /// Calls a VOID method on another codeunit and then writes a byref parameter,
    /// exactly as GetMLForecastCredentials appends its URL suffix after the call.
    procedure BoolAfterCallOutThenByRefWrite(var Sink: Text): Boolean
    begin
        Callee.DoVoidWork();
        Sink := Sink + '/suffix';
    end;

    /// Calls a Boolean-returning method on another codeunit and DISCARDS the result.
    /// The discarded value is TRUE, so if it leaks into this method's return slot the
    /// caller sees true where AL requires false.
    procedure BoolAfterDiscardingTrueFromAnotherCodeunit(): Boolean
    begin
        Callee.ReturnsTrue();
    end;

    /// Same, with several byref outputs written by the callee first — the arity of the
    /// enclosing method's scope frame is what differs from the simple cases above.
    procedure BoolAfterCalleeWritesSeveralByRefs(var A: Text; var B: Integer; var C: Decimal): Boolean
    begin
        Callee.WriteSeveralByRefs(A, B, C);
        A := A + '/suffix';
    end;

    /// Non-Boolean returns of the same shape, to pin that the rule is about the
    /// declared return type's default and not about Boolean specifically.
    procedure IntegerAfterCallOut(): Integer
    begin
        Callee.DoVoidWork();
    end;

    procedure TextAfterCallOut(): Text
    begin
        Callee.DoVoidWork();
    end;

    procedure ReadSideEffect(): Integer
    begin
        exit(SideEffect);
    end;
}
