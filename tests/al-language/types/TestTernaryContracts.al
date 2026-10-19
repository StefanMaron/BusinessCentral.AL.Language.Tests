codeunit 60193 "Test Ternary Contracts"
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
    procedure Ternary_TrueCondition_ReturnsFirstBranch()
    var
        Result: Text;
    begin
        Result := (5 > 3) ? 'big' : 'small';
        Assert.AreEqual('big', Result, 'Ternary with true condition must return first branch');
    end;

    [Test]
    procedure Ternary_FalseCondition_ReturnsSecondBranch()
    var
        Result: Text;
    begin
        Result := (3 > 5) ? 'big' : 'small';
        Assert.AreEqual('small', Result, 'Ternary with false condition must return second branch');
    end;

    [Test]
    procedure Ternary_Integer_TrueCondition()
    var
        Result: Integer;
    begin
        Result := (10 > 5) ? 100 : 200;
        Assert.AreEqual(100, Result, 'Ternary with integer values: true → 100');
    end;

    [Test]
    procedure Ternary_Integer_FalseCondition()
    var
        Result: Integer;
    begin
        Result := (5 > 10) ? 100 : 200;
        Assert.AreEqual(200, Result, 'Ternary with integer values: false → 200');
    end;

    [Test]
    procedure Ternary_InExitExpression()
    var
        Result: Text;
    begin
        Result := ClassifyNumber(7);
        Assert.AreEqual('big', Result, 'exit(n > 3 ? "big" : "small") must return "big" for n=7');
    end;

    [Test]
    procedure Ternary_InExitExpression_Opposite()
    var
        Result: Text;
    begin
        Result := ClassifyNumber(2);
        Assert.AreEqual('small', Result, 'exit(n > 3 ? "big" : "small") must return "small" for n=2');
    end;

    [Test]
    procedure Ternary_BothBranches_Differ()
    begin
        Assert.AreNotEqual(ClassifyNumber(10), ClassifyNumber(0), 'Ternary must produce different values for different branches');
    end;

    [Test]
    procedure Ternary_NestedTernary()
    var
        Result: Text;
    begin
        Result := BucketNumber(5);
        Assert.AreEqual('low', Result, 'Nested ternary: 5 < 10 → "low"');
    end;

    [Test]
    procedure Ternary_NestedTernary_Middle()
    var
        Result: Text;
    begin
        Result := BucketNumber(50);
        Assert.AreEqual('mid', Result, 'Nested ternary: 50 not < 10 but < 100 → "mid"');
    end;

    [Test]
    procedure Ternary_NestedTernary_High()
    var
        Result: Text;
    begin
        Result := BucketNumber(500);
        Assert.AreEqual('high', Result, 'Nested ternary: 500 not < 100 → "high"');
    end;

    [Test]
    procedure Ternary_Max_ReturnsLarger()
    var
        Result: Integer;
    begin
        Result := MaxOfTwo(7, 4);
        Assert.AreEqual(7, Result, 'a >= b ? a : b must return larger value');
    end;

    [Test]
    procedure Ternary_FlipBoolean()
    var
        Result: Boolean;
    begin
        Result := FlipBool(true);
        Assert.IsFalse(Result, 'Ternary flip: true ? false : true must return false');
    end;

    local procedure ClassifyNumber(N: Integer): Text
    begin
        exit(N > 3 ? 'big' : 'small');
    end;

    local procedure BucketNumber(N: Integer): Text
    begin
        exit(N < 10 ? 'low' : N < 100 ? 'mid' : 'high');
    end;

    local procedure MaxOfTwo(A: Integer; B: Integer): Integer
    begin
        exit(A >= B ? A : B);
    end;

    local procedure FlipBool(B: Boolean): Boolean
    begin
        exit(B ? false : true);
    end;

    // corpus issue 664 (writer BN): ternary branches of different types (microsoft/AL issues 7937, 7926, 8151, 8106). The true branch sets
    // the type of the expression. `Cond ? '1' : ''` and `Cond ? CurrentDateTime() : Today()` do not compile:
    // tests/must-not-compile/cases/1405 and 1406. Observed on BC (probe form: Observer.Finish).
    [Test]
    procedure BN_Ternary_CharAndTextLiterals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('true', CharTextForms(true));
        Observer.Observe('false', CharTextForms(false));
        Observer.Finish();
    end;

    local procedure CharTextForms(Cond: Boolean): Text
    var
        Txt: Text;
        R: Text;
    begin
        Txt := Cond ? '' : '1';
        R := '[' + Txt + ']';
        Txt := Cond ? '1' : ' ';
        R += '[' + Txt + ']';
        Txt := Cond ? '1' : '0';
        R += '[' + Txt + ']';
        Txt := Cond ? ('' + 'a') : '';
        R += '[' + Txt + ']';
        Txt := Cond ? Format('1') : '';
        R += '[' + Txt + ']';
        exit(R);
    end;

    [Test]
    procedure BN_Ternary_VariantBranch()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        if TryVariantTrueText(false, V) then
            Observer.Observe('Cond ? Bar : GetVariant(), false', 'ok|' + Format(V) + '|' + VariantKind(V))
        else
            Observer.ObserveError('Cond ? Bar : GetVariant(), false');
        if TryVariantTrueText(true, V) then
            Observer.Observe('Cond ? Bar : GetVariant(), true', 'ok|' + Format(V) + '|' + VariantKind(V))
        else
            Observer.ObserveError('Cond ? Bar : GetVariant(), true');
        if TryVariantTrueVariant(false, V) then
            Observer.Observe('Cond ? GetVariant() : Bar, false', 'ok|' + Format(V) + '|' + VariantKind(V))
        else
            Observer.ObserveError('Cond ? GetVariant() : Bar, false');
        if TryVariantTrueVariant(true, V) then
            Observer.Observe('Cond ? GetVariant() : Bar, true', 'ok|' + Format(V) + '|' + VariantKind(V))
        else
            Observer.ObserveError('Cond ? GetVariant() : Bar, true');
        Observer.Finish();
    end;

    local procedure GetVariant(): Variant
    var
        V: Variant;
        I: Integer;
    begin
        I := 5;
        V := I;
        exit(V);
    end;

    local procedure VariantKind(V: Variant): Text
    begin
        if V.IsInteger() then
            exit('Integer');
        if V.IsText() then
            exit('Text');
        if V.IsCode() then
            exit('Code');
        exit('other');
    end;

    [TryFunction]
    local procedure TryVariantTrueText(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? 'Bar' : GetVariant();
    end;

    [TryFunction]
    local procedure TryVariantTrueVariant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? GetVariant() : 'Bar';
    end;

    [Test]
    procedure BN_Ternary_IntegerAndDecimalBranches()
    var
        Observer: Codeunit "Probe Observer";
        Quantity: Decimal;
    begin
        if TryIntTrue(false, 0.25, Quantity) then
            Observer.Observe('Boo ? 1 : 0.25, false', 'ok|' + Format(Quantity))
        else
            Observer.ObserveError('Boo ? 1 : 0.25, false');
        if TryIntTrue(false, 3, Quantity) then
            Observer.Observe('Boo ? 1 : 3.0, false', 'ok|' + Format(Quantity))
        else
            Observer.ObserveError('Boo ? 1 : 3.0, false');
        if TryIntTrue(false, 2.5, Quantity) then
            Observer.Observe('Boo ? 1 : 2.5, false', 'ok|' + Format(Quantity))
        else
            Observer.ObserveError('Boo ? 1 : 2.5, false');
        if TryIntTrue(true, 0.25, Quantity) then
            Observer.Observe('Boo ? 1 : 0.25, true', 'ok|' + Format(Quantity))
        else
            Observer.ObserveError('Boo ? 1 : 0.25, true');
        if TryDecTrue(false, 0.25, Quantity) then
            Observer.Observe('Boo ? 0.25 : 1, false', 'ok|' + Format(Quantity))
        else
            Observer.ObserveError('Boo ? 0.25 : 1, false');
        if TryDecTrue(true, 0.25, Quantity) then
            Observer.Observe('Boo ? 0.25 : 1, true', 'ok|' + Format(Quantity))
        else
            Observer.ObserveError('Boo ? 0.25 : 1, true');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryIntTrue(Boo: Boolean; OrigQty: Decimal; var Quantity: Decimal)
    begin
        Quantity := Boo ? 1 : OrigQty;
    end;

    [TryFunction]
    local procedure TryDecTrue(Boo: Boolean; OrigQty: Decimal; var Quantity: Decimal)
    begin
        Quantity := Boo ? OrigQty : 1;
    end;

    [Test]
    procedure BN_Ternary_Code20TrueBranch()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        if TryCodeTrue(false, Result) then
            Observer.Observe('Cond ? Code20 : 30-char text, false', 'ok|' + Result + '|' + Format(StrLen(Result)))
        else
            Observer.ObserveError('Cond ? Code20 : 30-char text, false');
        if TryCodeTrue(true, Result) then
            Observer.Observe('Cond ? Code20 : 30-char text, true', 'ok|' + Result)
        else
            Observer.ObserveError('Cond ? Code20 : 30-char text, true');
        if TryTextTrue(false, Result) then
            Observer.Observe('Cond ? 30-char text : Code20, false', 'ok|' + Result)
        else
            Observer.ObserveError('Cond ? 30-char text : Code20, false');
        if TryTextTrue(true, Result) then
            Observer.Observe('Cond ? 30-char text : Code20, true', 'ok|' + Result + '|' + Format(StrLen(Result)))
        else
            Observer.ObserveError('Cond ? 30-char text : Code20, true');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryCodeTrue(Cond: Boolean; var Result: Text)
    var
        C20: Code[20];
        LongText: Text;
    begin
        C20 := 'shortcode';
        LongText := 'abcdefghijklmnopqrstuvwxyz1234';
        Result := Cond ? C20 : LongText;
    end;

    [TryFunction]
    local procedure TryTextTrue(Cond: Boolean; var Result: Text)
    var
        C20: Code[20];
        LongText: Text;
    begin
        C20 := 'shortcode';
        LongText := 'abcdefghijklmnopqrstuvwxyz1234';
        Result := Cond ? LongText : C20;
    end;
}
