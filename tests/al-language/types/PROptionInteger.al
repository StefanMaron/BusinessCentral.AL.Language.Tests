// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-option-data-type
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// An Option member used as an integer: the member's ORDINAL. `I := Opt::C` gives 2, `I := Opt` 1 for B; `Opt + 1`, `Opt::B + 1`, `Opt * 2` are Integer arithmetic;
// an Option passed to an Integer parameter is its ordinal (int:1), `Opt = 1`, `Opt > 0` and `Opt::B = 1` compare it as a number; case Opt of Opt::C and of 2 both match;
// `for I := 0 to Opt` runs ordinal + 1 times. Integer to Option: `Opt := 2` is C, an Integer variable likewise; an ordinal beyond the members (7, -1) is kept (Format
// shows the number); Evaluate(Opt, '1') and Evaluate(Opt, 'C') both succeed.
// Fixtures used: Probe Observer (69160); self-contained codeunit 69540; writer QS: table 87355 (tests QS_*: Option compared with Decimal)
// BC versions: 27.5

// Writer QS: an Option field and a Decimal field for the Option-versus-Decimal comparisons (tests QS_*).
table 87355 "LT QS Opt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option) { OptionMembers = None,Quantity,Amount; }
        field(3; Qty; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

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

    // Corpus issue 672 (odd AL behavior leads, part G), item 42: unary minus on an Option does not compile (AL0172, see
    // tests/must-not-compile/cases/1531 to 1533); the forms that do compile: -1 * Option, 0 - Option and the literal -1.
    [Test]
    procedure LT_BU_Option_NegatedByMultiplication()
    var
        Opt: Option A,B,C;
        Opt2: Option A,B,C;
        I: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Opt := Opt::B;
        Opt2 := -1 * Opt;
        Observer.Observe('minus one times option', '[' + Format(Opt2) + ']' + Format(Opt2, 0, 1));
        I := -1 * Opt;
        Observer.Observe('minus one times option into integer', Format(I));
        Opt2 := 0 - Opt;
        Observer.Observe('zero minus option', '[' + Format(Opt2) + ']' + Format(Opt2, 0, 1));
        Opt2 := -1;
        Observer.Observe('literal minus one', '[' + Format(Opt2) + ']' + Format(Opt2, 0, 1));
        Observer.Observe('negative option = -1', Format(Opt2 = -1));
        Observer.Observe('negative option < A', Format(Opt2 < Opt2::A));
        Observer.Expect('minus one times option', '[-1]-1');
        Observer.Expect('minus one times option into integer', '-1');
        Observer.Expect('zero minus option', '[-1]-1');
        Observer.Expect('literal minus one', '[-1]-1');
        Observer.Expect('negative option = -1', 'Yes');
        Observer.Expect('negative option < A', 'Yes');
        Observer.Verify();
    end;

    local procedure QsCompare(O: Option None,Quantity,Amount; D: Decimal): Text
    begin
        exit(StrSubstNo('=%1 <>%2 <%3 >%4 <=%5 >=%6 rev=%7 rev<%8', O = D, O <> D, O < D, O > D, O <= D, O >= D, D = O, D < O));
    end;

    [Test]
    procedure QS_OptionVariable_VersusDecimal()
    var
        Observer: Codeunit "Probe Observer";
        O: Option None,Quantity,Amount;
    begin
        O := O::Quantity;
        Observer.Observe('Quantity vs 0', QsCompare(O, 0));
        Observer.Observe('Quantity vs 1', QsCompare(O, 1));
        Observer.Observe('Quantity vs 1.0', QsCompare(O, 1.0));
        Observer.Observe('Quantity vs 0.5', QsCompare(O, 0.5));
        Observer.Observe('Quantity vs 1.5', QsCompare(O, 1.5));
        Observer.Observe('Quantity vs 0.99999', QsCompare(O, 0.99999));
        Observer.Observe('Quantity vs 2', QsCompare(O, 2));
        Observer.Observe('Quantity vs -1', QsCompare(O, -1));
        O := O::None;
        Observer.Observe('None vs 0', QsCompare(O, 0));
        Observer.Observe('None vs -0.5', QsCompare(O, -0.5));
        O := O::Amount;
        Observer.Observe('Amount vs 2.0', QsCompare(O, 2.0));
        Observer.Observe('Amount vs 1.99', QsCompare(O, 1.99));
        Observer.Expect('Quantity vs 0', '=No <>Yes <No >Yes <=No >=Yes rev=No rev<Yes');
        Observer.Expect('Quantity vs 1', '=Yes <>No <No >No <=Yes >=Yes rev=Yes rev<No');
        Observer.Expect('Quantity vs 1.0', '=Yes <>No <No >No <=Yes >=Yes rev=Yes rev<No');
        Observer.Expect('Quantity vs 0.5', '=No <>Yes <No >Yes <=No >=Yes rev=No rev<Yes');
        Observer.Expect('Quantity vs 1.5', '=No <>Yes <Yes >No <=Yes >=No rev=No rev<No');
        Observer.Expect('Quantity vs 0.99999', '=No <>Yes <No >Yes <=No >=Yes rev=No rev<Yes');
        Observer.Expect('Quantity vs 2', '=No <>Yes <Yes >No <=Yes >=No rev=No rev<No');
        Observer.Expect('Quantity vs -1', '=No <>Yes <No >Yes <=No >=Yes rev=No rev<Yes');
        Observer.Expect('None vs 0', '=Yes <>No <No >No <=Yes >=Yes rev=Yes rev<No');
        Observer.Expect('None vs -0.5', '=No <>Yes <No >Yes <=No >=Yes rev=No rev<Yes');
        Observer.Expect('Amount vs 2.0', '=Yes <>No <No >No <=Yes >=Yes rev=Yes rev<No');
        Observer.Expect('Amount vs 1.99', '=No <>Yes <No >Yes <=No >=Yes rev=No rev<Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QS_OptionMember_VersusDecimalConstant()
    var
        Observer: Codeunit "Probe Observer";
        O: Option None,Quantity,Amount;
        D: Decimal;
    begin
        Observer.Observe('Quantity = 1.0', Format(O::Quantity = 1.0));
        Observer.Observe('Quantity = 1.5', Format(O::Quantity = 1.5));
        Observer.Observe('Quantity <> 1.0', Format(O::Quantity <> 1.0));
        Observer.Observe('Quantity > 0.5', Format(O::Quantity > 0.5));
        Observer.Observe('Quantity < 1.5', Format(O::Quantity < 1.5));
        Observer.Observe('Amount >= 2.0', Format(O::Amount >= 2.0));
        Observer.Observe('None <= -0.1', Format(O::None <= -0.1));
        D := 1;
        Observer.Observe('Quantity = D 1', Format(O::Quantity = D));
        Observer.Observe('D 1 = Quantity', Format(D = O::Quantity));
        D := 1.25;
        Observer.Observe('Quantity < D 1.25', Format(O::Quantity < D));
        Observer.Observe('D 1.25 > Amount', Format(D > O::Amount));
        Observer.Expect('Quantity = 1.0', 'Yes');
        Observer.Expect('Quantity = 1.5', 'No');
        Observer.Expect('Quantity <> 1.0', 'No');
        Observer.Expect('Quantity > 0.5', 'Yes');
        Observer.Expect('Quantity < 1.5', 'Yes');
        Observer.Expect('Amount >= 2.0', 'Yes');
        Observer.Expect('None <= -0.1', 'No');
        Observer.Expect('Quantity = D 1', 'Yes');
        Observer.Expect('D 1 = Quantity', 'Yes');
        Observer.Expect('Quantity < D 1.25', 'Yes');
        Observer.Expect('D 1.25 > Amount', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QS_OptionField_VersusDecimalField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QS Opt Row";
    begin
        Row.Kind := Row.Kind::Quantity;
        Row.Qty := 1;
        Observer.Observe('Kind Quantity vs Qty 1', StrSubstNo('=%1 <>%2 <%3 >%4', Row.Kind = Row.Qty, Row.Kind <> Row.Qty, Row.Kind < Row.Qty, Row.Kind > Row.Qty));
        Row.Qty := 0;
        Observer.Observe('Kind Quantity vs Qty 0', StrSubstNo('=%1 <>%2 <%3 >%4', Row.Kind = Row.Qty, Row.Kind <> Row.Qty, Row.Kind < Row.Qty, Row.Kind > Row.Qty));
        Row.Qty := 2;
        Observer.Observe('member Quantity vs Qty 2', StrSubstNo('=%1 <>%2 <%3 >%4', Row.Kind::Quantity = Row.Qty, Row.Kind::Quantity <> Row.Qty, Row.Kind::Quantity < Row.Qty, Row.Kind::Quantity > Row.Qty));
        Row.Qty := 1.5;
        Observer.Observe('Qty 1.5 vs Kind Quantity', StrSubstNo('=%1 <>%2 <%3 >%4', Row.Qty = Row.Kind, Row.Qty <> Row.Kind, Row.Qty < Row.Kind, Row.Qty > Row.Kind));
        Observer.Expect('Kind Quantity vs Qty 1', '=Yes <>No <No >No');
        Observer.Expect('Kind Quantity vs Qty 0', '=No <>Yes <No >Yes');
        Observer.Expect('member Quantity vs Qty 2', '=No <>Yes <Yes >No');
        Observer.Expect('Qty 1.5 vs Kind Quantity', '=No <>Yes <No >Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Case_DecimalSelector_OptionLabel()
    var
        Observer: Codeunit "Probe Observer";
        O: Option None,Quantity,Amount;
        D: Decimal;
        Values: List of [Decimal];
        Hit: Text;
    begin
        Values.Add(0);
        Values.Add(1);
        Values.Add(1.0);
        Values.Add(1.5);
        Values.Add(2);
        foreach D in Values do begin
            case D of
                O::None:
                    Hit := 'None';
                O::Quantity:
                    Hit := 'Quantity';
                O::Amount:
                    Hit := 'Amount';
                else
                    Hit := 'else';
            end;
            Observer.Observe('case ' + Format(D), Hit);
        end;
        Observer.Expect('case 0', 'None');
        Observer.Expect('case 1', 'Quantity');
        Observer.Expect('case 1', 'Quantity');
        Observer.Expect('case 1.5', 'else');
        Observer.Expect('case 2', 'Amount');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Case_OptionSelector_DecimalVariableLabel()
    var
        Observer: Codeunit "Probe Observer";
        O: Option None,Quantity,Amount;
        D: Decimal;
        Hit: Text;
    begin
        O := O::Quantity;
        D := 1;
        case O of
            D:
                Hit := 'D';
            else
                Hit := 'else';
        end;
        Observer.Observe('Quantity vs label D 1', Hit);
        // D := 1.5 here stops the test on the Linux BC container with 'Overflow under conversion of
        // Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.' (27.5, 28.5, 29.0): queued for the Windows check, not asserted.
        Observer.Finish();
    end;
}
