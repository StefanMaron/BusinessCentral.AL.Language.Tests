// Observe-only probes (writer A). Rows: Format milliseconds/standard numbers, Trim, text edge functions, DelChr,
// time zone of CreateDateTime, closing dates, Date2DWY, CalcDate, DateFormula Evaluate, Format strings, Option format.
table 69802 "PA Fmt Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = Alpha,Beta,Gamma; OptionCaption = 'First,Second,Third'; }
        field(3; OptNoCaption; Option) { OptionMembers = Xx,Yy; }
        field(4; Dec; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 69804 "PA Text Date Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Try(Op: Integer; A: Text; B: Text; N1: Integer; N2: Integer): Text
    var
        R: Text;
    begin
        if TryF(Op, A, B, N1, N2, R) then
            exit('[' + R + ']');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryF(Op: Integer; A: Text; B: Text; N1: Integer; N2: Integer; var R: Text)
    var
        TB: TextBuilder;
        I: Integer;
    begin
        case Op of
            1:
                R := A.Substring(N1);
            2:
                R := A.Substring(N1, N2);
            3:
                R := DelStr(A, N1);
            4:
                R := DelStr(A, N1, N2);
            5:
                R := InsStr(A, B, N1);
            6:
                R := IncStr(A);
            7:
                R := ConvertStr(A, B, '12345678'.Substring(1, StrLen(B)));
            8:
                R := Format(A.IndexOf(B, N1));
            9:
                R := Format(A.LastIndexOf(B, N1));
            10:
                R := Format(A.LastIndexOf(B));
            11:
                begin
                    TB.Append(A);
                    TB.Insert(N1, B);
                    R := TB.ToText();
                end;
            12:
                begin
                    TB.Append(A);
                    TB.Remove(N1, N2);
                    R := TB.ToText();
                end;
            13:
                begin
                    TB.Append(A);
                    TB.Replace(B, '#');
                    R := TB.ToText();
                end;
            14:
                R := CopyStr(A, N1, N2);
            15:
                R := Format(StrPos(A, B));
            16:
                R := A.Substring(N1, N2);
            17:
                R := Format(A.Contains(B));
            18:
                R := Format(A.StartsWith(B));
            19:
                R := Format(A.EndsWith(B));
            20:
                R := A.PadLeft(N1, 'x').PadRight(N1 + 2, 'y');
        end;
    end;

    [Test]
    procedure Text_SubstringBounds()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('substring_0', Try(1, 'abcdef', '', 0, 0));
        O.Observe('substring_neg', Try(1, 'abcdef', '', -1, 0));
        O.Observe('substring_1', Try(1, 'abcdef', '', 1, 0));
        O.Observe('substring_len_plus_1', Try(1, 'abcdef', '', 7, 0));
        O.Observe('substring_len_plus_2', Try(1, 'abcdef', '', 8, 0));
        O.Observe('substring_2_neg_count', Try(2, 'abcdef', '', 2, -1));
        O.Observe('substring_2_zero_count', Try(2, 'abcdef', '', 2, 0));
        O.Observe('substring_2_past_end', Try(2, 'abcdef', '', 4, 10));
        O.Observe('substring_start0_count2', Try(2, 'abcdef', '', 0, 2));
        O.Observe('copystr_start0', Try(14, 'abcdef', '', 0, 2));
        O.Observe('copystr_start_past_end', Try(14, 'abcdef', '', 9, 2));
        O.Observe('copystr_neg_count', Try(14, 'abcdef', '', 2, -1));
        O.Expect('substring_0', 'ERR:startIndex (''-1'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -1./ArgumentOutOfRange');
        O.Expect('substring_neg', 'ERR:startIndex (''-2'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -2./ArgumentOutOfRange');
        O.Expect('substring_1', '[abcdef]');
        O.Expect('substring_len_plus_1', '[]');
        O.Expect('substring_len_plus_2', 'ERR:startIndex cannot be larger than length of string. (Parameter ''startIndex'')/ArgumentOutOfRange');
        O.Expect('substring_2_neg_count', 'ERR:length (''-1'') must be a non-negative value. (Parameter ''length'')\Actual value was -1./ArgumentOutOfRange');
        O.Expect('substring_2_zero_count', '[]');
        O.Expect('substring_2_past_end', '[def]');
        O.Expect('substring_start0_count2', 'ERR:startIndex (''-1'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -1./ArgumentOutOfRange');
        O.Expect('copystr_start0', 'ERR:The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647./OutsidePermittedRange');
        O.Expect('copystr_start_past_end', '[]');
        O.Expect('copystr_neg_count', 'ERR:The value of COPYSTR parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 0 to 2,147,483,647./OutsidePermittedRange');
        O.Verify();
    end;

    [Test]
    procedure Text_DelStrInsStr()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('delstr_pos0', Try(3, 'abcdef', '', 0, 0));
        O.Observe('delstr_pos0_len2', Try(4, 'abcdef', '', 0, 2));
        O.Observe('delstr_neg_pos', Try(4, 'abcdef', '', -2, 2));
        O.Observe('delstr_pos3_len_past_end', Try(4, 'abcdef', '', 3, 100));
        O.Observe('delstr_pos3_len_neg', Try(4, 'abcdef', '', 3, -1));
        O.Observe('delstr_pos_past_end', Try(4, 'abcdef', '', 9, 2));
        O.Observe('delstr_pos_len_plus_1', Try(4, 'abcdef', '', 7, 2));
        O.Observe('delstr_no_len', Try(3, 'abcdef', '', 3, 0));
        O.Observe('insstr_pos0', Try(5, 'abcdef', 'XY', 0, 0));
        O.Observe('insstr_neg', Try(5, 'abcdef', 'XY', -1, 0));
        O.Observe('insstr_pos1', Try(5, 'abcdef', 'XY', 1, 0));
        O.Observe('insstr_pos_len_plus_1', Try(5, 'abcdef', 'XY', 7, 0));
        O.Observe('insstr_pos_past_end', Try(5, 'abcdef', 'XY', 10, 0));
        O.Expect('delstr_pos0', 'ERR:The value of DELSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2048./OutsidePermittedRange');
        O.Expect('delstr_pos0_len2', 'ERR:The value of DELSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647./OutsidePermittedRange');
        O.Expect('delstr_neg_pos', 'ERR:The value of DELSTR parameter 2 is outside of the permitted range. The current value is: -2. The permitted range is: from 1 to 2,147,483,647./OutsidePermittedRange');
        O.Expect('delstr_pos3_len_past_end', '[ab]');
        O.Expect('delstr_pos3_len_neg', 'ERR:The value of DELSTR parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 0 to 2,147,483,647./OutsidePermittedRange');
        O.Expect('delstr_pos_past_end', '[abcdef]');
        O.Expect('delstr_pos_len_plus_1', '[abcdef]');
        O.Expect('delstr_no_len', '[ab]');
        O.Expect('insstr_pos0', 'ERR:The value of INSSTR parameter 3 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647./OutsidePermittedRange');
        O.Expect('insstr_neg', 'ERR:The value of INSSTR parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 2,147,483,647./OutsidePermittedRange');
        O.Expect('insstr_pos1', '[XYabcdef]');
        O.Expect('insstr_pos_len_plus_1', '[abcdefXY]');
        O.Expect('insstr_pos_past_end', '[abcdefXY]');
        O.Verify();
    end;

    [Test]
    procedure Text_IncStrAndConvertStr()
    var
        O: Codeunit "Probe Observer";
        Tx: Text;
    begin
        O.Observe('incstr_A1', Try(6, 'A1', '', 0, 0));
        O.Observe('incstr_A9', Try(6, 'A9', '', 0, 0));
        O.Observe('incstr_A99', Try(6, 'A99', '', 0, 0));
        O.Observe('incstr_A099', Try(6, 'A099', '', 0, 0));
        O.Observe('incstr_empty', Try(6, '', '', 0, 0));
        O.Observe('incstr_no_digits', Try(6, 'ABC', '', 0, 0));
        O.Observe('incstr_digits_then_text', Try(6, '12AB', '', 0, 0));
        O.Observe('incstr_9', Try(6, '9', '', 0, 0));
        O.Observe('incstr_with_increment_2', IncStrBy('A1', 2));
        O.Observe('incstr_with_increment_neg', IncStrBy('A5', -2));
        O.Observe('incstr_with_increment_zero', IncStrBy('A5', 0));
        O.Observe('convertstr_abc', Try(7, 'abc', 'ab', 0, 0));
        O.Observe('convertstr_empty_from', Try(7, 'abc', '', 0, 0));
        O.Expect('incstr_A1', '[A2]');
        O.Expect('incstr_A9', '[A10]');
        O.Expect('incstr_A99', '[A100]');
        O.Expect('incstr_A099', '[A100]');
        O.Expect('incstr_empty', '[]');
        O.Expect('incstr_no_digits', '[]');
        O.Expect('incstr_digits_then_text', '[13AB]');
        O.Expect('incstr_9', '[10]');
        O.Expect('incstr_with_increment_2', '[A3]');
        O.Expect('incstr_with_increment_neg', '[A3]');
        O.Expect('incstr_with_increment_zero', '[A5]');
        O.Expect('convertstr_abc', '[12c]');
        O.Expect('convertstr_empty_from', '[abc]');
        O.Verify();
    end;

    local procedure IncStrBy(T: Text; By: Integer): Text
    var
        R: Text;
    begin
        if TryIncBy(T, By, R) then
            exit('[' + R + ']');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryIncBy(T: Text; By: Integer; var R: Text)
    begin
        R := IncStr(T, By);
    end;

    [Test]
    procedure Text_IndexOfAndTextBuilderEdges()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('indexof_empty_start1', Try(8, 'abc', '', 1, 0));
        O.Observe('indexof_empty_start2', Try(8, 'abc', '', 2, 0));
        O.Observe('indexof_empty_start_len_plus_1', Try(8, 'abc', '', 4, 0));
        O.Observe('indexof_empty_start_0', Try(8, 'abc', '', 0, 0));
        O.Observe('indexof_b_start_0', Try(8, 'abc', 'b', 0, 0));
        O.Observe('indexof_b_start_5', Try(8, 'abc', 'b', 5, 0));
        O.Observe('indexof_b_start_neg', Try(8, 'abc', 'b', -1, 0));
        O.Observe('lastindexof_empty', Try(10, 'abc', '', 0, 0));
        O.Observe('lastindexof_empty_start3', Try(9, 'abc', '', 3, 0));
        O.Observe('lastindexof_b_start2', Try(9, 'abcb', 'b', 2, 0));
        O.Observe('lastindexof_b_start_0', Try(9, 'abcb', 'b', 0, 0));
        O.Observe('lastindexof_b_start_past_end', Try(9, 'abcb', 'b', 9, 0));
        O.Observe('lastindexof_b_start_neg', Try(9, 'abcb', 'b', -1, 0));
        O.Observe('textbuilder_insert_at_0', Try(11, 'abc', 'X', 0, 0));
        O.Observe('textbuilder_insert_at_len_plus_1', Try(11, 'abc', 'X', 4, 0));
        O.Observe('textbuilder_insert_at_len_plus_2', Try(11, 'abc', 'X', 5, 0));
        O.Observe('textbuilder_insert_at_1', Try(11, 'abc', 'X', 1, 0));
        O.Observe('textbuilder_remove_0_1', Try(12, 'abc', '', 0, 1));
        O.Observe('textbuilder_remove_1_5', Try(12, 'abc', '', 1, 5));
        O.Observe('textbuilder_remove_2_1', Try(12, 'abc', '', 2, 1));
        O.Observe('textbuilder_remove_4_1', Try(12, 'abc', '', 4, 1));
        O.Observe('textbuilder_replace_empty_old', Try(13, 'abc', '', 0, 0));
        O.Observe('textbuilder_replace_b', Try(13, 'abc', 'b', 0, 0));
        O.Observe('strpos_empty', Try(15, 'abc', '', 0, 0));
        O.Observe('contains_empty', Try(17, 'abc', '', 0, 0));
        O.Observe('startswith_empty', Try(18, 'abc', '', 0, 0));
        O.Observe('endswith_empty', Try(19, 'abc', '', 0, 0));
        O.Observe('padleft_n5', Try(20, 'ab', '', 5, 0));
        O.Observe('padleft_n1_shorter', Try(20, 'abcdef', '', 1, 0));
        O.Expect('indexof_empty_start1', '[1]');
        O.Expect('indexof_empty_start2', '[2]');
        O.Expect('indexof_empty_start_len_plus_1', '[4]');
        O.Expect('indexof_empty_start_0', 'ERR:Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')/ArgumentOutOfRange');
        O.Expect('indexof_b_start_0', 'ERR:Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')/ArgumentOutOfRange');
        O.Expect('indexof_b_start_5', 'ERR:Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')/ArgumentOutOfRange');
        O.Expect('indexof_b_start_neg', 'ERR:Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')/ArgumentOutOfRange');
        O.Expect('lastindexof_empty', '[4]');
        O.Expect('lastindexof_empty_start3', '[4]');
        O.Expect('lastindexof_b_start2', '[2]');
        O.Expect('lastindexof_b_start_0', 'ERR:Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')/ArgumentOutOfRange');
        O.Expect('lastindexof_b_start_past_end', 'ERR:Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')/ArgumentOutOfRange');
        O.Expect('lastindexof_b_start_neg', 'ERR:Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')/ArgumentOutOfRange');
        O.Expect('textbuilder_insert_at_0', 'ERR:An invalid argument was passed to a ''TextBuilder'' data type method./ArgumentOutOfRange');
        O.Expect('textbuilder_insert_at_len_plus_1', '[abcX]');
        O.Expect('textbuilder_insert_at_len_plus_2', 'ERR:An invalid argument was passed to a ''TextBuilder'' data type method./ArgumentOutOfRange');
        O.Expect('textbuilder_insert_at_1', '[Xabc]');
        O.Expect('textbuilder_remove_0_1', 'ERR:An invalid argument was passed to a ''TextBuilder'' data type method./ArgumentOutOfRange');
        O.Expect('textbuilder_remove_1_5', 'ERR:An invalid argument was passed to a ''TextBuilder'' data type method./ArgumentOutOfRange');
        O.Expect('textbuilder_remove_2_1', '[ac]');
        O.Expect('textbuilder_remove_4_1', 'ERR:An invalid argument was passed to a ''TextBuilder'' data type method./ArgumentOutOfRange');
        O.Expect('textbuilder_replace_empty_old', 'ERR:An invalid argument was passed to a ''TextBuilder'' data type method./Argument');
        O.Expect('textbuilder_replace_b', '[a#c]');
        O.Expect('strpos_empty', '[0]');
        O.Expect('contains_empty', '[Yes]');
        O.Expect('startswith_empty', '[Yes]');
        O.Expect('endswith_empty', '[Yes]');
        O.Expect('padleft_n5', '[xxxabyy]');
        O.Expect('padleft_n1_shorter', '[abcdef]');
        O.Verify();
    end;





    [Test]
    procedure Text_TrimUnicodeWhiteSpace()
    var
        O: Codeunit "Probe Observer";
        Ws: Text;
        T: Text;
        i: Integer;
        Codes: List of [Integer];
        Cd: Integer;
    begin
        Codes.Add(9);
        Codes.Add(10);
        Codes.Add(11);
        Codes.Add(12);
        Codes.Add(13);
        Codes.Add(32);
        Codes.Add(133);
        Codes.Add(160);
        Codes.Add(5760);
        Codes.Add(8192);
        Codes.Add(8195);
        Codes.Add(8203);
        Codes.Add(8232);
        Codes.Add(8233);
        Codes.Add(8239);
        Codes.Add(12288);
        Codes.Add(65279);
        foreach Cd in Codes do begin
            Ws := '';
            Ws[1] := Cd;
            T := Ws + 'x' + Ws;
            O.Observe('trim_code_' + Format(Cd), Format(StrLen(T.Trim())) + ',' + Format(StrLen(T.TrimStart())) + ',' + Format(StrLen(T.TrimEnd())) + ' of ' + Format(StrLen(T)));
        end;
        O.Expect('trim_code_9', '1,2,2 of 3');
        O.Expect('trim_code_10', '1,2,2 of 3');
        O.Expect('trim_code_11', '1,2,2 of 3');
        O.Expect('trim_code_12', '1,2,2 of 3');
        O.Expect('trim_code_13', '1,2,2 of 3');
        O.Expect('trim_code_32', '1,2,2 of 3');
        O.Expect('trim_code_133', '1,2,2 of 3');
        O.Expect('trim_code_160', '1,2,2 of 3');
        O.Expect('trim_code_5760', '1,2,2 of 3');
        O.Expect('trim_code_8192', '1,2,2 of 3');
        O.Expect('trim_code_8195', '1,2,2 of 3');
        O.Expect('trim_code_8203', '3,3,3 of 3');
        O.Expect('trim_code_8232', '1,2,2 of 3');
        O.Expect('trim_code_8233', '1,2,2 of 3');
        O.Expect('trim_code_8239', '1,2,2 of 3');
        O.Expect('trim_code_12288', '1,2,2 of 3');
        O.Expect('trim_code_65279', '3,3,3 of 3');
        O.Verify();
    end;

    [Test]
    procedure Text_TrimWithCharacterSet()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('trimstart_xy', 'xxayyxbx'.TrimStart('xy'));
        O.Observe('trimend_xy', 'xxayyxbx'.TrimEnd('xy'));
        O.Observe('trimstart_set_case_sensitive', 'XxaxX'.TrimStart('x'));
        O.Observe('trimend_set_case_sensitive', 'XxaxX'.TrimEnd('x'));
        O.Observe('trimstart_empty_set', '  a  '.TrimStart(''));
        O.Observe('trimend_all_chars', 'xxx'.TrimEnd('x') + '|');
        O.Observe('trimstart_set_no_space', '  a  '.TrimStart('x'));
        O.Observe('trimstart_space_in_set', '  a  '.TrimStart(' '));
        O.Expect('trimstart_xy', 'ayyxbx');
        O.Expect('trimend_xy', 'xxayyxb');
        O.Expect('trimstart_set_case_sensitive', 'XxaxX');
        O.Expect('trimend_set_case_sensitive', 'XxaxX');
        O.Expect('trimstart_empty_set', 'a  ');
        O.Expect('trimend_all_chars', '|');
        O.Expect('trimstart_set_no_space', '  a  ');
        O.Expect('trimstart_space_in_set', 'a  ');
        O.Verify();
    end;

    [Test]
    procedure Text_DelChrForms()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('delchr_no_which', '[' + DelChr('  a b  ') + ']');
        O.Observe('delchr_which_empty_chars', '[' + DelChr('  a b  ', '=') + ']');
        O.Observe('delchr_lead', '[' + DelChr('  a b  ', '<') + ']');
        O.Observe('delchr_trail', '[' + DelChr('  a b  ', '>') + ']');
        O.Observe('delchr_all_spaces', '[' + DelChr('  a b  ', '=', ' ') + ']');
        O.Observe('delchr_both_x', '[' + DelChr('xxaxbxx', '<>', 'x') + ']');
        O.Observe('delchr_case', '[' + DelChr('XxaXx', '=', 'x') + ']');
        O.Observe('delchr_chars_no_which_char_arg', '[' + DelChr('  a b  ', '=', ' a') + ']');
        O.Expect('delchr_no_which', '[ab]');
        O.Expect('delchr_which_empty_chars', '[ab]');
        O.Expect('delchr_lead', '[a b  ]');
        O.Expect('delchr_trail', '[  a b]');
        O.Expect('delchr_all_spaces', '[ab]');
        O.Expect('delchr_both_x', '[axb]');
        O.Expect('delchr_case', '[XaX]');
        O.Expect('delchr_chars_no_which_char_arg', '[b]');
        O.Verify();
    end;

    [Test]
    procedure Format_MillisecondsTimeDateTimeDuration()
    var
        O: Codeunit "Probe Observer";
        T: Time;
        Dt: DateTime;
        Du: Duration;
    begin
        T := 120000T + 7;
        O.Observe('time_7ms_f9', Format(T, 0, 9));
        O.Observe('time_7ms_f2', Format(T, 0, 2));
        O.Observe('time_7ms_f0', Format(T, 0, 0));
        T := 120000T;
        O.Observe('time_0ms_f9', Format(T, 0, 9));
        O.Observe('time_0ms_f2', Format(T, 0, 2));
        T := 120000T + 120;
        O.Observe('time_120ms_f9', Format(T, 0, 9));
        T := 120000T + 500;
        O.Observe('time_500ms_f9', Format(T, 0, 9));
        Dt := CreateDateTime(DMY2Date(15, 1, 2024), 120000T + 7);
        O.Observe('dt_7ms_f9', Format(Dt, 0, 9));
        O.Observe('dt_7ms_f0', Format(Dt, 0, 0));
        Dt := CreateDateTime(DMY2Date(15, 1, 2024), 120000T + 500);
        O.Observe('dt_500ms_f9', Format(Dt, 0, 9));
        Dt := CreateDateTime(DMY2Date(15, 1, 2024), 120000T);
        O.Observe('dt_0ms_f9', Format(Dt, 0, 9));
        Du := 1500;
        O.Observe('dur_1500_f9', Format(Du, 0, 9));
        Du := 12;
        O.Observe('dur_12_f9', Format(Du, 0, 9));
        Du := 1;
        O.Observe('dur_1_f9', Format(Du, 0, 9));
        Du := 999;
        O.Observe('dur_999_f9', Format(Du, 0, 9));
        Du := 5;
        O.Observe('dur_5_f9', Format(Du, 0, 9));
        Du := 100;
        O.Observe('dur_100_f9', Format(Du, 0, 9));
        Du := 1000;
        O.Observe('dur_1000_f9', Format(Du, 0, 9));
        Du := 60000;
        O.Observe('dur_60000_f9', Format(Du, 0, 9));
        Du := 90061001;
        O.Observe('dur_1d1h1m1s1ms_f9', Format(Du, 0, 9));
        O.Expect('time_7ms_f9', '12:00:00.007');
        O.Expect('time_7ms_f2', '120000.007T');
        O.Expect('time_7ms_f0', '12:00:00 PM');
        O.Expect('time_0ms_f9', '12:00:00');
        O.Expect('time_0ms_f2', '120000T');
        O.Expect('time_120ms_f9', '12:00:00.12');
        O.Expect('time_500ms_f9', '12:00:00.5');
        O.Expect('dt_7ms_f9', '2024-01-15T12:00:00.007Z');
        O.Expect('dt_7ms_f0', '01/15/24 12:00 PM');
        O.Expect('dt_500ms_f9', '2024-01-15T12:00:00.5Z');
        O.Expect('dt_0ms_f9', '2024-01-15T12:00:00Z');
        O.Expect('dur_1500_f9', 'P0DT0H0M1.5S');
        O.Expect('dur_12_f9', 'P0DT0H0M0.012S');
        O.Expect('dur_1_f9', 'P0DT0H0M0.001S');
        O.Expect('dur_999_f9', 'P0DT0H0M0.999S');
        O.Expect('dur_5_f9', 'P0DT0H0M0.005S');
        O.Expect('dur_100_f9', 'P0DT0H0M0.1S');
        O.Expect('dur_1000_f9', 'P0DT0H0M1.0S');
        O.Expect('dur_60000_f9', 'P0DT0H1M0.0S');
        O.Expect('dur_1d1h1m1s1ms_f9', 'P1DT1H1M1.001S');
        O.Verify();
    end;

    [Test]
    procedure Format_StandardNumbers_Time()
    var
        O: Codeunit "Probe Observer";
        T: Time;
        i: Integer;
    begin
        T := 134509T + 7;
        for i := 0 to 10 do
            O.Observe('time_fmt_' + Format(i), FmtTime(T, i));
        T := 134509T;
        for i := 0 to 10 do
            O.Observe('time_0ms_fmt_' + Format(i), FmtTime(T, i));
        O.Expect('time_fmt_0', '[ 1:45:09 PM]');
        O.Expect('time_fmt_1', '[ 1:45:09.007 PM]');
        O.Expect('time_fmt_2', '[134509.007T]');
        O.Expect('time_fmt_3', 'ERR:Standard format number 3 does not exist for the type ''Time''./InvalidStandardFormat');
        O.Expect('time_fmt_4', 'ERR:Standard format number 4 does not exist for the type ''Time''./InvalidStandardFormat');
        O.Expect('time_fmt_5', 'ERR:Standard format number 5 does not exist for the type ''Time''./InvalidStandardFormat');
        O.Expect('time_fmt_6', 'ERR:Standard format number 6 does not exist for the type ''Time''./InvalidStandardFormat');
        O.Expect('time_fmt_7', 'ERR:Standard format number 7 does not exist for the type ''Time''./InvalidStandardFormat');
        O.Expect('time_fmt_8', 'ERR:Standard format number 8 does not exist for the type ''Time''./InvalidStandardFormat');
        O.Expect('time_fmt_9', '[13:45:09.007]');
        O.Expect('time_fmt_10', 'ERR:Standard format number 10 does not exist for the type ''Time''./InvalidStandardFormat');
        O.Expect('time_0ms_fmt_0', '[ 1:45:09 PM]');
        O.Expect('time_0ms_fmt_1', '[ 1:45:09 PM]');
        O.Expect('time_0ms_fmt_2', '[134509T]');
        O.Expect('time_0ms_fmt_3', 'ERR:Standard format number 3 does not exist for the type ''Time''./InvalidStandardFormat');
        O.Expect('time_0ms_fmt_4', 'ERR:Standard format number 4 does not exist for the type ''Time''./InvalidStandardFormat');
        O.Expect('time_0ms_fmt_5', 'ERR:Standard format number 5 does not exist for the type ''Time''./InvalidStandardFormat');
        O.Expect('time_0ms_fmt_6', 'ERR:Standard format number 6 does not exist for the type ''Time''./InvalidStandardFormat');
        O.Expect('time_0ms_fmt_7', 'ERR:Standard format number 7 does not exist for the type ''Time''./InvalidStandardFormat');
        O.Expect('time_0ms_fmt_8', 'ERR:Standard format number 8 does not exist for the type ''Time''./InvalidStandardFormat');
        O.Expect('time_0ms_fmt_9', '[13:45:09]');
        O.Expect('time_0ms_fmt_10', 'ERR:Standard format number 10 does not exist for the type ''Time''./InvalidStandardFormat');
        O.Verify();
    end;

    local procedure FmtTime(T: Time; N: Integer): Text
    var
        R: Text;
    begin
        if FmtTimeF(T, N, R) then
            exit('[' + R + ']');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure FmtTimeF(T: Time; N: Integer; var R: Text)
    begin
        R := Format(T, 0, N);
    end;

    [Test]
    procedure Format_StandardNumbers_DateTime()
    var
        O: Codeunit "Probe Observer";
        Dt: DateTime;
        i: Integer;
    begin
        Dt := CreateDateTime(DMY2Date(5, 3, 2024), 134509T + 7);
        for i := 0 to 10 do
            O.Observe('dt_fmt_' + Format(i), FmtDt(Dt, i));
        Dt := CreateDateTime(DMY2Date(5, 3, 2024), 134509T);
        for i := 0 to 10 do
            O.Observe('dt_0ms_fmt_' + Format(i), FmtDt(Dt, i));
        O.Expect('dt_fmt_0', '[03/05/24 01:45 PM]');
        O.Expect('dt_fmt_1', '[03/05/24 01:45:09.007 PM]');
        O.Expect('dt_fmt_2', '[03/05/24 01:45 PM]');
        O.Expect('dt_fmt_3', '[03/05/24 01:45:09 PM]');
        O.Expect('dt_fmt_4', 'ERR:Standard format number 4 does not exist for the type ''DateTime''./InvalidStandardFormat');
        O.Expect('dt_fmt_5', 'ERR:Standard format number 5 does not exist for the type ''DateTime''./InvalidStandardFormat');
        O.Expect('dt_fmt_6', 'ERR:Standard format number 6 does not exist for the type ''DateTime''./InvalidStandardFormat');
        O.Expect('dt_fmt_7', 'ERR:Standard format number 7 does not exist for the type ''DateTime''./InvalidStandardFormat');
        O.Expect('dt_fmt_8', 'ERR:Standard format number 8 does not exist for the type ''DateTime''./InvalidStandardFormat');
        O.Expect('dt_fmt_9', '[2024-03-05T13:45:09.007Z]');
        O.Expect('dt_fmt_10', 'ERR:Standard format number 10 does not exist for the type ''DateTime''./InvalidStandardFormat');
        O.Expect('dt_0ms_fmt_0', '[03/05/24 01:45 PM]');
        O.Expect('dt_0ms_fmt_1', '[03/05/24 01:45:09 PM]');
        O.Expect('dt_0ms_fmt_2', '[03/05/24 01:45 PM]');
        O.Expect('dt_0ms_fmt_3', '[03/05/24 01:45:09 PM]');
        O.Expect('dt_0ms_fmt_4', 'ERR:Standard format number 4 does not exist for the type ''DateTime''./InvalidStandardFormat');
        O.Expect('dt_0ms_fmt_5', 'ERR:Standard format number 5 does not exist for the type ''DateTime''./InvalidStandardFormat');
        O.Expect('dt_0ms_fmt_6', 'ERR:Standard format number 6 does not exist for the type ''DateTime''./InvalidStandardFormat');
        O.Expect('dt_0ms_fmt_7', 'ERR:Standard format number 7 does not exist for the type ''DateTime''./InvalidStandardFormat');
        O.Expect('dt_0ms_fmt_8', 'ERR:Standard format number 8 does not exist for the type ''DateTime''./InvalidStandardFormat');
        O.Expect('dt_0ms_fmt_9', '[2024-03-05T13:45:09Z]');
        O.Expect('dt_0ms_fmt_10', 'ERR:Standard format number 10 does not exist for the type ''DateTime''./InvalidStandardFormat');
        O.Verify();
    end;

    local procedure FmtDt(T: DateTime; N: Integer): Text
    var
        R: Text;
    begin
        if FmtDtF(T, N, R) then
            exit('[' + R + ']');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure FmtDtF(T: DateTime; N: Integer; var R: Text)
    begin
        R := Format(T, 0, N);
    end;

    [Test]
    procedure Format_StandardNumbers_DurationAndDate()
    var
        O: Codeunit "Probe Observer";
        Du: Duration;
        D: Date;
        i: Integer;
    begin
        Du := 90061001;
        for i := 0 to 10 do
            O.Observe('duration_fmt_' + Format(i), FmtDu(Du, i));
        D := DMY2Date(5, 3, 2024);
        for i := 0 to 12 do
            O.Observe('date_fmt_' + Format(i), FmtD(D, i));
        O.Expect('duration_fmt_0', '[1 day 1 hour 1 minute 1 second 1 millisecond]');
        O.Expect('duration_fmt_1', '[1 day 1 hour 1 minute 1 second 1 millisecond]');
        O.Expect('duration_fmt_2', '[1 0 1 2 1 4 1 6 1 8]');
        O.Expect('duration_fmt_3', 'ERR:Standard format number 3 does not exist for the type ''Duration''./InvalidStandardFormat');
        O.Expect('duration_fmt_4', 'ERR:Standard format number 4 does not exist for the type ''Duration''./InvalidStandardFormat');
        O.Expect('duration_fmt_5', 'ERR:Standard format number 5 does not exist for the type ''Duration''./InvalidStandardFormat');
        O.Expect('duration_fmt_6', 'ERR:Standard format number 6 does not exist for the type ''Duration''./InvalidStandardFormat');
        O.Expect('duration_fmt_7', 'ERR:Standard format number 7 does not exist for the type ''Duration''./InvalidStandardFormat');
        O.Expect('duration_fmt_8', 'ERR:Standard format number 8 does not exist for the type ''Duration''./InvalidStandardFormat');
        O.Expect('duration_fmt_9', '[P1DT1H1M1.001S]');
        O.Expect('duration_fmt_10', 'ERR:Standard format number 10 does not exist for the type ''Duration''./InvalidStandardFormat');
        O.Expect('date_fmt_0', '[03/05/24]');
        O.Expect('date_fmt_1', '[03/05/24]');
        O.Expect('date_fmt_2', '[030524D]');
        O.Expect('date_fmt_3', '[24/03/05]');
        O.Expect('date_fmt_4', '[March 5, 2024]');
        O.Expect('date_fmt_5', '[030524]');
        O.Expect('date_fmt_6', '[240305]');
        O.Expect('date_fmt_7', '[Mar 5, 2024]');
        O.Expect('date_fmt_8', 'ERR:Standard format number 8 does not exist for the type ''Date''./InvalidStandardFormat');
        O.Expect('date_fmt_9', '[2024-03-05]');
        O.Expect('date_fmt_10', 'ERR:Standard format number 10 does not exist for the type ''Date''./InvalidStandardFormat');
        O.Expect('date_fmt_11', 'ERR:Standard format number 11 does not exist for the type ''Date''./InvalidStandardFormat');
        O.Expect('date_fmt_12', 'ERR:Standard format number 12 does not exist for the type ''Date''./InvalidStandardFormat');
        O.Verify();
    end;

    local procedure FmtDu(T: Duration; N: Integer): Text
    var
        R: Text;
    begin
        if FmtDuF(T, N, R) then
            exit('[' + R + ']');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure FmtDuF(T: Duration; N: Integer; var R: Text)
    begin
        R := Format(T, 0, N);
    end;

    local procedure FmtD(T: Date; N: Integer): Text
    var
        R: Text;
    begin
        if FmtDF(T, N, R) then
            exit('[' + R + ']');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure FmtDF(T: Date; N: Integer; var R: Text)
    begin
        R := Format(T, 0, N);
    end;

    [Test]
    procedure Dates_CreateDateTimeRoundTrip()
    var
        O: Codeunit "Probe Observer";
        Dt: DateTime;
    begin
        Dt := CreateDateTime(DMY2Date(15, 1, 2024), 233000T);
        O.Observe('dt2date_late', Format(DT2Date(Dt), 0, 9));
        O.Observe('dt2time_late', Format(DT2Time(Dt), 0, 9));
        O.Observe('fmt_hours', Format(Dt, 0, '<Hours24>:<Minutes>'));
        O.Observe('fmt_date_codes', Format(Dt, 0, '<Year4>-<Month,2>-<Day,2>'));
        Dt := CreateDateTime(DMY2Date(15, 1, 2024), 003000T);
        O.Observe('dt2date_early', Format(DT2Date(Dt), 0, 9));
        O.Observe('dt2time_early', Format(DT2Time(Dt), 0, 9));
        O.Observe('fmt_early', Format(Dt, 0, '<Year4>-<Month,2>-<Day,2> <Hours24>:<Minutes>'));
        Dt := CreateDateTime(0D, 0T);
        O.Observe('createdatetime_0D_0T', Format(Dt, 0, 9));
        Dt := CreateDateTime(DMY2Date(15, 1, 2024), 0T);
        O.Observe('createdatetime_date_0T', Format(Dt, 0, 9));
        asserterror Dt := CreateDateTime(0D, 120000T);
        O.ObserveError('createdatetime_0D_time');
        O.Observe('dt2date_of_0DT', Format(DT2Date(0DT), 0, 9));
        O.Observe('dt2time_of_0DT', Format(DT2Time(0DT), 0, 9));
        O.Expect('dt2date_late', '2024-01-15');
        O.Expect('dt2time_late', '23:30:00');
        O.Expect('fmt_hours', '23:30');
        O.Expect('fmt_date_codes', '2024-01-15');
        O.Expect('dt2date_early', '2024-01-15');
        O.Expect('dt2time_early', '00:30:00');
        O.Expect('fmt_early', '2024-01-15 0:30');
        O.Expect('createdatetime_0D_0T', '');
        O.Expect('createdatetime_date_0T', '2024-01-15T00:00:00Z');
        O.Expect('createdatetime_0D_time|text', 'The date is not valid.');
        O.Expect('createdatetime_0D_time|code', 'DateInvalid');
        O.Expect('dt2date_of_0DT', '');
        O.Expect('dt2time_of_0DT', '');
        O.Verify();
    end;

    [Test]
    procedure Dates_CreateDateTimeClosingDate()
    var
        O: Codeunit "Probe Observer";
        Dt: DateTime;
    begin
        Dt := CreateDateTime(ClosingDate(DMY2Date(31, 12, 2024)), 0T);
        O.Observe('createdatetime_closing_date', 'no error');
        O.Expect('createdatetime_closing_date', 'no error');
        O.Verify();
    end;

    [Test]
    procedure Dates_Date2DWY_WeekAndYear()
    var
        O: Codeunit "Probe Observer";
        Dates: List of [Date];
        D: Date;
    begin
        Dates.Add(DMY2Date(1, 1, 2021));
        Dates.Add(DMY2Date(3, 1, 2021));
        Dates.Add(DMY2Date(4, 1, 2021));
        Dates.Add(DMY2Date(30, 12, 2024));
        Dates.Add(DMY2Date(31, 12, 2024));
        Dates.Add(DMY2Date(1, 1, 2024));
        Dates.Add(DMY2Date(29, 12, 2025));
        Dates.Add(DMY2Date(31, 12, 2020));
        Dates.Add(DMY2Date(28, 12, 2026));
        Dates.Add(DMY2Date(1, 1, 2027));
        foreach D in Dates do
            O.Observe('dwy_' + Format(D, 0, 9), Format(Date2DWY(D, 1)) + ' week=' + Format(Date2DWY(D, 2)) + ' year=' + Format(Date2DWY(D, 3)));
        O.Expect('dwy_2021-01-01', '5 week=53 year=2020');
        O.Expect('dwy_2021-01-03', '7 week=53 year=2020');
        O.Expect('dwy_2021-01-04', '1 week=1 year=2021');
        O.Expect('dwy_2024-12-30', '1 week=1 year=2025');
        O.Expect('dwy_2024-12-31', '2 week=1 year=2025');
        O.Expect('dwy_2024-01-01', '1 week=1 year=2024');
        O.Expect('dwy_2025-12-29', '1 week=1 year=2026');
        O.Expect('dwy_2020-12-31', '4 week=53 year=2020');
        O.Expect('dwy_2026-12-28', '1 week=53 year=2026');
        O.Expect('dwy_2027-01-01', '5 week=53 year=2026');
        O.Verify();
    end;

    [Test]
    procedure Dates_Date2DWY_BadPart()
    var
        O: Codeunit "Probe Observer";
        R: Integer;
    begin
        asserterror R := Date2DWY(DMY2Date(1, 1, 2024), 0);
        O.ObserveError('part_0');
        asserterror R := Date2DWY(DMY2Date(1, 1, 2024), 4);
        O.ObserveError('part_4');
        asserterror R := Date2DWY(0D, 1);
        O.ObserveError('undefined_date');
        asserterror R := Date2DMY(DMY2Date(1, 1, 2024), 4);
        O.ObserveError('date2dmy_part_4');
        asserterror R := Date2DMY(DMY2Date(1, 1, 2024), 0);
        O.ObserveError('date2dmy_part_0');
        R := Date2DWY(ClosingDate(DMY2Date(31, 12, 2024)), 1);
        O.Observe('closing_date_dwy1', 'no error');
        O.Expect('part_0|text', 'The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 3.');
        O.Expect('part_0|code', 'OutsidePermittedRange');
        O.Expect('part_4|text', 'The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: 4. The permitted range is: from 1 to 3.');
        O.Expect('part_4|code', 'OutsidePermittedRange');
        O.Expect('undefined_date|text', 'The date is not valid.');
        O.Expect('undefined_date|code', 'DateInvalid');
        O.Expect('date2dmy_part_4|text', 'The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 4. The permitted range is: from 1 to 3.');
        O.Expect('date2dmy_part_4|code', 'OutsidePermittedRange');
        O.Expect('date2dmy_part_0|text', 'The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 3.');
        O.Expect('date2dmy_part_0|code', 'OutsidePermittedRange');
        O.Expect('closing_date_dwy1', 'no error');
        O.Verify();
    end;

    [Test]
    procedure Dates_CalcDate_Formulas()
    var
        O: Codeunit "Probe Observer";
        Mon: Date;
        Wed: Date;
    begin
        Mon := DMY2Date(15, 1, 2024);
        Wed := DMY2Date(17, 1, 2024);
        O.Observe('wd1_on_monday', CalcD('<WD1>', Mon));
        O.Observe('plus_wd1_on_monday', CalcD('<+WD1>', Mon));
        O.Observe('minus_wd1_on_monday', CalcD('<-WD1>', Mon));
        O.Observe('wd1_on_wednesday', CalcD('<WD1>', Wed));
        O.Observe('minus_wd1_on_wednesday', CalcD('<-WD1>', Wed));
        O.Observe('wd3_on_wednesday', CalcD('<WD3>', Wed));
        O.Observe('wd7_on_monday', CalcD('<WD7>', Mon));
        O.Observe('lowercase_cm', CalcD('<cm>', Mon));
        O.Observe('lowercase_1d', CalcD('<1d>', Mon));
        O.Observe('upper_cm', CalcD('<CM>', Mon));
        O.Observe('term_no_sign_second', CalcD('<1D1W>', Mon));
        O.Observe('term_sign_second', CalcD('<1D+1W>', Mon));
        O.Observe('minus_then_term', CalcD('<-1D1M>', Mon));
        O.Observe('cm_plus_1d', CalcD('<CM+1D>', Mon));
        O.Observe('cq', CalcD('<CQ>', Mon));
        O.Observe('cy', CalcD('<CY>', Mon));
        O.Observe('minus_cy', CalcD('<-CY>', Mon));
        O.Observe('1m_from_jan31', CalcD('<1M>', DMY2Date(31, 1, 2024)));
        O.Observe('1y_from_feb29', CalcD('<1Y>', DMY2Date(29, 2, 2024)));
        O.Observe('closing_date_base', CalcDClosing('<1D>'));
        O.Observe('closing_date_base_cm', CalcDClosing('<CM>'));
        O.Observe('undefined_date_base', CalcD('<1D>', 0D));
        O.Observe('undefined_date_base_cm', CalcD('<CM>', 0D));
        O.Observe('empty_formula', CalcD('', Mon));
        O.Observe('wd_with_number_8', CalcD('<WD8>', Mon));
        O.Expect('wd1_on_monday', '2024-01-22');
        O.Expect('plus_wd1_on_monday', '2024-01-22');
        O.Expect('minus_wd1_on_monday', '2024-01-08');
        O.Expect('wd1_on_wednesday', '2024-01-22');
        O.Expect('minus_wd1_on_wednesday', '2024-01-15');
        O.Expect('wd3_on_wednesday', '2024-01-24');
        O.Expect('wd7_on_monday', '2024-01-21');
        O.Expect('lowercase_cm', '2024-01-31');
        O.Expect('lowercase_1d', '2024-01-16');
        O.Expect('upper_cm', '2024-01-31');
        O.Expect('term_no_sign_second', 'ERR:The date formula ''1D1W'' must include plus (+) or minus (-)./Evaluate');
        O.Expect('term_sign_second', '2024-01-23');
        O.Expect('minus_then_term', 'ERR:The date formula ''-1D1M'' must include plus (+) or minus (-)./Evaluate');
        O.Expect('cm_plus_1d', '2024-02-01');
        O.Expect('cq', '2024-03-31');
        O.Expect('cy', '2024-12-31');
        O.Expect('minus_cy', '2024-01-01');
        O.Expect('1m_from_jan31', '2024-02-29');
        O.Expect('1y_from_feb29', '2025-02-28');
        O.Expect('closing_date_base', '2024-01-01');
        O.Expect('closing_date_base_cm', '2023-12-31');
        O.Expect('undefined_date_base', 'ERR:You cannot base a date calculation on an undefined date.\r\\r\Date: 0D\r\Formula: 1D./Argument');
        O.Expect('undefined_date_base_cm', 'ERR:You cannot base a date calculation on an undefined date.\r\\r\Date: 0D\r\Formula: CM./Argument');
        O.Expect('empty_formula', '2024-01-15');
        O.Expect('wd_with_number_8', 'ERR:The date formula ''WD8'' contains a number that is too large.\r\\r\The number must be in the range 1 - 7./Evaluate');
        O.Verify();
    end;

    local procedure CalcD(F: Text; D: Date): Text
    var
        R: Date;
    begin
        if CalcDF(F, D, R) then
            exit(Format(R, 0, 9));
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure CalcDF(F: Text; D: Date; var R: Date)
    begin
        R := CalcDate(F, D);
    end;

    local procedure CalcDClosing(F: Text): Text
    var
        R: Date;
    begin
        if CalcDClosingF(F, R) then
            exit(Format(R, 0, 9));
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure CalcDClosingF(F: Text; var R: Date)
    begin
        R := CalcDate(F, ClosingDate(DMY2Date(31, 12, 2023)));
    end;

    [Test]
    procedure Dates_CalcDate_OmittedBase()
    var
        O: Codeunit "Probe Observer";
        Saved: Date;
    begin
        Saved := WorkDate();
        WorkDate(DMY2Date(15, 1, 2000));
        O.Observe('omitted_base_plus_0D_vs_workdate_2000', Format(CalcDate('<0D>')));
        O.Observe('omitted_base_is_today_diff', Format(CalcDate('<0D>') - Today()));
        O.Observe('omitted_base_is_workdate_diff', Format(CalcDate('<0D>') - WorkDate()));
        WorkDate(Saved);
        O.Expect('omitted_base_plus_0D_vs_workdate_2000', Format(Today()));
        O.Expect('omitted_base_is_today_diff', '0');
        O.Expect('omitted_base_is_workdate_diff', Format(Today() - DMY2Date(15, 1, 2000)));
        O.Verify();
    end;

    [Test]
    procedure DateFormula_EvaluateForms()
    var
        O: Codeunit "Probe Observer";
        Texts: List of [Text];
        T: Text;
        DF: DateFormula;
    begin
        Texts.Add('');
        Texts.Add('<>');
        Texts.Add('   ');
        Texts.Add('1D');
        Texts.Add('<1D>');
        Texts.Add('-1D');
        Texts.Add('+1D');
        Texts.Add('1D+1W');
        Texts.Add('1D1W');
        Texts.Add('CM');
        Texts.Add('cm');
        Texts.Add('1X');
        Texts.Add('D');
        Texts.Add('1');
        Texts.Add('WD1');
        Texts.Add('-WD1');
        Texts.Add('<1D');
        Texts.Add('1D>');
        Texts.Add('1Q');
        Texts.Add('1P');
        Texts.Add('1D1M1Y');
        Texts.Add('99999D');
        Texts.Add('1d');
        foreach T in Texts do begin
            Clear(DF);
            if Evaluate(DF, T) then
                O.Observe('evaluate_dateformula_[' + T + ']', 'ok:[' + Format(DF) + ']')
            else
                O.Observe('evaluate_dateformula_[' + T + ']', 'fail');
        end;
        O.Expect('evaluate_dateformula_[]', 'ok:[]');
        O.Expect('evaluate_dateformula_[<>]', 'ok:[]');
        O.Expect('evaluate_dateformula_[   ]', 'ok:[]');
        O.Expect('evaluate_dateformula_[1D]', 'ok:[1D]');
        O.Expect('evaluate_dateformula_[<1D>]', 'ok:[1D]');
        O.Expect('evaluate_dateformula_[-1D]', 'ok:[-1D]');
        O.Expect('evaluate_dateformula_[+1D]', 'ok:[+1D]');
        O.Expect('evaluate_dateformula_[1D+1W]', 'ok:[1D+1W]');
        O.Expect('evaluate_dateformula_[1D1W]', 'fail');
        O.Expect('evaluate_dateformula_[CM]', 'ok:[CM]');
        O.Expect('evaluate_dateformula_[cm]', 'ok:[CM]');
        O.Expect('evaluate_dateformula_[1X]', 'fail');
        O.Expect('evaluate_dateformula_[D]', 'fail');
        O.Expect('evaluate_dateformula_[1]', 'fail');
        O.Expect('evaluate_dateformula_[WD1]', 'ok:[WD1]');
        O.Expect('evaluate_dateformula_[-WD1]', 'ok:[-WD1]');
        O.Expect('evaluate_dateformula_[<1D]', 'ok:[1D]');
        O.Expect('evaluate_dateformula_[1D>]', 'ok:[1D]');
        O.Expect('evaluate_dateformula_[1Q]', 'ok:[1Q]');
        O.Expect('evaluate_dateformula_[1P]', 'fail');
        O.Expect('evaluate_dateformula_[1D1M1Y]', 'fail');
        O.Expect('evaluate_dateformula_[99999D]', 'fail');
        O.Expect('evaluate_dateformula_[1d]', 'ok:[1D]');
        O.Verify();
    end;

    [Test]
    procedure Format_FormatStrings_Date()
    var
        O: Codeunit "Probe Observer";
        D: Date;
    begin
        D := DMY2Date(5, 3, 2005);
        O.Observe('day', Format(D, 0, '<Day>'));
        O.Observe('day_2', Format(D, 0, '<Day,2>'));
        O.Observe('month', Format(D, 0, '<Month>'));
        O.Observe('month_2', Format(D, 0, '<Month,2>'));
        O.Observe('year', Format(D, 0, '<Year>'));
        O.Observe('year_2005_year4', Format(D, 0, '<Year4>'));
        O.Observe('year_1999', Format(DMY2Date(5, 3, 1999), 0, '<Year>'));
        O.Observe('year_1905', Format(DMY2Date(5, 3, 1905), 0, '<Year>'));
        O.Observe('year_2105', Format(DMY2Date(5, 3, 2105), 0, '<Year>'));
        O.Observe('year_2009', Format(DMY2Date(5, 3, 2009), 0, '<Year>'));
        O.Observe('year_1930', Format(DMY2Date(5, 3, 1930), 0, '<Year>'));
        O.Observe('year_1929', Format(DMY2Date(5, 3, 1929), 0, '<Year>'));
        O.Observe('year_2029', Format(DMY2Date(5, 3, 2029), 0, '<Year>'));
        O.Observe('year_2030', Format(DMY2Date(5, 3, 2030), 0, '<Year>'));
        O.Observe('year_2000', Format(DMY2Date(5, 3, 2000), 0, '<Year>'));
        O.Observe('year_2001', Format(DMY2Date(5, 3, 2001), 0, '<Year>'));
        O.Observe('month_text', Format(D, 0, '<Month Text>'));
        O.Observe('closing_date_text', Format(ClosingDate(D), 0, '<Day>.<Month>.<Year4>'));
        O.Expect('day', '5');
        O.Expect('day_2', '05');
        O.Expect('month', '3');
        O.Expect('month_2', '03');
        O.Expect('year', '05');
        O.Expect('year_2005_year4', '2005');
        O.Expect('year_1999', '99');
        O.Expect('year_1905', '1905');
        O.Expect('year_2105', '2105');
        O.Expect('year_2009', '09');
        O.Expect('year_1930', '1930');
        O.Expect('year_1929', '1929');
        O.Expect('year_2029', '29');
        O.Expect('year_2030', '30');
        O.Expect('year_2000', '00');
        O.Expect('year_2001', '01');
        O.Expect('month_text', 'March');
        O.Expect('closing_date_text', '5.3.2005');
        O.Verify();
    end;

    [Test]
    procedure Format_FormatStrings_Number()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('sign_positive', Format(5, 0, '<Sign><Integer>'));
        O.Observe('sign_zero', Format(0, 0, '<Sign><Integer>'));
        O.Observe('sign_negative', Format(-5, 0, '<Sign><Integer>'));
        O.Observe('sign_pos_char', Format(5, 0, '<Sign,1><Integer>'));
        O.Observe('sign_pos_dec', Format(5.5, 0, '<Sign><Integer><Decimals>'));
        O.Observe('decimals_without_width', Format(1234.5, 0, '<Integer><Decimals>'));
        O.Observe('decimals_2', Format(1234.567, 0, '<Integer><Decimals,3>'));
        O.Observe('decimals_2_wide', Format(1234.5, 0, '<Integer><Decimals,5>'));
        O.Observe('integer_thousand', Format(1234567, 0, '<Integer Thousand>'));
        O.Observe('integer_thousand_width_10', Format(1234567, 0, '<Integer Thousand,10>'));
        O.Observe('integer_thousand_width_3', Format(1234567, 0, '<Integer Thousand,3>'));
        O.Observe('integer_width_5', Format(42, 0, '<Integer,5>'));
        asserterror O.Observe('integer_width_5_fill_0', Format(42, 0, '<Integer,5><Filler Character 0>'));
        O.ObserveError('integer_width_5_fill_0');
        asserterror O.Observe('integer_width_5_fill_x', Format(42, 0, '<Integer,5><Filler Character x>'));
        O.ObserveError('integer_width_5_fill_x');
        O.Observe('standard_format_1', Format(1234567.891, 0, 1));
        O.Observe('standard_format_2', Format(1234567.891, 0, 2));
        O.Observe('standard_format_0', Format(1234567.891, 0, 0));
        O.Observe('precision_decimals_neg', Format(-0.5, 0, '<Sign><Integer><Decimals>'));
        O.Observe('standard_format_3', Format(1234567.891, 0, 3));
        O.Observe('standard_format_4', Format(1234567.891, 0, 4));
        O.Expect('sign_positive', '5');
        O.Expect('sign_zero', '0');
        O.Expect('sign_negative', '-5');
        O.Expect('sign_pos_char', ' 5');
        O.Expect('sign_pos_dec', '5.5');
        O.Expect('decimals_without_width', '1234.5');
        O.Expect('decimals_2', '1234***');
        O.Expect('decimals_2_wide', '1234.5000');
        O.Expect('integer_thousand', '1,234,567');
        O.Expect('integer_thousand_width_10', ' 1,234,567');
        O.Expect('integer_thousand_width_3', '***');
        O.Expect('integer_width_5', '   42');
        O.Expect('integer_width_5_fill_0|text', 'An invalid field or attribute has been specified for the ''Format'' property.\r\\r\<Integer,5><Filler Character 0>');
        O.Expect('integer_width_5_fill_0|code', 'InvalidFormatString');
        O.Expect('integer_width_5_fill_x|text', 'An invalid field or attribute has been specified for the ''Format'' property.\r\\r\<Integer,5><Filler Character x>');
        O.Expect('integer_width_5_fill_x|code', 'InvalidFormatString');
        O.Expect('standard_format_1', '1234567.891');
        O.Expect('standard_format_2', '1234567.891');
        O.Expect('standard_format_0', '1,234,567.891');
        O.Expect('precision_decimals_neg', '-0.5');
        O.Expect('standard_format_3', '1,234,567.891 ');
        O.Expect('standard_format_4', '1234567.891 ');
        O.Verify();
    end;

    [Test]
    procedure Format_OptionFieldAndOptionVariable()
    var
        O: Codeunit "Probe Observer";
        R: Record "PA Fmt Row";
        Opt: Option Red,Green,Blue;
        i: Integer;
    begin
        R.Opt := R.Opt::Beta;
        R.OptNoCaption := R.OptNoCaption::Yy;
        O.Observe('field_default', Format(R.Opt));
        O.Observe('field_f0', Format(R.Opt, 0, 0));
        O.Observe('field_f1', Format(R.Opt, 0, 1));
        O.Observe('field_f2', Format(R.Opt, 0, 2));
        O.Observe('field_f9', Format(R.Opt, 0, 9));
        O.Observe('field_len3', Format(R.Opt, 3));
        O.Observe('field_len3_f2', Format(R.Opt, 3, 2));
        O.Observe('field_nocaption_default', Format(R.OptNoCaption));
        O.Observe('field_nocaption_f9', Format(R.OptNoCaption, 0, 9));
        Opt := Opt::Green;
        O.Observe('var_default', Format(Opt));
        O.Observe('var_f9', Format(Opt, 0, 9));
        O.Observe('var_f2', Format(Opt, 0, 2));
        asserterror O.Observe('integer_cast_default', Format(R.Opt, 0, '<Integer>'));
        O.ObserveError('integer_cast_default');
        O.Observe('field_caption_via_record_format', Format(R));
        O.Expect('field_default', 'Second');
        O.Expect('field_f0', 'Second');
        O.Expect('field_f1', 'Second');
        O.Expect('field_f2', '1');
        O.Expect('field_f9', '1');
        O.Expect('field_len3', 'Sec');
        O.Expect('field_len3_f2', '1  ');
        O.Expect('field_nocaption_default', 'Yy');
        O.Expect('field_nocaption_f9', '1');
        O.Expect('var_default', 'Green');
        O.Expect('var_f9', '1');
        O.Expect('var_f2', '1');
        O.Expect('integer_cast_default|text', 'An invalid field or attribute has been specified for the ''Format'' property.\r\\r\<Integer>');
        O.Expect('integer_cast_default|code', 'InvalidFormatString');
        O.Expect('field_caption_via_record_format', '0\tSecond\tYy\t0');
        O.Verify();
    end;

    [Test]
    procedure Format_DecimalInRecordFormat()
    var
        O: Codeunit "Probe Observer";
        R: Record "PA Fmt Row";
    begin
        R.Id := 1;
        R.Dec := 1234.5;
        O.Observe('format_decimal_default', Format(R.Dec));
        O.Observe('format_decimal_f9', Format(R.Dec, 0, 9));
        O.Observe('format_decimal_f1', Format(R.Dec, 0, 1));
        O.Observe('format_record', Format(R));
        O.Expect('format_decimal_default', '1,234.5');
        O.Expect('format_decimal_f9', '1234.5');
        O.Expect('format_decimal_f1', '1234.5');
        O.Expect('format_record', '1\tFirst\tXx\t1,234.5');
        O.Verify();
    end;
}
