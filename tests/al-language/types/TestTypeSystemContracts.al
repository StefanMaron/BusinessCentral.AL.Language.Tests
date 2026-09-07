codeunit 60153 "Test Type System Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        Cleanup.Initialize();
    end;

    var
        Cleanup: Codeunit ALTFixtureCleanup;
        Assert: Codeunit Assert;
        ProbeCalls: Integer;

    [Test]
    procedure Integer_MaxValue_PlusOne_Throws()
    var
        I: Integer;
    begin
        I := 2147483647;
        asserterror I := I + 1;
        Assert.AreNotEqual('', GetLastErrorText(), 'Integer overflow must throw a runtime error');
    end;

    [Test]
    procedure Integer_MinValue_MinusOne_Throws()
    var
        I: Integer;
    begin
        I := -2147483647 - 1; // = -2147483648 (MinInt) via arithmetic
        asserterror I := I - 1;
        Assert.AreNotEqual('', GetLastErrorText(), 'Integer underflow must throw a runtime error');
    end;

    [Test]
    procedure Decimal_DivisionByZero_Throws()
    var
        D: Decimal;
        Zero: Decimal;
    begin
        Zero := 0;
        asserterror D := 10 / Zero;
        Assert.AreNotEqual('', GetLastErrorText(), 'Division by zero must throw a runtime error');
    end;

    [Test]
    procedure Integer_DivisionByZero_Throws()
    var
        I: Integer;
        ZeroI: Integer;
    begin
        ZeroI := 0;
        asserterror I := 10 div ZeroI;
        Assert.AreNotEqual('', GetLastErrorText(), 'Integer div 0 must throw a runtime error');
    end;

    [Test]
    procedure CodeField_Assignment_UppercasesValue()
    var
        Rec: Record "ALT Universal";
    begin
        Cleanup.Initialize();
        Rec."Entry No." := 1;
        Rec."Code Field" := 'lowercase';
        Rec.Insert();
        Rec.Get(1);
        Assert.AreEqual('LOWERCASE', Rec."Code Field", 'Assigning lowercase to Code field must store uppercase');
    end;

    [Test]
    procedure CodeField_SetRange_CaseInsensitive()
    var
        Rec: Record "ALT Universal";
    begin
        Cleanup.Initialize();
        Rec."Entry No." := 1;
        Rec."Code Field" := 'ABC';
        Rec.Insert();
        Rec.Reset();
        Rec.SetRange("Code Field", 'abc');
        Assert.AreEqual(1, Rec.Count(), 'SetRange on Code field must be case-insensitive (abc finds ABC)');
    end;

    [Test]
    procedure CodeField_DirectComparison_CaseInsensitive()
    var
        Rec: Record "ALT Universal";
        CodeVar: Code[20];
    begin
        Cleanup.Initialize();
        Rec."Entry No." := 1;
        Rec."Code Field" := 'HELLO';
        Rec.Insert();
        Rec.Get(1);
        CodeVar := 'hello'; // Code[20] assignment uppercases the literal to 'HELLO'
        Assert.IsTrue(Rec."Code Field" = CodeVar, 'Code field comparison must be case-insensitive (HELLO = hello stored as HELLO)');
    end;

    [Test]
    procedure TextField_DirectComparison_CaseSensitive()
    var
        Rec: Record "ALT Universal";
    begin
        Cleanup.Initialize();
        Rec."Entry No." := 1;
        Rec."Text Field" := 'Hello';
        Rec.Insert();
        Rec.Get(1);
        Assert.IsFalse(Rec."Text Field" = 'hello', 'Text field comparison IS case-sensitive (Hello <> hello)');
    end;

    [Test]
    procedure CalcDate_LeapYear_Feb28_PlusOneDay()
    var
        D: Date;
    begin
        D := CalcDate('<+1D>', 20240228D);
        Assert.AreEqual(20240229D, D, 'CalcDate +1D from Feb 28 in leap year must give Feb 29');
    end;

    [Test]
    procedure CalcDate_LeapYear_Feb29_PlusOneDay()
    var
        D: Date;
    begin
        D := CalcDate('<+1D>', 20240229D);
        Assert.AreEqual(20240301D, D, 'CalcDate +1D from Feb 29 must give Mar 1');
    end;

    [Test]
    procedure CalcDate_NonLeapYear_Feb28_PlusOneDay()
    var
        D: Date;
    begin
        D := CalcDate('<+1D>', 20230228D);
        Assert.AreEqual(20230301D, D, 'CalcDate +1D from Feb 28 in non-leap year must give Mar 1');
    end;

    [Test]
    procedure Boolean_TruthTable_ORAndAND()
    // Renamed from Boolean_ShortCircuit_ORAndAND. It only ever asserted the truth table of
    // OR and AND over literals -- nothing here observes whether an operand was evaluated,
    // so the old name claimed more than the body proved. The evaluation claim is now made,
    // and measured, by the four tests below.
    begin
        Assert.IsTrue(true or false, 'true OR false must be true');
        Assert.IsTrue(true or true, 'true OR true must be true');
        Assert.IsFalse(false or false, 'false OR false must be false');
        Assert.IsFalse(false and true, 'false AND true must be false');
    end;

    [Test]
    procedure Guid_DirectComparison_IsReliable()
    var
        G1: Guid;
        G2: Guid;
        G3: Guid;
    begin
        G1 := CreateGuid();
        G2 := G1;
        Assert.IsTrue(G1 = G2, 'Guid direct comparison G1 = G2 must return true for same GUID');
        G3 := CreateGuid();
        Assert.IsFalse(G1 = G3, 'Different GUIDs must not be equal via direct comparison');
    end;

    [Test]
    procedure Variant_IsInteger_AfterIntegerAssign_NotDecimal()
    var
        V: Variant;
        I: Integer;
        D: Decimal;
    begin
        I := 5;
        V := I;
        Assert.IsTrue(V.IsInteger(), 'After assigning Integer to Variant, IsInteger must be true');
        Assert.IsFalse(V.IsDecimal(), 'After assigning Integer to Variant, IsDecimal must be false');
        D := 5.0;
        V := D;
        Assert.IsTrue(V.IsDecimal(), 'After assigning Decimal to Variant, IsDecimal must be true');
        Assert.IsFalse(V.IsInteger(), 'After assigning Decimal to Variant, IsInteger must be false');
    end;

    [Test]
    procedure Boolean_AND_FalseLeftOperand_RightOperandIsStillEvaluated()
    // CLAIM: AL does not short-circuit AND. With a left operand that is already false at run
    // time, the right operand is evaluated anyway. Observed through a counter a helper bumps,
    // so the claim rests on an effect the expression had and not on the value it produced.
    var
        LeftOperand: Boolean;
        Result: Boolean;
    begin
        ProbeCalls := 0;
        LeftOperand := StrLen('ab') = 3; // false, but computed, so it is not a literal to fold away

        Result := LeftOperand and ProbeReturnsTrue();

        Assert.IsFalse(Result, 'false AND true must still evaluate to false');
        Assert.AreEqual(1, ProbeCalls,
            'AL evaluates both operands of AND: the right operand of a false AND must run exactly once');
    end;

    [Test]
    procedure Boolean_OR_TrueLeftOperand_RightOperandIsStillEvaluated()
    // CLAIM: the same for OR, in the direction where a short-circuiting language would skip
    // the right operand -- a true left operand.
    var
        LeftOperand: Boolean;
        Result: Boolean;
    begin
        ProbeCalls := 0;
        LeftOperand := StrLen('ab') = 2; // true, but computed

        Result := LeftOperand or ProbeReturnsFalse();

        Assert.IsTrue(Result, 'true OR false must still evaluate to true');
        Assert.AreEqual(1, ProbeCalls,
            'AL evaluates both operands of OR: the right operand of a true OR must run exactly once');
    end;

    [Test]
    procedure Boolean_NestedIf_GuardedOperand_IsNotEvaluated()
    // CLAIM (the control arm for the two above): nesting the second test inside the first is
    // what actually guards it. Same helper, same false condition, zero calls. Without this
    // arm the counter assertions above could be satisfied by a helper that is simply never
    // reachable in either shape.
    var
        LeftOperand: Boolean;
        Reached: Boolean;
    begin
        ProbeCalls := 0;
        LeftOperand := StrLen('ab') = 3; // false

        if LeftOperand then
            if ProbeReturnsTrue() then
                Reached := true;

        Assert.IsFalse(Reached, 'the guarded branch must not be reached');
        Assert.AreEqual(0, ProbeCalls,
            'nesting is what guards the second test: the helper must not run at all');
    end;

    [Test]
    procedure Boolean_AND_FalseLeftOperand_RightOperandThatRaises_StillRaises()
    // CLAIM: the consequence that bites real AL code. Guarding an out-of-range index with a
    // count check in the SAME boolean expression does not guard it -- the index call runs and
    // raises. KeyIndex(1) of "ALT Keyed" is its single-field primary key, so FieldIndex(2) is
    // out of range by construction and FieldCount() = 2 is false, which is exactly the shape
    // a short-circuiting language would never evaluate.
    var
        RecRef: RecordRef;
        KRef: KeyRef;
        Matched: Boolean;
    begin
        RecRef.Open(Database::"ALT Keyed");
        KRef := RecRef.KeyIndex(1);
        Assert.AreEqual(1, KRef.FieldCount(),
            'the primary key of ALT Keyed must have exactly one field for this test to mean anything');

        asserterror Matched := (KRef.FieldCount() = 2) and (KRef.FieldIndex(2).Name() = 'Name');
        Assert.ExpectedError('Index out of bounds');

        Assert.IsFalse(Matched, 'the assignment must not have completed');
    end;

    local procedure ProbeReturnsTrue(): Boolean
    begin
        ProbeCalls += 1;
        exit(true);
    end;

    local procedure ProbeReturnsFalse(): Boolean
    begin
        ProbeCalls += 1;
        exit(false);
    end;
}
