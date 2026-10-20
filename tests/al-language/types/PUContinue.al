// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-control-statements
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier and run on BC 29.0.54011.55816; every literal below is what those tiers produced.
//
// The `continue` statement compiles on AL 16 (BC 27) and later and skips the rest of the loop body in for (to and downto), while, repeat, foreach, a FindSet repeat loop and from inside a
// case branch. In `for` the counter still advances (and keeps the value past the last turn: 6 after 1..6); in `repeat` continue jumps to the `until` condition (so a repeat that
// always continues still ends when the condition holds: 4); in nested loops it affects only the innermost loop; `continue` before `break` works as expected.
// Fixtures used: PU Tf Row (69336) from PUTestFieldErrorInfo.al, codeunit 69338
// BC versions: 27.5, 29.0

codeunit 69338 "PU Continue Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Continue_InForToDownto()
    var
        i: Integer;
        Seen: Text;
        Observer: Codeunit "Probe Observer";
    begin
        for i := 1 to 6 do begin
            if i mod 2 = 0 then
                continue;
            Seen += Format(i);
        end;
        Observer.Observe('for_to_odd_numbers', Seen);
        Observer.Observe('for_to_counter_after', Format(i));
        Seen := '';
        for i := 6 downto 1 do begin
            if i = 3 then
                continue;
            Seen += Format(i);
        end;
        Observer.Observe('for_downto_skip_3', Seen);
        Observer.Expect('for_to_odd_numbers', '135');
        Observer.Expect('for_to_counter_after', '6');
        Observer.Expect('for_downto_skip_3', '65421');
        Observer.Verify();
    end;

    [Test]
    procedure Continue_InWhileAndRepeat()
    var
        i: Integer;
        Seen: Text;
        Observer: Codeunit "Probe Observer";
    begin
        i := 0;
        while i < 6 do begin
            i += 1;
            if i mod 2 = 1 then
                continue;
            Seen += Format(i);
        end;
        Observer.Observe('while_even_numbers', Seen);
        Seen := '';
        i := 0;
        repeat
            i += 1;
            if i = 2 then
                continue;
            Seen += Format(i);
        until i >= 4;
        Observer.Observe('repeat_skip_2', Seen);
        Seen := '';
        i := 0;
        repeat
            i += 1;
            if i < 10 then
                continue;
            Seen += Format(i);
        until i >= 4;
        Observer.Observe('repeat_continue_skips_until_check', Seen + '/' + Format(i));
        Observer.Expect('while_even_numbers', '246');
        Observer.Expect('repeat_skip_2', '134');
        Observer.Expect('repeat_continue_skips_until_check', '/4');
        Observer.Verify();
    end;

    [Test]
    procedure Continue_InForeach_AndNestedLoops()
    var
        List: List of [Integer];
        N: Integer;
        i: Integer;
        j: Integer;
        Seen: Text;
        Observer: Codeunit "Probe Observer";
    begin
        List.Add(1);
        List.Add(2);
        List.Add(3);
        List.Add(4);
        foreach N in List do begin
            if N = 2 then
                continue;
            Seen += Format(N);
        end;
        Observer.Observe('foreach_skip_2', Seen);
        Seen := '';
        for i := 1 to 3 do
            for j := 1 to 3 do begin
                if j = 2 then
                    continue;
                Seen += Format(i) + Format(j) + ' ';
            end;
        Observer.Observe('nested_inner_continue_only', Seen);
        Seen := '';
        for i := 1 to 5 do begin
            if i = 2 then
                continue;
            if i = 4 then
                break;
            Seen += Format(i);
        end;
        Observer.Observe('continue_then_break', Seen + '/' + Format(i));
        Observer.Expect('foreach_skip_2', '134');
        Observer.Expect('nested_inner_continue_only', '11 13 21 23 31 33 ');
        Observer.Expect('continue_then_break', '13/4');
        Observer.Verify();
    end;

    [Test]
    procedure Continue_InRecordLoop_AndWithCase()
    var
        Row: Record "PU Tf Row";
        Seen: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Row.Id := 3;
        Row.Insert();
        if Row.FindSet() then
            repeat
                if Row.Id = 2 then
                    continue;
                Seen += Format(Row.Id);
            until Row.Next() = 0;
        Observer.Observe('findset_repeat_skip_2', Seen);
        Seen := '';
        if Row.FindSet() then
            repeat
                case Row.Id of
                    1:
                        continue;
                    else
                        Seen += Format(Row.Id);
                end;
            until Row.Next() = 0;
        Observer.Observe('continue_inside_case', Seen);
        Observer.Expect('findset_repeat_skip_2', '13');
        Observer.Expect('continue_inside_case', '23');
        Observer.Verify();
    end;

    // corpus issue 664 (writer BN): `continue;` in a codeunit that also declares a procedure named Continue (microsoft/AL issue 7930,
    // Learn: control statements). The loop lives in codeunit 82150 below, so the other tests of this codeunit keep the plain statement.
    // A local variable named Continue makes `continue;` an illegal statement: tests/must-not-compile/cases/1393.
    [Test]
    procedure Continue_WithProcedureNamedContinue()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT BN Continue Proc";
    begin
        Observer.Observe('for_loop', Helper.ForLoop());
        Observer.Observe('while_loop', Helper.WhileLoop());
        Observer.Observe('explicit_call', Helper.ExplicitCall());
        Observer.Expect('for_loop', '123|calls=1');
        Observer.Expect('while_loop', '123|calls=1');
        Observer.Expect('explicit_call', '123|calls=1');
        Observer.Verify();
    end;

    // corpus issue 664 (writer BN): `if ... then continue else ...` in a foreach nested in a for that also continues (microsoft/AL issue 8339).
    [Test]
    procedure Continue_ForeachInFor_IfContinueElse()
    var
        Observer: Codeunit "Probe Observer";
        List: List of [Text];
        Item: Text;
        FieldNo: Integer;
        Seen: Text;
    begin
        List.Add('A');
        List.Add('B');
        List.Add('C');
        for FieldNo := 1 to 5 do begin
            if FieldNo = 3 then
                continue;
            foreach Item in List do
                if Item = 'A' then
                    continue
                else
                    Seen += Format(FieldNo) + Item + ' ';
        end;
        Observer.Observe('seen', Seen);
        Observer.Observe('for_after', Format(FieldNo));
        Seen := '';
        foreach Item in List do begin
            if Item = 'B' then
                continue
            else
                Seen += Item;
            Seen += '.';
        end;
        Observer.Observe('foreach_continue_else_block', Seen);
        Observer.Expect('seen', '');
        Observer.Expect('for_after', '5');
        Observer.Expect('foreach_continue_else_block', 'A.C.');
        Observer.Verify();
    end;

    // Writer PY-C (al-runtime-rs PR 346, "continue; where the procedure named Continue ..."): `continue;` in a codeunit whose procedure Continue
    // takes a parameter, returns a value, is a TryFunction, or is overloaded (helpers 85211-85214 below).
    [Test]
    procedure PYC_Continue_ProcedureShapes()
    var
        Observer: Codeunit "Probe Observer";
        P: Codeunit "LT PYC Continue Param";
        R: Codeunit "LT PYC Continue Ret";
        T: Codeunit "LT PYC Continue Try";
        O: Codeunit "LT PYC Continue Over";
    begin
        Observer.Observe('with parameter', P.ForLoop());
        Observer.Observe('with return value', R.ForLoop());
        Observer.Observe('try function', T.ForLoop());
        Observer.Observe('overloaded', O.ForLoop());
        Observer.Finish();
    end;

    // Writer PY-C (al-runtime-rs PR 346, probes-needed "Loops, continue and MaxStrLen"): `if ... then continue else ...` with the foreach
    // directly in for, while and repeat, with a begin..end around the if, foreach in foreach, and as the direct body of a foreach that is not nested.
    local procedure Abc(var List: List of [Text])
    begin
        Clear(List);
        List.Add('A');
        List.Add('B');
        List.Add('C');
    end;

    [Test]
    procedure PYC_ContinueElse_ForeachInLoops()
    var
        Observer: Codeunit "Probe Observer";
        List: List of [Text];
        Item: Text;
        i: Integer;
        Seen: Text;
    begin
        Abc(List);
        for i := 1 to 2 do
            foreach Item in List do
                if Item = 'A' then
                    continue
                else
                    Seen += Format(i) + Item + ' ';
        Observer.Observe('for no continue', Seen + '|' + Format(i));
        Seen := '';
        i := 0;
        while i < 2 do begin
            i += 1;
            foreach Item in List do
                if Item = 'A' then
                    continue
                else
                    Seen += Format(i) + Item + ' ';
        end;
        Observer.Observe('while', Seen + '|' + Format(i));
        Seen := '';
        i := 0;
        repeat
            i += 1;
            foreach Item in List do
                if Item = 'A' then
                    continue
                else
                    Seen += Format(i) + Item + ' ';
        until i >= 2;
        Observer.Observe('repeat', Seen + '|' + Format(i));
        Seen := '';
        for i := 1 to 2 do
            foreach Item in List do begin
                if Item = 'A' then
                    continue
                else
                    Seen += Format(i) + Item + ' ';
            end;
        Observer.Observe('for begin end', Seen + '|' + Format(i));
        Seen := '';
        foreach Item in List do
            if Item = 'B' then
                continue
            else
                Seen += Item;
        Observer.Observe('foreach direct body', Seen);
        Observer.Finish();
    end;

    [Test]
    procedure PYC_ContinueElse_ForeachInForeach()
    var
        Observer: Codeunit "Probe Observer";
        Outer: List of [Text];
        List: List of [Text];
        O: Text;
        Item: Text;
        Seen: Text;
        i: Integer;
    begin
        Abc(List);
        Outer.Add('x');
        Outer.Add('y');
        foreach O in Outer do
            foreach Item in List do
                if Item = 'A' then
                    continue
                else
                    Seen += O + Item + ' ';
        Observer.Observe('foreach in foreach', Seen);
        Seen := '';
        for i := 1 to 2 do
            foreach Item in List do
                if Item <> 'A' then
                    Seen += Format(i) + Item + ' '
                else
                    continue;
        Observer.Observe('else continue', Seen + '|' + Format(i));
        Seen := '';
        for i := 1 to 2 do
            foreach Item in List do
                if Item = 'A' then begin
                    continue;
                end else
                    Seen += Format(i) + Item + ' ';
        Observer.Observe('then begin continue end else', Seen + '|' + Format(i));
        Seen := '';
        for i := 1 to 2 do
            foreach Item in List do begin
                if Item = 'A' then
                    continue;
                Seen += Format(i) + Item + ' ';
            end;
        Observer.Observe('continue without else', Seen + '|' + Format(i));
        Observer.Finish();
    end;
}

