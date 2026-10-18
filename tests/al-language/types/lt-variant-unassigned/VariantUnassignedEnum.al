// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enum 67509, codeunit 67511
// Probe: a Variant cannot be compared with = or <> (must-not-compile case 0502), but it can be the subject of a case statement. Which case branches an unassigned Variant matches: an enum member (ordinal 0 and 1), the integers 0 and 1, an empty text, false and the zero date; the same for a Variant that holds an enum member (issue 580 item 6).
// BC versions: 27+

enum 67509 "LT VUE Kind"
{
    Extensible = true;

    value(0; Zero) { }
    value(1; One) { }
    value(2; Two) { }
}

codeunit 67511 "LT VUE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure MatchZeroMember(V: Variant): Text
    begin
        case V of
            "LT VUE Kind"::Zero:
                exit('match');
        end;
        exit('no match');
    end;

    local procedure MatchOneMember(V: Variant): Text
    begin
        case V of
            "LT VUE Kind"::One:
                exit('match');
        end;
        exit('no match');
    end;

    local procedure MatchInteger0(V: Variant): Text
    begin
        case V of
            0:
                exit('match');
        end;
        exit('no match');
    end;

    local procedure MatchInteger1(V: Variant): Text
    begin
        case V of
            1:
                exit('match');
        end;
        exit('no match');
    end;

    local procedure MatchEmptyText(V: Variant): Text
    begin
        case V of
            '':
                exit('match');
        end;
        exit('no match');
    end;

    local procedure MatchFalse(V: Variant): Text
    begin
        case V of
            false:
                exit('match');
        end;
        exit('no match');
    end;

    local procedure MatchZeroDate(V: Variant): Text
    begin
        case V of
            0D:
                exit('match');
        end;
        exit('no match');
    end;

    local procedure MatchDecimalZero(V: Variant): Text
    begin
        case V of
            0.0:
                exit('match');
        end;
        exit('no match');
    end;

    local procedure MatchAll(var Observer: Codeunit "Probe Observer"; V: Variant)
    begin
        Observer.Observe('enum_zero', MatchZeroMember(V));
        Observer.Observe('enum_one', MatchOneMember(V));
        Observer.Observe('integer_0', MatchInteger0(V));
        Observer.Observe('integer_1', MatchInteger1(V));
        Observer.Observe('empty_text', MatchEmptyText(V));
        Observer.Observe('false', MatchFalse(V));
        Observer.Observe('zero_date', MatchZeroDate(V));
        Observer.Observe('decimal_zero', MatchDecimalZero(V));
    end;

    [Test]
    procedure Unassigned_Variant_Kind_Flags()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        Observer.Observe('is_integer', Format(V.IsInteger()));
        Observer.Observe('is_option', Format(V.IsOption()));
        Observer.Observe('is_text', Format(V.IsText()));
        Observer.Observe('is_boolean', Format(V.IsBoolean()));
        Observer.Observe('is_decimal', Format(V.IsDecimal()));
        Observer.Observe('is_code', Format(V.IsCode()));
        Observer.Observe('is_record', Format(V.IsRecord()));
        Observer.Observe('format', '[' + Format(V) + ']');
        Observer.Finish();
    end;

    [Test]
    procedure Unassigned_Variant_CaseMatches()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        MatchAll(Observer, V);
        Observer.Finish();
    end;

    [Test]
    procedure Unassigned_Variant_CaseMatches_InsideProcedure()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Result: Text;
    begin
        case V of
            "LT VUE Kind"::Zero:
                Result := 'enum zero';
            "LT VUE Kind"::One:
                Result := 'enum one';
            else
                Result := 'else';
        end;
        Observer.Observe('own_variable', Result);
        Observer.Finish();
    end;

    [Test]
    procedure EnumZero_Variant_CaseMatches()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Kind: Enum "LT VUE Kind";
    begin
        Kind := Kind::Zero;
        V := Kind;
        Observer.Observe('is_option', Format(V.IsOption()));
        MatchAll(Observer, V);
        Observer.Finish();
    end;

    [Test]
    procedure EnumOne_Variant_CaseMatches()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Kind: Enum "LT VUE Kind";
    begin
        Kind := Kind::One;
        V := Kind;
        MatchAll(Observer, V);
        Observer.Finish();
    end;

    [Test]
    procedure IntegerZero_Variant_CaseMatches()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Zero: Integer;
    begin
        V := Zero;
        MatchAll(Observer, V);
        Observer.Finish();
    end;

    [Test]
    procedure ClearedVariant_CaseMatches()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        V := 5;
        Clear(V);
        MatchAll(Observer, V);
        Observer.Finish();
    end;
}
