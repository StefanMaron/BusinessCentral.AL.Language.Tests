// Observe-only probes (writer A). Rows: StrCheckSum, Format boolean, Error code, operators, text compare, Code assign,
// Evaluate boolean, Random, Round/Power, Guid evaluate, Text[i] assign.
table 69800 "PA Scalar Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Cd; Code[20]) { }
        field(3; Flag; Boolean) { }
        field(4; Txt; Text[50]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 69800 "PA Scalar Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Calls: Integer;

    [Test]
    procedure StrCheckSum_Values()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('doc_example_1234567890_w1234567', Format(StrCheckSum('1234567890', '1234567')));
        O.Observe('123_w1', Format(StrCheckSum('123', '1')));
        O.Observe('123_w123', Format(StrCheckSum('123', '123')));
        O.Observe('empty_w1', Format(StrCheckSum('', '1')));
        O.Observe('123_w12_shortweight', Format(StrCheckSum('123', '12')));
        O.Observe('123_w321_mod7', Format(StrCheckSum('123', '321', 7)));
        O.Observe('123_w321_mod11', Format(StrCheckSum('123', '321', 11)));
        O.Observe('999_w999_mod10', Format(StrCheckSum('999', '999')));
        O.Observe('0_w1', Format(StrCheckSum('0', '1')));
        O.Expect('doc_example_1234567890_w1234567', '3');
        O.Expect('123_w1', '4');
        O.Expect('123_w123', '6');
        O.Expect('empty_w1', '0');
        O.Expect('123_w12_shortweight', '2');
        O.Expect('123_w321_mod7', '4');
        O.Expect('123_w321_mod11', '1');
        O.Expect('999_w999_mod10', '7');
        O.Expect('0_w1', '0');
        O.Verify();
    end;

    [Test]
    procedure StrCheckSum_NonDigitSource()
    var
        O: Codeunit "Probe Observer";
        R: Integer;
    begin
        asserterror R := StrCheckSum('12a', '123');
        O.ObserveError('nondigit_source');
        O.Expect('nondigit_source|text', 'The value string must be numeric.');
        O.Expect('nondigit_source|code', 'ALSystemString');
        O.Verify();
    end;

    [Test]
    procedure StrCheckSum_NonDigitWeight()
    var
        O: Codeunit "Probe Observer";
        R: Integer;
    begin
        asserterror R := StrCheckSum('123', '1a3');
        O.ObserveError('nondigit_weight');
        O.Expect('nondigit_weight|text', 'The weight string must be numeric.');
        O.Expect('nondigit_weight|code', 'ALSystemString');
        O.Verify();
    end;

    [Test]
    procedure StrCheckSum_WeightLongerThanSource()
    var
        O: Codeunit "Probe Observer";
        R: Integer;
    begin
        asserterror R := StrCheckSum('12', '12345');
        O.ObserveError('weight_longer');
        O.Expect('weight_longer|text', 'The weight parameter cannot be longer than the value string.');
        O.Expect('weight_longer|code', 'ALSystemString');
        O.Verify();
    end;

    [Test]
    procedure StrCheckSum_ModulusZero()
    var
        O: Codeunit "Probe Observer";
        R: Integer;
    begin
        asserterror R := StrCheckSum('123', '123', 0);
        O.ObserveError('modulus_0');
        O.Expect('modulus_0|text', 'The modulus parameter cannot be less than 1.');
        O.Expect('modulus_0|code', 'ALSystemString');
        O.Verify();
    end;

    [Test]
    procedure StrCheckSum_ModulusNegative()
    var
        O: Codeunit "Probe Observer";
        R: Integer;
    begin
        asserterror R := StrCheckSum('123', '123', -3);
        O.ObserveError('modulus_minus3');
        O.Expect('modulus_minus3|text', 'The modulus parameter cannot be less than 1.');
        O.Expect('modulus_minus3|code', 'ALSystemString');
        O.Verify();
    end;

    [Test]
    procedure StrCheckSum_ModulusOne()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('modulus_1', Format(StrCheckSum('123', '123', 1)));
        O.Expect('modulus_1', '0');
        O.Verify();
    end;

    [Test]
    procedure FormatBoolean_Numbers()
    var
        O: Codeunit "Probe Observer";
        i: Integer;
    begin
        O.Observe('true_9', Format(true, 0, 9));
        O.Observe('false_9', Format(false, 0, 9));
        O.Observe('true_default', Format(true));
        O.Observe('false_default', Format(false));
        for i := 0 to 2 do begin
            O.Observe('true_fmt' + Format(i), Format(true, 0, i));
            O.Observe('false_fmt' + Format(i), Format(false, 0, i));
        end;
        O.Observe('true_len10', Format(true, 10));
        O.Observe('true_len2', Format(true, 2));
        O.Expect('true_9', 'true');
        O.Expect('false_9', 'false');
        O.Expect('true_default', 'Yes');
        O.Expect('false_default', 'No');
        O.Expect('true_fmt0', 'Yes');
        O.Expect('false_fmt0', 'No');
        O.Expect('true_fmt1', 'Yes');
        O.Expect('false_fmt1', 'No');
        O.Expect('true_fmt2', '1');
        O.Expect('false_fmt2', '0');
        O.Expect('true_len10', 'Yes       ');
        O.Expect('true_len2', 'Ye');
        O.Verify();
    end;

    [Test]
    procedure ErrorText_SetsCodeDialog()
    var
        O: Codeunit "Probe Observer";
    begin
        asserterror Error('Plain %1 text', 5);
        O.ObserveError('error_formatted');
        asserterror Error('');
        O.ObserveError('error_empty');
        O.Expect('error_formatted|text', 'Plain 5 text');
        O.Expect('error_formatted|code', 'Dialog');
        O.Expect('error_empty|text', '');
        O.Expect('error_empty|code', 'Dialog');
        O.Verify();
    end;

    [Test]
    procedure Operators_AndOrNoShortCircuit()
    var
        O: Codeunit "Probe Observer";
        R: Boolean;
    begin
        Calls := 0;
        R := Bump(false) and Bump(true);
        O.Observe('and_false_first_calls', Format(Calls));
        Calls := 0;
        R := Bump(true) or Bump(false);
        O.Observe('or_true_first_calls', Format(Calls));
        Calls := 0;
        R := Bump(true) and Bump(true) and Bump(false) and Bump(true);
        O.Observe('and_chain_calls', Format(Calls));
        Calls := 0;
        if (Calls = 0) or (Bump(true)) then;
        O.Observe('if_or_calls', Format(Calls));
        O.Expect('and_false_first_calls', '2');
        O.Expect('or_true_first_calls', '2');
        O.Expect('and_chain_calls', '4');
        O.Expect('if_or_calls', '1');
        O.Verify();
    end;

    local procedure Bump(Result: Boolean): Boolean
    begin
        Calls += 1;
        exit(Result);
    end;

    [Test]
    procedure TextCompare_CaseAndOrdinal()
    var
        O: Codeunit "Probe Observer";
        A: Text;
        B: Text;
    begin
        O.Observe('a_eq_A', Format('a' = 'A'));
        O.Observe('a_lt_B', Format('a' < 'B'));
        O.Observe('B_lt_a', Format('B' < 'a'));
        O.Observe('Z_lt_a', Format('Z' < 'a'));
        O.Observe('abc_lt_abd', Format('abc' < 'abd'));
        O.Observe('abc_lt_ABD', Format('abc' < 'ABD'));
        O.Observe('ABC_lt_abd', Format('ABC' < 'abd'));
        O.Observe('empty_lt_a', Format('' < 'a'));
        O.Observe('a_lt_ae_umlaut_before_z', Format('ä' < 'z'));
        O.Observe('ae_umlaut_eq_a', Format('ä' = 'a'));
        O.Observe('ss_eq_sharp_s', Format('ss' = 'ß'));
        A := 'Hello';
        B := 'hello';
        O.Observe('Hello_eq_hello', Format(A = B));
        O.Observe('Hello_lt_hello', Format(A < B));
        O.Observe('Hello_gt_hello', Format(A > B));
        O.Observe('trailing_space_eq', Format('a ' = 'a'));
        O.Observe('code_eq_text_case', Format(CodeEq('abc', 'ABC')));
        O.Expect('a_eq_A', 'No');
        O.Expect('a_lt_B', 'Yes');
        O.Expect('B_lt_a', 'No');
        O.Expect('Z_lt_a', 'No');
        O.Expect('abc_lt_abd', 'Yes');
        O.Expect('abc_lt_ABD', 'Yes');
        O.Expect('ABC_lt_abd', 'Yes');
        O.Expect('empty_lt_a', 'Yes');
        O.Expect('a_lt_ae_umlaut_before_z', 'Yes');
        O.Expect('ae_umlaut_eq_a', 'No');
        O.Expect('ss_eq_sharp_s', 'No');
        O.Expect('Hello_eq_hello', 'No');
        O.Expect('Hello_lt_hello', 'No');
        O.Expect('Hello_gt_hello', 'Yes');
        O.Expect('trailing_space_eq', 'No');
        O.Expect('code_eq_text_case', 'No');
        O.Verify();
    end;

    local procedure CodeEq(T: Text; C: Code[20]): Boolean
    begin
        exit(T = C);
    end;

    [Test]
    procedure CodeAssign_UpperAndTrim()
    var
        O: Codeunit "Probe Observer";
        C: Code[10];
        C2: Code[20];
        T: Text[20];
    begin
        C := '  ab  ';
        O.Observe('spaces_both', '[' + C + ']');
        C := 'abc def';
        O.Observe('inner_space', '[' + C + ']');
        T := '  xy  ';
        C2 := T;
        O.Observe('from_text_var', '[' + C2 + ']');
        C2 := 'äöüß';
        O.Observe('umlaut_sharp_s', '[' + C2 + ']');
        C2 := 'é';
        O.Observe('e_acute', '[' + C2 + ']');
        C2 := CopyStr('a' + Format(CreateGuid()), 1, 20);
        O.Observe('upper_guid_has_lower', Format(C2 = UpperCase(C2)));
        C2 := '	tab	';
        O.Observe('tabs', '[' + C2 + ']' + Format(StrLen(C2)));
        asserterror C := '0123456789A';
        O.ObserveError('too_long_11');
        C := '0123456789 ';
        O.Observe('too_long_trailing_space', 'no error');
        O.Expect('spaces_both', '[AB]');
        O.Expect('inner_space', '[ABC DEF]');
        O.Expect('from_text_var', '[XY]');
        O.Expect('umlaut_sharp_s', '[ÄÖÜß]');
        O.Expect('e_acute', '[É]');
        O.Expect('upper_guid_has_lower', 'Yes');
        O.Expect('tabs', '[TAB]3');
        O.Expect('too_long_11|text', 'The length of the string is 11, but it must be less than or equal to 10 characters. Value: 0123456789A');
        O.Expect('too_long_11|code', 'StringLengthExceeded');
        O.Expect('too_long_trailing_space', 'no error');
        O.Verify();
    end;

    [Test]
    procedure SetFilter_CodeFieldUpperCases()
    var
        O: Codeunit "Probe Observer";
        Row: Record "PA Scalar Row";
    begin
        Row.DeleteAll();
        Ins(1, 'AP1', true);
        Ins(2, 'ap2', false);
        Ins(3, 'BP3', true);
        Row.SetFilter(Cd, 'ap*');
        O.Observe('filter_ap_star_count', Format(Row.Count()));
        O.Observe('filter_ap_star_getfilter', Row.GetFilter(Cd));
        Row.SetFilter(Cd, '@ap*');
        O.Observe('filter_at_ap_star_count', Format(Row.Count()));
        O.Observe('filter_at_ap_getfilter', Row.GetFilter(Cd));
        Row.SetFilter(Cd, 'ap1');
        O.Observe('filter_ap1_count', Format(Row.Count()));
        O.Observe('filter_ap1_getfilter', Row.GetFilter(Cd));
        Row.SetRange(Cd, 'ap2');
        O.Observe('range_ap2_count', Format(Row.Count()));
        O.Observe('range_ap2_getfilter', Row.GetFilter(Cd));
        Row.Reset();
        Row.SetFilter(Txt, 'x*');
        O.Observe('text_field_filter_getfilter', Row.GetFilter(Txt));
        Row.DeleteAll();
        O.Expect('filter_ap_star_count', '2');
        O.Expect('filter_ap_star_getfilter', 'AP*');
        O.Expect('filter_at_ap_star_count', '2');
        O.Expect('filter_at_ap_getfilter', '@AP*');
        O.Expect('filter_ap1_count', '1');
        O.Expect('filter_ap1_getfilter', 'AP1');
        O.Expect('range_ap2_count', '1');
        O.Expect('range_ap2_getfilter', 'AP2');
        O.Expect('text_field_filter_getfilter', 'x*');
        O.Verify();
    end;

    local procedure Ins(Id: Integer; C: Code[20]; F: Boolean)
    var
        R: Record "PA Scalar Row";
    begin
        R.Id := Id;
        R.Cd := C;
        R.Flag := F;
        R.Insert();
    end;

    [Test]
    procedure SetFilter_BooleanText()
    var
        O: Codeunit "Probe Observer";
        Row: Record "PA Scalar Row";
        Texts: List of [Text];
        T: Text;
    begin
        Row.DeleteAll();
        Ins(1, 'A', true);
        Ins(2, 'B', false);
        Texts.Add('Yes');
        Texts.Add('No');
        Texts.Add('yes');
        Texts.Add('true');
        Texts.Add('false');
        Texts.Add('TRUE');
        Texts.Add('1');
        Texts.Add('0');
        Texts.Add('Ja');
        Texts.Add('abc');
        Texts.Add('Yes|No');
        foreach T in Texts do
            O.Observe('bool_filter_' + T, TryBoolFilter(T));
        Row.DeleteAll();
        O.Expect('bool_filter_Yes', 'count=1 getfilter=Yes');
        O.Expect('bool_filter_No', 'count=1 getfilter=No');
        O.Expect('bool_filter_yes', 'count=1 getfilter=Yes');
        O.Expect('bool_filter_true', 'count=1 getfilter=Yes');
        O.Expect('bool_filter_false', 'count=1 getfilter=No');
        O.Expect('bool_filter_TRUE', 'count=1 getfilter=Yes');
        O.Expect('bool_filter_1', 'count=1 getfilter=Yes');
        O.Expect('bool_filter_0', 'count=1 getfilter=No');
        O.Expect('bool_filter_Ja', 'ERR:The filter "Ja" is not valid for the Flag field on the PA Scalar Row table. The value "Ja" can''t be evaluated into type Boolean./Filter:CSide');
        O.Expect('bool_filter_abc', 'ERR:The filter "abc" is not valid for the Flag field on the PA Scalar Row table. The value "abc" can''t be evaluated into type Boolean./Filter:CSide');
        O.Expect('bool_filter_Yes|No', 'count=2 getfilter=Yes|No');
        O.Verify();
    end;

    local procedure TryBoolFilter(T: Text): Text
    var
        Row: Record "PA Scalar Row";
        Cnt: Integer;
        GF: Text;
    begin
        if not TryApply(T, Cnt, GF) then
            exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
        exit('count=' + Format(Cnt) + ' getfilter=' + GF);
    end;

    [TryFunction]
    local procedure TryApply(T: Text; var Cnt: Integer; var GF: Text)
    var
        Row: Record "PA Scalar Row";
    begin
        Row.SetFilter(Flag, T);
        Cnt := Row.Count();
        GF := Row.GetFilter(Flag);
    end;

    [Test]
    procedure Evaluate_BooleanTexts()
    var
        O: Codeunit "Probe Observer";
        Texts: List of [Text];
        T: Text;
        B: Boolean;
    begin
        Texts.Add('0');
        Texts.Add('F');
        Texts.Add('f');
        Texts.Add('1');
        Texts.Add('T');
        Texts.Add('t');
        Texts.Add('true');
        Texts.Add('TRUE');
        Texts.Add('false');
        Texts.Add('Yes');
        Texts.Add('no');
        Texts.Add('Y');
        Texts.Add('N');
        Texts.Add('y');
        Texts.Add('n');
        Texts.Add('2');
        Texts.Add('');
        Texts.Add(' true');
        Texts.Add('true ');
        Texts.Add('on');
        Texts.Add('Ja');
        foreach T in Texts do begin
            B := not true;
            if Evaluate(B, T) then
                O.Observe('evaluate_bool_[' + T + ']', 'ok:' + Format(B))
            else
                O.Observe('evaluate_bool_[' + T + ']', 'fail');
        end;
        O.Expect('evaluate_bool_[0]', 'ok:No');
        O.Expect('evaluate_bool_[F]', 'ok:No');
        O.Expect('evaluate_bool_[f]', 'ok:No');
        O.Expect('evaluate_bool_[1]', 'ok:Yes');
        O.Expect('evaluate_bool_[T]', 'ok:Yes');
        O.Expect('evaluate_bool_[t]', 'ok:Yes');
        O.Expect('evaluate_bool_[true]', 'ok:Yes');
        O.Expect('evaluate_bool_[TRUE]', 'ok:Yes');
        O.Expect('evaluate_bool_[false]', 'ok:No');
        O.Expect('evaluate_bool_[Yes]', 'ok:Yes');
        O.Expect('evaluate_bool_[no]', 'ok:No');
        O.Expect('evaluate_bool_[Y]', 'ok:Yes');
        O.Expect('evaluate_bool_[N]', 'ok:No');
        O.Expect('evaluate_bool_[y]', 'ok:Yes');
        O.Expect('evaluate_bool_[n]', 'ok:No');
        O.Expect('evaluate_bool_[2]', 'fail');
        O.Expect('evaluate_bool_[]', 'fail');
        O.Expect('evaluate_bool_[ true]', 'ok:Yes');
        O.Expect('evaluate_bool_[true ]', 'ok:Yes');
        O.Expect('evaluate_bool_[on]', 'fail');
        O.Expect('evaluate_bool_[Ja]', 'fail');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_BooleanFailureError()
    var
        O: Codeunit "Probe Observer";
        B: Boolean;
        T: Text;
    begin
        T := 'maybe';
        asserterror Evaluate(B, T);
        O.Observe('evaluate_statement_has_error', Format(GetLastErrorText() <> ''));
        O.Observe('evaluate_statement_code', GetLastErrorCode());
        O.Expect('evaluate_statement_has_error', 'Yes');
        O.Expect('evaluate_statement_code', 'Evaluate');
        O.Verify();
    end;

    [Test]
    procedure Round_PrecisionAndPower()
    var
        O: Codeunit "Probe Observer";
        D: Decimal;
    begin
        O.Observe('round_1_5_prec_0', Format(Round(1.5, 0.1)));
        O.Observe('round_2_5_prec_1', Format(Round(2.5, 1)));
        O.Observe('round_minus_2_5_prec_1', Format(Round(-2.5, 1)));
        O.Observe('round_1234_prec_100', Format(Round(1234, 100)));
        O.Observe('round_3_14159_001', Format(Round(3.14159, 0.01)));
        O.Observe('round_up_3_141', Format(Round(3.141, 0.01, '>')));
        O.Observe('round_down_3_149', Format(Round(3.149, 0.01, '<')));
        O.Observe('round_nearest_explicit', Format(Round(2.5, 1, '=')));
        O.Observe('round_prec_neg', TryRound(1.5, -1));
        O.Observe('round_prec_zero', TryRound(1.5, 0));
        O.Observe('round_prec_tiny', TryRound(1.5, 0.0000000001));
        O.Observe('power_2_0_5', Format(Power(2, 0.5), 0, 9));
        O.Observe('power_2_10', Format(Power(2, 10), 0, 9));
        O.Observe('power_2_neg2', Format(Power(2, -2), 0, 9));
        O.Observe('power_2_100', TryPower(2, 100));
        O.Observe('power_3_0_333', Format(Power(3, 0.3333333), 0, 9));
        O.Observe('power_0_0', Format(Power(0, 0), 0, 9));
        O.Observe('power_0_neg1', TryPower(0, -1));
        O.Observe('power_neg2_0_5', TryPower(-2, 0.5));
        O.Observe('power_neg2_3', TryPower(-2, 3));
        O.Observe('power_2_1000', TryPower(2, 1000));
        O.Observe('power_1_1_5', TryPower(1.5, 1.5));
        O.Expect('round_1_5_prec_0', '1.5');
        O.Expect('round_2_5_prec_1', '3');
        O.Expect('round_minus_2_5_prec_1', '-3');
        O.Expect('round_1234_prec_100', '1,200');
        O.Expect('round_3_14159_001', '3.14');
        O.Expect('round_up_3_141', '3.15');
        O.Expect('round_down_3_149', '3.14');
        O.Expect('round_nearest_explicit', '3');
        O.Expect('round_prec_neg', 'ERR:The value of ROUND parameter 2 is outside of the permitted range. The current value is: 1. The permitted range is: from 1 to 2,147,483,647./OutsidePermittedRange');
        O.Expect('round_prec_zero', 'ERR:The value of ROUND parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647./OutsidePermittedRange');
        O.Expect('round_prec_tiny', '1.5');
        O.Expect('power_2_0_5', '1.4142135623731');
        O.Expect('power_2_10', '1024');
        O.Expect('power_2_neg2', '0.25');
        O.Expect('power_2_100', 'ERR:Value was either too large or too small for a Decimal./AL:Overflow');
        O.Expect('power_3_0_333', '1.44224951749164');
        O.Expect('power_0_0', '1');
        O.Expect('power_0_neg1', 'ERR:Value was either too large or too small for a Decimal./AL:Overflow');
        O.Expect('power_neg2_0_5', 'ERR:Value was either too large or too small for a Decimal./AL:Overflow');
        O.Expect('power_neg2_3', '-8');
        O.Expect('power_2_1000', 'ERR:Value was either too large or too small for a Decimal./AL:Overflow');
        O.Expect('power_1_1_5', '1.83711730708738');
        O.Verify();
    end;

    local procedure TryRound(V: Decimal; P: Decimal): Text
    var
        R: Decimal;
    begin
        if TryRoundF(V, P, R) then
            exit(Format(R, 0, 9));
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRoundF(V: Decimal; P: Decimal; var R: Decimal)
    begin
        R := Round(V, P);
    end;

    local procedure TryPower(B: Decimal; E: Decimal): Text
    var
        R: Decimal;
    begin
        if TryPowerF(B, E, R) then
            exit(Format(R, 0, 9));
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryPowerF(B: Decimal; E: Decimal; var R: Decimal)
    begin
        R := Power(B, E);
    end;

    [Test]
    procedure Guid_EvaluateAndFormat()
    var
        O: Codeunit "Probe Observer";
        Texts: List of [Text];
        T: Text;
        G: Guid;
    begin
        Texts.Add('{ABCDEF01-2345-6789-ABCD-EF0123456789}');
        Texts.Add('abcdef01-2345-6789-abcd-ef0123456789');
        Texts.Add('ABCDEF0123456789ABCDEF0123456789');
        Texts.Add('{abcdef01-2345-6789-abcd-ef0123456789');
        Texts.Add('(abcdef01-2345-6789-abcd-ef0123456789)');
        Texts.Add('abcdef01-2345-6789-abcd-ef012345678');
        Texts.Add('nonsense');
        Texts.Add('');
        Texts.Add('{00000000-0000-0000-0000-000000000000}');
        foreach T in Texts do begin
            Clear(G);
            if Evaluate(G, T) then
                O.Observe('guid_eval_[' + T + ']', 'ok:' + Format(G) + ' null=' + Format(IsNullGuid(G)))
            else
                O.Observe('guid_eval_[' + T + ']', 'fail');
        end;
        O.Expect('guid_eval_[{ABCDEF01-2345-6789-ABCD-EF0123456789}]', 'ok:{ABCDEF01-2345-6789-ABCD-EF0123456789} null=No');
        O.Expect('guid_eval_[abcdef01-2345-6789-abcd-ef0123456789]', 'ok:{ABCDEF01-2345-6789-ABCD-EF0123456789} null=No');
        O.Expect('guid_eval_[ABCDEF0123456789ABCDEF0123456789]', 'ok:{ABCDEF01-2345-6789-ABCD-EF0123456789} null=No');
        O.Expect('guid_eval_[{abcdef01-2345-6789-abcd-ef0123456789]', 'fail');
        O.Expect('guid_eval_[(abcdef01-2345-6789-abcd-ef0123456789)]', 'ok:{ABCDEF01-2345-6789-ABCD-EF0123456789} null=No');
        O.Expect('guid_eval_[abcdef01-2345-6789-abcd-ef012345678]', 'fail');
        O.Expect('guid_eval_[nonsense]', 'fail');
        O.Expect('guid_eval_[]', 'fail');
        O.Expect('guid_eval_[{00000000-0000-0000-0000-000000000000}]', 'ok:{00000000-0000-0000-0000-000000000000} null=Yes');
        O.Verify();
    end;

    [Test]
    procedure Guid_EvaluateStatementError()
    var
        O: Codeunit "Probe Observer";
        G: Guid;
        T: Text;
    begin
        T := 'nonsense';
        asserterror Evaluate(G, T);
        O.ObserveError('guid_nonsense');
        O.Expect('guid_nonsense|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        O.Expect('guid_nonsense|code', 'InvalidGuidFormat');
        O.Verify();
    end;

    [Test]
    procedure Guid_CreateGuidShape()
    var
        O: Codeunit "Probe Observer";
        G: Guid;
        T: Text;
    begin
        G := CreateGuid();
        T := Format(G);
        O.Observe('length', Format(StrLen(T)));
        O.Observe('first_char', CopyStr(T, 1, 1));
        O.Observe('last_char', CopyStr(T, StrLen(T), 1));
        O.Observe('dash_positions', Format(StrPos(T, '-')) + ',' + Format(StrLen(T)));
        O.Observe('is_upper', Format(T = UpperCase(T)));
        O.Observe('format_nobrace_len', Format(StrLen(DelChr(T, '=', '{}'))));
        O.Expect('length', '38');
        O.Expect('first_char', '{');
        O.Expect('last_char', '}');
        O.Expect('dash_positions', '10,38');
        O.Expect('is_upper', 'Yes');
        O.Expect('format_nobrace_len', '36');
        O.Verify();
    end;

    [Test]
    procedure Random_RangesAndSeed()
    var
        O: Codeunit "Probe Observer";
        i: Integer;
        S: Text;
    begin
        Randomize(42);
        for i := 1 to 8 do
            S += Format(Random(100)) + ',';
        O.Observe('seed42_random100_x8', S);
        Randomize(42);
        S := '';
        for i := 1 to 8 do
            S += Format(Random(100)) + ',';
        O.Observe('seed42_again', S);
        Randomize(1);
        S := '';
        for i := 1 to 8 do
            S += Format(Random(1000000)) + ',';
        O.Observe('seed1_random1000000_x8', S);
        Randomize(0);
        S := '';
        for i := 1 to 5 do
            S += Format(Random(10)) + ',';
        O.Observe('seed0_random10_x5', S);
        Randomize(-5);
        S := '';
        for i := 1 to 5 do
            S += Format(Random(10)) + ',';
        O.Observe('seedminus5_random10_x5', S);
        Randomize(42);
        O.Observe('seed42_random1', Format(Random(1)));
        Randomize(42);
        O.Observe('seed42_random0', Format(Random(0)));
        Randomize(42);
        O.Observe('seed42_random_minus100', Format(Random(-100)));
        Randomize(42);
        O.Observe('seed42_random_max', Format(Random(2147483647)));
        O.Expect('seed42_random100_x8', '67,15,13,53,17,27,73,52,');
        O.Expect('seed42_again', '67,15,13,53,17,27,73,52,');
        O.Expect('seed1_random1000000_x8', '248669,110744,467011,771605,657519,432783,354084,943863,');
        O.Expect('seed0_random10_x5', '8,9,8,6,3,');
        O.Expect('seedminus5_random10_x5', '4,3,3,7,5,');
        O.Expect('seed42_random1', '1');
        O.Expect('seed42_random0', '1');
        O.Expect('seed42_random_minus100', '67');
        O.Expect('seed42_random_max', '1434747711');
        O.Verify();
    end;

    [Test]
    procedure Random_MinIntError()
    var
        O: Codeunit "Probe Observer";
        R: Integer;
        N: Integer;
    begin
        N := -2147483647 - 1;
        asserterror R := Random(N);
        O.ObserveError('random_minint');
        O.Expect('random_minint|text', 'Arithmetic operation resulted in an overflow.');
        O.Expect('random_minint|code', 'AL:Overflow');
        O.Verify();
    end;

    [Test]
    procedure Random_NoSeedRange()
    var
        O: Codeunit "Probe Observer";
        i: Integer;
        Mn: Integer;
        Mx: Integer;
        V: Integer;
    begin
        Randomize();
        Mn := 1000;
        Mx := 0;
        for i := 1 to 200 do begin
            V := Random(6);
            if V < Mn then
                Mn := V;
            if V > Mx then
                Mx := V;
        end;
        O.Observe('randomize_noarg_min_of_200', Format(Mn));
        O.Observe('randomize_noarg_max_of_200', Format(Mx));
        O.Expect('randomize_noarg_min_of_200', '1');
        O.Expect('randomize_noarg_max_of_200', '6');
        O.Verify();
    end;

    [Test]
    procedure TextChar_AssignByIndex()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('replace_inside', TryCharAssign('abc', 2, 'X'));
        O.Observe('append_at_len_plus_1', TryCharAssign('abc', 4, 'X'));
        O.Observe('at_len_plus_2', TryCharAssign('abc', 5, 'X'));
        O.Observe('index_0', TryCharAssign('abc', 0, 'X'));
        O.Observe('index_minus1', TryCharAssign('abc', -1, 'X'));
        O.Observe('empty_text_index_1', TryCharAssign('', 1, 'X'));
        O.Observe('read_len_plus_1', TryCharRead('abc', 4));
        O.Observe('read_index_0', TryCharRead('abc', 0));
        O.Observe('read_inside', TryCharRead('abc', 2));
        O.Observe('assign_past_declared_length_3', TryCharAssignCap(3));
        O.Expect('replace_inside', '[aXc]');
        O.Expect('append_at_len_plus_1', '[abcX]');
        O.Expect('at_len_plus_2', 'ERR:The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 5. The permitted range is: from 1 to 3./OutsidePermittedRange');
        O.Expect('index_0', 'ERR:The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 3./OutsidePermittedRange');
        O.Expect('index_minus1', 'ERR:The value of INDEXING parameter 1 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 3./OutsidePermittedRange');
        O.Expect('empty_text_index_1', '[X]');
        O.Expect('read_len_plus_1', '\u0000');
        O.Expect('read_index_0', 'ERR:The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647./OutsidePermittedRange');
        O.Expect('read_inside', 'b');
        O.Expect('assign_past_declared_length_3', 'ERR:The length of the string is 4, but it must be less than or equal to 3 characters. Value: abcX/StringLengthExceeded');
        O.Verify();
    end;

    local procedure TryCharAssign(Src: Text; Idx: Integer; C: Char): Text
    var
        T: Text;
        Res: Text;
    begin
        T := Src;
        if TryCharAssignF(T, Idx, C) then
            exit('[' + T + ']');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryCharAssignF(var T: Text; Idx: Integer; C: Char)
    begin
        T[Idx] := C;
    end;

    local procedure TryCharRead(Src: Text; Idx: Integer): Text
    var
        C: Char;
    begin
        if TryCharReadF(Src, Idx, C) then
            exit(Format(C));
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryCharReadF(Src: Text; Idx: Integer; var C: Char)
    begin
        C := Src[Idx];
    end;

    local procedure TryCharAssignCap(Cap: Integer): Text
    var
        T3: Text[3];
    begin
        T3 := 'abc';
        if TryCharAssign3(T3) then
            exit('[' + T3 + ']');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryCharAssign3(var T3: Text[3])
    begin
        T3[4] := 'X';
    end;

    [Test]
    procedure TextChar_AssignIntoCode()
    var
        O: Codeunit "Probe Observer";
        C: Code[5];
    begin
        C := 'abc';
        C[2] := 'x';
        O.Observe('code_index_assign', '[' + C + ']');
        O.Expect('code_index_assign', '[AXC]');
        O.Verify();
    end;
}