// corpus issue 664 (writer BN): helper for Continue_WithProcedureNamedContinue. Not a test codeunit.
codeunit 82150 "LT BN Continue Proc"
{
    var
        Calls: Integer;

    procedure Continue()
    begin
        Calls += 1;
    end;

    procedure ForLoop(): Text
    var
        i: Integer;
        S: Text;
    begin
        Calls := 0;
        for i := 1 to 3 do begin
            if i = 2 then
                continue;
            S += Format(i);
        end;
        exit(S + '|calls=' + Format(Calls));
    end;

    procedure WhileLoop(): Text
    var
        i: Integer;
        S: Text;
    begin
        Calls := 0;
        while i < 3 do begin
            i += 1;
            if i = 2 then
                continue;
            S += Format(i);
        end;
        exit(S + '|calls=' + Format(Calls));
    end;

    procedure ExplicitCall(): Text
    var
        i: Integer;
        S: Text;
    begin
        Calls := 0;
        for i := 1 to 3 do begin
            if i = 2 then
                Continue();
            S += Format(i);
        end;
        exit(S + '|calls=' + Format(Calls));
    end;
}

// Writer PY-C (al-runtime-rs PR 346): helpers for PYC_Continue_ProcedureShapes. Not test codeunits.
codeunit 85211 "LT PYC Continue Param"
{
    var
        Calls: Integer;

    procedure Continue(X: Integer)
    begin
        Calls += X;
    end;

    procedure ForLoop(): Text
    var
        i: Integer;
        S: Text;
    begin
        Calls := 0;
        for i := 1 to 3 do begin
            if i = 2 then
                continue;
            S += Format(i);
        end;
        exit(S + '|calls=' + Format(Calls));
    end;
}

