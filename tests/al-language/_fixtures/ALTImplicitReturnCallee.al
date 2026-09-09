// Callee for ALTImplicitReturnProbe (codeunit 60036). Kept in its own codeunit so the
// probe's calls genuinely cross a codeunit boundary.

codeunit 60049 "ALTImplicitReturnCallee"
{
    var
        Calls: Integer;

    /// Void: has observable work so the call cannot be optimised away, but no return value.
    procedure DoVoidWork()
    begin
        Calls += 1;
    end;

    /// Returns TRUE explicitly. Callers in the probe discard this value.
    procedure ReturnsTrue(): Boolean
    begin
        Calls += 1;
        exit(true);
    end;

    /// Writes several byref outputs, then returns nothing.
    procedure WriteSeveralByRefs(var A: Text; var B: Integer; var C: Decimal)
    begin
        Calls += 1;
        A := 'written';
        B := 42;
        C := 3.5;
    end;

    procedure CallCount(): Integer
    begin
        exit(Calls);
    end;
}
