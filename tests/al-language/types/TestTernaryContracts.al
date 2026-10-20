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
        Observer.Expect('true', '[][1][1][a][1]');
        Observer.Expect('false', '[1][ ][0][][]');
        Observer.Verify();
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
        Observer.Expect('Cond ? Bar : GetVariant(), false|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('Cond ? Bar : GetVariant(), false|code', 'TypeConversion');
        Observer.Expect('Cond ? Bar : GetVariant(), true', 'ok|Bar|Text');
        Observer.Expect('Cond ? GetVariant() : Bar, false', 'ok|Bar|Text');
        Observer.Expect('Cond ? GetVariant() : Bar, true', 'ok|5|Integer');
        Observer.Verify();
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
        Observer.Expect('Boo ? 1 : 0.25, false|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.25 to System.Int32.');
        Observer.Expect('Boo ? 1 : 0.25, false|code', 'ConversionCast');
        Observer.Expect('Boo ? 1 : 3.0, false', 'ok|3');
        Observer.Expect('Boo ? 1 : 2.5, false|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Observer.Expect('Boo ? 1 : 2.5, false|code', 'ConversionCast');
        Observer.Expect('Boo ? 1 : 0.25, true', 'ok|1');
        Observer.Expect('Boo ? 0.25 : 1, false', 'ok|1');
        Observer.Expect('Boo ? 0.25 : 1, true', 'ok|0.25');
        Observer.Verify();
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
        Observer.Expect('Cond ? Code20 : 30-char text, false|text', 'The length of the string is 30, but it must be less than or equal to 20 characters. Value: abcdefghijklmnopqrstuvwxyz1234');
        Observer.Expect('Cond ? Code20 : 30-char text, false|code', 'StringLengthExceeded');
        Observer.Expect('Cond ? Code20 : 30-char text, true', 'ok|SHORTCODE');
        Observer.Expect('Cond ? 30-char text : Code20, false', 'ok|SHORTCODE');
        Observer.Expect('Cond ? 30-char text : Code20, true', 'ok|abcdefghijklmnopqrstuvwxyz1234|30');
        Observer.Verify();
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
    // Writer PY-C (al-runtime-rs PR 339, probes-needed "Ternary and call-argument conversion"): Integer true with BigInteger false beyond Int32,
    // Text[10] true with a 12-character Text false, Option and Enum true with Integer false. Each read into a BigInteger, Text or Integer.
    [Test]
    procedure PYC_Ternary_MoreBranchPairs()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigInteger;
        R: Text;
        I: Integer;
    begin
        ClearLastError();
        if TryIntBig(false, 3000000000L, Big) then
            Observer.Observe('Cond ? 1 : Big 3e9, false', 'ok|' + Format(Big))
        else
            Observer.ObserveError('Cond ? 1 : Big 3e9, false');
        if TryIntBig(false, 5L, Big) then
            Observer.Observe('Cond ? 1 : Big 5, false', 'ok|' + Format(Big))
        else
            Observer.ObserveError('Cond ? 1 : Big 5, false');
        if TryBigInt(false, 3000000000L, Big) then
            Observer.Observe('Cond ? Big 3e9 : 1, true', 'ok|' + Format(Big))
        else
            Observer.ObserveError('Cond ? Big 3e9 : 1, true');
        if TryText10(false, R) then
            Observer.Observe('Cond ? Text10 : 12-char text, false', 'ok|' + R + '|' + Format(StrLen(R)))
        else
            Observer.ObserveError('Cond ? Text10 : 12-char text, false');
        if TryText10(true, R) then
            Observer.Observe('Cond ? Text10 : 12-char text, true', 'ok|' + R)
        else
            Observer.ObserveError('Cond ? Text10 : 12-char text, true');
        if TryOptionInt(false, I) then
            Observer.Observe('Cond ? Option : Integer 7, false', 'ok|' + Format(I))
        else
            Observer.ObserveError('Cond ? Option : Integer 7, false');
        if TryOptionInt(true, I) then
            Observer.Observe('Cond ? Option : Integer 7, true', 'ok|' + Format(I))
        else
            Observer.ObserveError('Cond ? Option : Integer 7, true');
        if TryEnumInt(false, I) then
            Observer.Observe('Cond ? Enum : Integer 7, false', 'ok|' + Format(I))
        else
            Observer.ObserveError('Cond ? Enum : Integer 7, false');
        if TryEnumInt(true, I) then
            Observer.Observe('Cond ? Enum : Integer 7, true', 'ok|' + Format(I))
        else
            Observer.ObserveError('Cond ? Enum : Integer 7, true');
        Observer.Expect('Cond ? 1 : Big 3e9, false|text', 'Overflow under conversion of System.Int64 value 3000000000 to System.Int32.');
        Observer.Expect('Cond ? 1 : Big 3e9, false|code', 'ConversionCast');
        Observer.Expect('Cond ? 1 : Big 5, false', 'ok|5');
        Observer.Expect('Cond ? Big 3e9 : 1, true', 'ok|3000000000');
        Observer.Expect('Cond ? Text10 : 12-char text, false|text', 'The length of the string is 12, but it must be less than or equal to 10 characters. Value: abcdefghijkl');
        Observer.Expect('Cond ? Text10 : 12-char text, false|code', 'StringLengthExceeded');
        Observer.Expect('Cond ? Text10 : 12-char text, true', 'ok|short');
        Observer.Expect('Cond ? Option : Integer 7, false', 'ok|7');
        Observer.Expect('Cond ? Option : Integer 7, true', 'ok|2');
        Observer.Expect('Cond ? Enum : Integer 7, false', 'ok|7');
        Observer.Expect('Cond ? Enum : Integer 7, true', 'ok|2');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryIntBig(Cond: Boolean; B: BigInteger; var Result: BigInteger)
    begin
        Result := Cond ? 1 : B;
    end;

    [TryFunction]
    local procedure TryBigInt(Cond: Boolean; B: BigInteger; var Result: BigInteger)
    begin
        Result := not Cond ? B : 1;
    end;

    [TryFunction]
    local procedure TryText10(Cond: Boolean; var Result: Text)
    var
        T10: Text[10];
        T: Text;
    begin
        T10 := 'short';
        T := 'abcdefghijkl';
        Result := Cond ? T10 : T;
    end;

    [TryFunction]
    local procedure TryOptionInt(Cond: Boolean; var Result: Integer)
    var
        Opt: Option Zero,One,Two;
    begin
        Opt := Opt::Two;
        Result := Cond ? Opt : 7;
    end;

    [TryFunction]
    local procedure TryEnumInt(Cond: Boolean; var Result: Integer)
    var
        E: Enum "Sales Document Type";
    begin
        E := E::Invoice;
        Result := Cond ? E : 7;
    end;
}