codeunit 85212 "LT PYC Continue Ret"
{
    var
        Calls: Integer;

    procedure Continue(): Integer
    begin
        Calls += 1;
        exit(7);
    end;

    procedure ForLoop(): Text
    var
        i: Integer;
        S: Text;
    begin
        Calls := 0;
        for i := 1 to 3 do begin
            if i = 2 then
                continue;
            S += Format(i);
        end;
        exit(S + '|calls=' + Format(Calls));
    end;
}

codeunit 85213 "LT PYC Continue Try"
{
    var
        Calls: Integer;

    [TryFunction]
    procedure Continue()
    begin
        Calls += 1;
    end;

    procedure ForLoop(): Text
    var
        i: Integer;
        S: Text;
    begin
        Calls := 0;
        for i := 1 to 3 do begin
            if i = 2 then
                continue;
            S += Format(i);
        end;
        exit(S + '|calls=' + Format(Calls));
    end;
}

codeunit 85214 "LT PYC Continue Over"
{
    var
        Calls: Integer;

    procedure Continue()
    begin
        Calls += 1;
    end;

    procedure Continue(X: Integer)
    begin
        Calls += 10 * X;
    end;

    procedure ForLoop(): Text
    var
        i: Integer;
        S: Text;
    begin
        Calls := 0;
        for i := 1 to 3 do begin
            if i = 2 then
                continue;
            S += Format(i);
        end;
        exit(S + '|calls=' + Format(Calls));
    end;
}
