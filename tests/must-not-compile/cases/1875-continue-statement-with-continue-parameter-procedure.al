// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'X' of 'Continue(Integer)'
// Writer PY-C (al-runtime-rs PR 346, probes-needed "continue; where the procedure named Continue takes parameters"): in a codeunit whose only
// procedure Continue takes a parameter, `continue;` is read as a call of that procedure. Without parameters it is a call too
// (types/PUContinue.al Continue_WithProcedureNamedContinue).
codeunit 51875 "MNC PYC Continue With Param"
{
    var
        Calls: Integer;

    procedure Continue(X: Integer)
    begin
        Calls += X;
    end;

    procedure ForLoop()
    var
        i: Integer;
    begin
        for i := 1 to 3 do begin
            if i = 2 then
                continue;
        end;
    end;
}
