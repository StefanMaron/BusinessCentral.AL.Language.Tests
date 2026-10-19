codeunit 60187 "Test Case Contracts"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    trigger OnRun()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure Case_Integer_MatchesExactValue()
    var
        I: Integer;
    begin
        I := 2;
        case I of
            1:
                Assert.Fail('must not reach 1');
            2:
                Assert.IsTrue(true, 'case 2 must match when I=2');
            3:
                Assert.Fail('must not reach 3');
        end;
    end;

    [Test]
    procedure Case_Integer_Else_WhenNoMatch()
    var
        I: Integer;
        Result: Text;
    begin
        I := 99;
        Result := '';
        case I of
            1:
                Result := 'one';
            2:
                Result := 'two';
            else
                Result := 'other';
        end;
        Assert.AreEqual('other', Result, 'else branch must execute when no case matches');
    end;

    [Test]
    procedure Case_Integer_NoElse_SkipsIfNoMatch()
    var
        I: Integer;
        Result: Text;
    begin
        I := 99;
        Result := 'unchanged';
        case I of
            1:
                Result := 'one';
            2:
                Result := 'two';
        end;
        Assert.AreEqual('unchanged', Result, 'case with no else and no match must leave Result unchanged');
    end;

    [Test]
    procedure Case_Text_MatchesExactString()
    var
        S: Text;
        Result: Integer;
    begin
        S := 'hello';
        Result := 0;
        case S of
            'hello':
                Result := 1;
            'world':
                Result := 2;
            else
                Result := 0;
        end;
        Assert.AreEqual(1, Result, 'case text must match exact string "hello"');
    end;

    [Test]
    procedure Case_Text_IsCaseSensitive()
    var
        S: Text;
        Result: Integer;
    begin
        S := 'HELLO';
        Result := 0;
        case S of
            'hello':
                Result := 1;
            'HELLO':
                Result := 2;
            else
                Result := 0;
        end;
        Assert.AreEqual(2, Result, 'case text must be case-sensitive (HELLO matches HELLO not hello)');
    end;

    [Test]
    procedure Case_Enum_MatchesValue()
    var
        Status: Enum "ALT Status";
        Result: Text;
    begin
        Status := "ALT Status"::Active;
        Result := '';
        case Status of
            "ALT Status"::Draft:
                Result := 'draft';
            "ALT Status"::Active:
                Result := 'active';
            "ALT Status"::Closed:
                Result := 'closed';
            else
                Result := 'other';
        end;
        Assert.AreEqual('active', Result, 'case enum must match Active value');
    end;

    [Test]
    procedure Case_MultipleValuesInOneBranch()
    var
        I: Integer;
        Result: Text;
    begin
        I := 3;
        Result := '';
        case I of
            1, 2:
                Result := 'low';
            3, 4:
                Result := 'mid';
            5, 6:
                Result := 'high';
            else
                Result := 'other';
        end;
        Assert.AreEqual('mid', Result, 'case with comma-separated values: 3 must match 3,4 branch');
    end;

    [Test]
    procedure Case_MultipleValues_FirstOfGroup()
    var
        I: Integer;
        Result: Text;
    begin
        I := 1;
        Result := '';
        case I of
            1, 2:
                Result := 'one-or-two';
            3, 4:
                Result := 'three-or-four';
        end;
        Assert.AreEqual('one-or-two', Result, 'Both values in a branch must match: 1 matches 1,2');
    end;

    [Test]
    procedure Case_Boolean_TrueAndFalse()
    var
        B: Boolean;
        Result: Text;
    begin
        B := true;
        Result := '';
        case B of
            true:
                Result := 'yes';
            false:
                Result := 'no';
        end;
        Assert.AreEqual('yes', Result, 'case boolean true must match true branch');
    end;

    [Test]
    procedure Case_UnmatchedValue_ExecutesElse()
    var
        I: Integer;
        Result: Integer;
    begin
        I := 5;
        Result := 0;
        case I of
            1:
                Result := 1;
            2:
                Result := 2;
            else
                Result := 99;
        end;
        Assert.AreEqual(99, Result, 'else must execute for unmatched value 5');
    end;

    [Test]
    procedure Case_Code_UppercaseNormalized()
    var
        C: Code[20];
        Result: Text;
    begin
        C := 'hello';
        Result := '';
        case C of
            'HELLO':
                Result := 'matched';
            else
                Result := 'not matched';
        end;
        Assert.AreEqual('matched', Result, 'case on Code must match uppercase (Code normalizes on assign)');
    end;

    [Test]
    procedure Case_NestingWorks()
    var
        I: Integer;
        Result: Text;
    begin
        I := 2;
        Result := '';
        case I of
            1:
                Result := 'one';
            2:
                begin
                    case I * 2 of
                        4:
                            Result := 'two';
                        else
                            Result := 'unexpected';
                    end;
                end;
            else
                Result := 'other';
        end;
        Assert.AreEqual('two', Result, 'Nested case statement must work correctly');
    end;

    [Test]
    procedure Case_WithProcedureCall_InElse()
    var
        I: Integer;
        Result: Text;
    begin
        I := 7;
        Result := '';
        case I of
            1:
                Result := 'one';
            else
                Result := GetDefault(I);
        end;
        Assert.AreEqual('default-7', Result, 'else branch can call procedure');
    end;

    [Test]
    procedure Case_InLoop_SelectsCorrectly()
    var
        i: Integer;
        Sum: Integer;
    begin
        Sum := 0;
        for i := 1 to 3 do
            case i of
                1:
                    Sum += 10;
                2:
                    Sum += 20;
                3:
                    Sum += 30;
            end;
        Assert.AreEqual(60, Sum, 'case inside for loop must select correct branch each iteration (10+20+30=60)');
    end;

    local procedure GetDefault(I: Integer): Text
    begin
        exit('default-' + Format(I));
    end;

    // corpus issue 664 (writer BN): case statements from microsoft/AL issues 709, 834, 4312, 6136, 6912 and Learn (control statements).
    // Observed on BC (probe form: Observer.Finish).
    [Test]
    procedure BN_Case_UnbracedIfInBranches()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('a=1', UnbracedIf(1));
        Observer.Observe('a=2', UnbracedIf(2));
        Observer.Observe('a=3', UnbracedIf(3));
        Observer.Finish();
    end;

    local procedure UnbracedIf(a: Integer): Text
    var
        R: Text;
    begin
        R := 'none';
        case a of
            1:
                if a = a then R := 'x';
            2:
                if a = a then R := 'y';
            3:
                if a <> a then R := 'never' else R := 'z';
        end;
        exit(R);
    end;

    [Test]
    procedure BN_Case_DecimalSelector()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1.5', DecCase(1.5));
        Observer.Observe('1.50', DecCase(1.50));
        Observer.Observe('1.2', DecCase(1.2));
        Observer.Observe('2', DecCase(2));
        Observer.Observe('2.5', DecCase(2.5));
        Observer.Observe('-0.5', DecCase(-0.5));
        Observer.Observe('0.1+0.2', DecCase(0.1 + 0.2));
        Observer.Observe('0.3', DecCase(0.3));
        Observer.Observe('-3', DecCase(-3));
        Observer.Finish();
    end;

    local procedure DecCase(Value: Decimal): Text
    begin
        case Value of
            1.5:
                exit('first 1.5');
            1.50:
                exit('second 1.50');
            1 .. 2:
                exit('range 1..2');
            -0.5:
                exit('minus 0.5');
            0.3:
                exit('0.3');
            -5 .. -1:
                exit('range -5..-1');
            else
                exit('else');
        end;
    end;

    [Test]
    procedure BN_Case_OnlyElse()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        I: Integer;
    begin
        case true of
            else begin
                R := 'else ran';
            end;
        end;
        Observer.Observe('case true only else', R);
        R := '';
        I := 7;
        case I of
            else
                R := 'int else ran';
        end;
        Observer.Observe('case int only else', R);
        Observer.Finish();
    end;

    [Test]
    procedure BN_Case_ZeroLiterals()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        T: Time;
        DT: DateTime;
    begin
        D := 0D;
        Observer.Observe('0D', DateCase(D));
        Observer.Observe('fixed date', DateCase(DMY2Date(15, 3, 2024)));
        Observer.Observe('other date', DateCase(DMY2Date(16, 3, 2024)));
        T := 0T;
        case T of
            0T:
                Observer.Observe('0T', 'zero');
            else
                Observer.Observe('0T', 'other');
        end;
        DT := 0DT;
        case DT of
            0DT:
                Observer.Observe('0DT', 'zero');
            else
                Observer.Observe('0DT', 'other');
        end;
        Observer.Finish();
    end;

    local procedure DateCase(D: Date): Text
    begin
        case D of
            0D:
                exit('zero');
            DMY2Date(15, 3, 2024):
                exit('15 March');
            else
                exit('other');
        end;
    end;

    [Test]
    procedure BN_Case_CodeSelectorAndLabels()
    var
        Observer: Codeunit "Probe Observer";
        MyCode: Code[10];
        Txt: Text;
    begin
        MyCode := 'ABC';
        Observer.Observe('code ABC vs labels abc,ABC', CodeCase(MyCode));
        MyCode := 'abc';
        Observer.Observe('code assigned abc', CodeCase(MyCode));
        Txt := 'abc';
        Observer.Observe('text abc vs labels ABC,abc', TextCase(Txt));
        Txt := 'ABC';
        Observer.Observe('text ABC vs labels ABC,abc', TextCase(Txt));
        MyCode := 'XYZ';
        if TryLongLabel(MyCode, Txt) then
            Observer.Observe('code vs 12-char label', Txt)
        else
            Observer.ObserveError('code vs 12-char label');
        MyCode := 'ABCDEFGHIJ';
        if TryLongLabel(MyCode, Txt) then
            Observer.Observe('code 10 chars vs 12-char label', Txt)
        else
            Observer.ObserveError('code 10 chars vs 12-char label');
        Observer.Finish();
    end;

    local procedure CodeCase(Value: Code[10]): Text
    begin
        case Value of
            'abc':
                exit('lower label');
            'ABC':
                exit('upper label');
            else
                exit('else');
        end;
    end;

    local procedure TextCase(Value: Text): Text
    begin
        case Value of
            'ABC':
                exit('upper label');
            'abc':
                exit('lower label');
            else
                exit('else');
        end;
    end;

    [TryFunction]
    local procedure TryLongLabel(Value: Code[10]; var R: Text)
    begin
        case Value of
            'ABCDEFGHIJKL':
                R := 'long label';
            'XYZ':
                R := 'xyz';
            else
                R := 'else';
        end;
    end;
}
