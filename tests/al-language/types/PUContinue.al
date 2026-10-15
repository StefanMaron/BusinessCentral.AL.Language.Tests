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
}
