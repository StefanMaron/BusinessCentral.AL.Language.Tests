// Fixture for TestCodeunitVariableDispatch (codeunit 60966).
//
// Carries BOTH kinds of entry point on one object, which is what lets a test tell them apart:
//   - `trigger OnRun()`, the only thing Codeunit.Run reaches, and
//   - ordinary `procedure`s, the only thing a codeunit VARIABLE reaches.
// Each writes to its own counter so a test can say which one executed, rather than only that
// nothing threw.
codeunit 60959 ALTDispatchProbe
{
    var
        ProcCalls: Integer;
        RunCalls: Integer;

    trigger OnRun()
    begin
        RunCalls += 1;
    end;

    /// <summary>Returns a value derived from the argument, so a caller can tell a real
    /// execution from a default-valued return.</summary>
    procedure Triple(X: Integer): Integer
    begin
        ProcCalls += 1;
        exit(3 * X);
    end;

    /// <summary>Instance state written by Triple, readable through the same variable.</summary>
    procedure GetProcCalls(): Integer
    begin
        exit(ProcCalls);
    end;

    procedure GetRunCalls(): Integer
    begin
        exit(RunCalls);
    end;

    /// <summary>A Text-returning procedure, so the default-value question is asked of a
    /// second type: an empty string is Text's default exactly as 0 is Integer's.</summary>
    procedure Echo(S: Text): Text
    begin
        ProcCalls += 1;
        exit('echo:' + S);
    end;
}
