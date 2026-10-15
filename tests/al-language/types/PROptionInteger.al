// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-option-data-type
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// An Option member used as an integer: the member's ORDINAL. `I := Opt::C` gives 2, `I := Opt` 1 for B; `Opt + 1`, `Opt::B + 1`, `Opt * 2` are Integer arithmetic;
// an Option passed to an Integer parameter is its ordinal (int:1), `Opt = 1`, `Opt > 0` and `Opt::B = 1` compare it as a number; case Opt of Opt::C and of 2 both match;
// `for I := 0 to Opt` runs ordinal + 1 times. Integer to Option: `Opt := 2` is C, an Integer variable likewise; an ordinal beyond the members (7, -1) is kept (Format
// shows the number); Evaluate(Opt, '1') and Evaluate(Opt, 'C') both succeed.
// Fixtures used: self-contained codeunit 69540
// BC versions: 27.5

codeunit 69540 "PR Option Integer Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TakeInteger(Value: Integer): Text
    begin
        exit('int:' + Format(Value));
    end;

    local procedure TakeOption(var Value: Option A,B,C): Text
    begin
        exit('opt:' + Format(Value));
    end;

    [Test]
    procedure OptionMember_AsInteger()
    var
        Opt: Option A,B,C;
        I: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        I := Opt::C;
        Observer.Observe('member_literal_into_integer', Format(I));
        Opt := Opt::B;
        I := Opt;
        Observer.Observe('variable_into_integer', Format(I));
        Observer.Observe('variable_plus_one', Format(Opt + 1));
        Observer.Observe('member_plus_one', Format(Opt::B + 1));
        Observer.Observe('variable_times_two', Format(Opt * 2));
        Observer.Observe('as_integer_argument', TakeInteger(Opt));
        Observer.Observe('member_as_integer_argument', TakeInteger(Opt::C));
        Observer.Observe('compare_variable_to_integer', Format(Opt = 1));
        Observer.Observe('compare_greater', Format(Opt > 0));
        Observer.Observe('compare_member_to_integer', Format(Opt::B = 1));
        Observer.Observe('format_default', Format(Opt));
        Observer.Observe('format_integer', Format(Opt, 0, 1));
        Observer.Expect('member_literal_into_integer', '2');
        Observer.Expect('variable_into_integer', '1');
        Observer.Expect('variable_plus_one', '2');
        Observer.Expect('member_plus_one', '2');
        Observer.Expect('variable_times_two', '2');
        Observer.Expect('as_integer_argument', 'int:1');
        Observer.Expect('member_as_integer_argument', 'int:2');
        Observer.Expect('compare_variable_to_integer', 'Yes');
        Observer.Expect('compare_greater', 'Yes');
        Observer.Expect('compare_member_to_integer', 'Yes');
        Observer.Expect('format_default', 'B');
        Observer.Expect('format_integer', 'B');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_AsOptionValue()
    var
        Opt: Option A,B,C;
        I: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Opt := 2;
        Observer.Observe('literal_into_option', Format(Opt));
        I := 1;
        Opt := I;
        Observer.Observe('variable_into_option', Format(Opt));
        I := 7;
        Opt := I;
        Observer.Observe('beyond_members', '[' + Format(Opt) + ']' + Format(Opt, 0, 1));
        I := -1;
        Opt := I;
        Observer.Observe('negative', '[' + Format(Opt) + ']' + Format(Opt, 0, 1));
        I := 1;
        Opt := I;
        Observer.Observe('option_argument', TakeOption(Opt));
        Observer.Expect('literal_into_option', 'C');
        Observer.Expect('variable_into_option', 'B');
        Observer.Expect('beyond_members', '[7]7');
        Observer.Expect('negative', '[-1]-1');
        Observer.Expect('option_argument', 'opt:B');
        Observer.Verify();
    end;

    [Test]
    procedure Option_InCaseAndLoopBounds()
    var
        Opt: Option A,B,C;
        I: Integer;
        Count: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Opt := Opt::C;
        case Opt of
            Opt::A:
                Observer.Observe('case_member', 'A');
            Opt::C:
                Observer.Observe('case_member', 'C');
        end;
        case Opt of
            2:
                Observer.Observe('case_integer', 'two');
            else
                Observer.Observe('case_integer', 'other');
        end;
        for I := 0 to Opt do
            Count += 1;
        Observer.Observe('for_to_option', Format(Count));
        Observer.Observe('evaluate_integer_text', Format(Evaluate(Opt, '1')) + Format(Opt));
        Observer.Observe('evaluate_member_text', Format(Evaluate(Opt, 'C')) + Format(Opt));
        Observer.Expect('case_member', 'C');
        Observer.Expect('case_integer', 'two');
        Observer.Expect('for_to_option', '3');
        Observer.Expect('evaluate_integer_text', 'YesB');
        Observer.Expect('evaluate_member_text', 'YesC');
        Observer.Verify();
    end;
}
