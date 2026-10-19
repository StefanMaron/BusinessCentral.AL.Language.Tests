// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); helper codeunit 85121 in this folder
// Probe: corpus issue #672 (odd AL behavior leads, part G), items 47 to 61. Each test covers only the cases the existing corpus did not pin
// (the file header of each test names the existing pins). Every literal asserted below is what BC produced; other BC versions by the CI matrix.
// BC versions: 27, 28, 29

codeunit 85120 "LT CR Text Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Codes(T: Text): Text
    var
        I: Integer;
        C: Integer;
        R: Text;
    begin
        for I := 1 to StrLen(T) do begin
            C := T[I];
            if R <> '' then
                R += ',';
            R += Format(C);
        end;
        exit(R);
    end;

    [TryFunction]
    local procedure TrySub(T: Text; Pos: Integer; Len: Integer; var Res: Text)
    begin
        Res := T.Substring(Pos, Len);
    end;

    local procedure Sub(T: Text; Pos: Integer; Len: Integer): Text
    var
        Res: Text;
    begin
        if TrySub(T, Pos, Len, Res) then
            exit('ok:' + Res);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // Item 49 and 50 (Substring past the end). Already pinned: misc/lt-probes-needed-1/PnATextFunctions.al Substring_Cases
    // ('abc': Substring(0), (1,-1), (4) = '', (5) error, (2,10) = 'bc', (1,0), (-1)); text/lt-label-textbuilder/TxCLabel.al (Label receiver).
    // New here: the two-argument form with a start at or past the end, a start of 0 with a length, and the cases named in the lead.
    [Test]
    procedure Substring_StartAndLengthPastEnd()
    var
        Obs: Codeunit "Probe Observer";
        TC: TextConst ENU = 'textconst';
    begin
        Obs.Observe('string_1_20', Sub('string', 1, 20));
        Obs.Observe('abc_2_5', Sub('abc', 2, 5));
        Obs.Observe('digits_1_20', Sub('123456789', 1, 20));
        Obs.Observe('12345_3_10', Sub('12345', 3, 10));
        Obs.Observe('abc_4_0', Sub('abc', 4, 0));
        Obs.Observe('abc_4_1', Sub('abc', 4, 1));
        Obs.Observe('abc_5_0', Sub('abc', 5, 0));
        Obs.Observe('abc_5_1', Sub('abc', 5, 1));
        Obs.Observe('abc_0_1', Sub('abc', 0, 1));
        Obs.Observe('abc_3_1', Sub('abc', 3, 1));
        Obs.Observe('empty_1_0', Sub('', 1, 0));
        Obs.Observe('empty_1_1', Sub('', 1, 1));
        Obs.Observe('empty_2_1', Sub('', 2, 1));
        Obs.Observe('textconst_5_20', TC.Substring(5, 20));
        Obs.Finish();
    end;

    // Item 51 (BigText boundaries). Already pinned: streams/StTBigText.al (AddText at 0, -1 and length+2; GetSubText 0, negative, length+1
    // and 20 raise no error; TextPos of '' and of a missing text = 0). New here: the values those calls return.
    [Test]
    procedure BigText_BoundaryValues()
    var
        Obs: Codeunit "Probe Observer";
        Big: BigText;
        T: Text;
        N: Integer;
    begin
        Big.AddText('abc');
        Big.AddText('x', 999);
        Big.GetSubText(T, 1);
        Obs.Observe('add999', T + '|' + Format(Big.Length()));
        Big.AddText('', 1);
        Big.GetSubText(T, 1);
        Obs.Observe('addEmpty', T + '|' + Format(Big.Length()));
        T := 'old';
        N := Big.GetSubText(T, 5, 1);
        Obs.Observe('sub_len_plus_1', T + '|' + Format(N));
        T := 'old';
        N := Big.GetSubText(T, 20);
        Obs.Observe('sub_20', T + '|' + Format(N));
        T := 'old';
        N := Big.GetSubText(T, 3, 50);
        Obs.Observe('sub_3_50', T + '|' + Format(N));
        Clear(Big);
        Obs.Observe('emptyTextPos', Format(Big.TextPos('a')));
        Obs.Observe('emptyTextPosEmpty', Format(Big.TextPos('')));
        Obs.Finish();
    end;

    [TryFunction]
    local procedure TrySetCode(var C: Code[10]; Pos: Integer; Ch: Char)
    begin
        C[Pos] := Ch;
    end;

    local procedure SetCode(var C: Code[10]; Pos: Integer; Ch: Char): Text
    begin
        if TrySetCode(C, Pos, Ch) then
            exit('ok:' + C);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TrySetText(var T: Text; Pos: Integer; Ch: Char)
    begin
        T[Pos] := Ch;
    end;

    local procedure SetText(var T: Text; Pos: Integer; Ch: Char): Text
    begin
        if TrySetText(T, Pos, Ch) then
            exit('ok:' + T);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // Item 52 (index assignment past the end). Already pinned for Text[5]: misc/lt-probes-needed-2/PnBDateFormat.al TextCharAssign
    // (length+1 appends, a gap raises, the declared length is enforced). New here: Code, and an unbounded Text with a gap.
    [Test]
    procedure IndexAssign_CodeAndText()
    var
        Obs: Codeunit "Probe Observer";
        C: Code[10];
        T: Text;
    begin
        C := 'ABC';
        Obs.Observe('code_len_plus_1', SetCode(C, 4, 'd'));
        Obs.Observe('code_gap', SetCode(C, 6, 'x'));
        Obs.Observe('code_replace_lower', SetCode(C, 1, 'q'));
        Obs.Observe('code_after', C + '|' + Format(StrLen(C)));
        C := 'ABCDEFGHIJ';
        Obs.Observe('code_past_declared', SetCode(C, 11, 'K'));
        T := 'abc';
        Obs.Observe('text_len_plus_1', SetText(T, 4, 'd'));
        Obs.Observe('text_gap', SetText(T, 8, 'x'));
        Obs.Observe('text_after', T);
        Obs.Finish();
    end;

    [TryFunction]
    local procedure TrySetLanguage(Id: Integer)
    begin
        GlobalLanguage(Id);
    end;

    local procedure Cases(var Obs: Codeunit "Probe Observer"; Prefix: Text)
    var
        Upper: Text;
        Lower: Text;
    begin
        Upper := 'I';
        Lower := 'i';
        Obs.Observe(Prefix + 'LowerCase_I', Codes(LowerCase(Upper)));
        Obs.Observe(Prefix + 'ToLower_I', Codes(Upper.ToLower()));
        Obs.Observe(Prefix + 'UpperCase_i', Codes(UpperCase(Lower)));
        Obs.Observe(Prefix + 'ToUpper_i', Codes(Lower.ToUpper()));
        Upper := 'İ';
        Lower := 'ı';
        Obs.Observe(Prefix + 'LowerCase_Idot', Codes(LowerCase(Upper)));
        Obs.Observe(Prefix + 'ToLower_Idot', Codes(Upper.ToLower()));
        Obs.Observe(Prefix + 'UpperCase_dotless', Codes(UpperCase(Lower)));
        Obs.Observe(Prefix + 'ToUpper_dotless', Codes(Lower.ToUpper()));
        Upper := 'ΑΣ';
        Lower := 'ας';
        Obs.Observe(Prefix + 'LowerCase_AS', Codes(LowerCase(Upper)));
        Obs.Observe(Prefix + 'ToLower_AS', Codes(Upper.ToLower()));
        Obs.Observe(Prefix + 'UpperCase_as', Codes(UpperCase(Lower)));
        Obs.Observe(Prefix + 'ToUpper_as', Codes(Lower.ToUpper()));
        Lower := 'ß';
        Obs.Observe(Prefix + 'UpperCase_sz', Codes(UpperCase(Lower)));
        Obs.Observe(Prefix + 'ToUpper_sz', Codes(Lower.ToUpper()));
    end;

    // Item 54 (LowerCase/UpperCase against ToLower/ToUpper under another GlobalLanguage). Already pinned with the default language only:
    // text/lt-text-functions/CaseConv.Codeunit.al, text/lt-text-instance/CaseTrim1.Codeunit.al. New here: GlobalLanguage 1055 (Turkish) and
    // 1032 (Greek). Values are UTF-16 code units.
    [Test]
    procedure CaseConversion_UnderGlobalLanguage()
    var
        Obs: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        Obs.Observe('default_language', Format(Saved));
        Cases(Obs, 'en.');
        if TrySetLanguage(1055) then
            Obs.Observe('set1055', 'ok:' + Format(GlobalLanguage()))
        else
            Obs.Observe('set1055', 'error:' + GetLastErrorText());
        Cases(Obs, 'tr.');
        if TrySetLanguage(1032) then
            Obs.Observe('set1032', 'ok:' + Format(GlobalLanguage()))
        else
            Obs.Observe('set1032', 'error:' + GetLastErrorText());
        Cases(Obs, 'el.');
        GlobalLanguage(Saved);
        Obs.Finish();
    end;

    local procedure TakeCode20(C: Code[20]): Text
    begin
        exit('[' + C + ']');
    end;

    // Item 56 (a long Text field passed to a Code[20] value parameter). Already pinned for a Label: text/lt-label-textbuilder/TxCLabel.al
    // Label_To_Short_Param_Errors. New here: a Text[100] table field (the reported case) and a Text[100] variable, as argument and in an
    // assignment. A var parameter of type Code[20] does not accept a Text[100] field: tests/must-not-compile/cases/1736-*.al.
    [Test]
    procedure LongTextField_ToCode20Parameter()
    var
        Obs: Codeunit "Probe Observer";
        FinHdr: Record "Finance Charge Memo Header" temporary;
        T100: Text[100];
        C20: Code[20];
        R: Text;
    begin
        FinHdr.Name := 'abcdefghij0123456789';
        Obs.Observe('field20', TakeCode20(FinHdr.Name));
        FinHdr.Name := 'abcdefghij0123456789x';
        asserterror R := TakeCode20(FinHdr.Name);
        Obs.ObserveError('field21');
        FinHdr.Name := 'abcdefghij0123456789          ';
        asserterror R := TakeCode20(FinHdr.Name);
        Obs.ObserveError('field20_trailing_spaces');
        T100 := 'abcdefghij0123456789xyz';
        asserterror R := TakeCode20(T100);
        Obs.ObserveError('var23');
        asserterror C20 := T100;
        Obs.ObserveError('assign23');
        Obs.Finish();
    end;

    // Item 57 (StrCheckSum). Already pinned: types/TestProbeScalarContracts.al (non-digit source and weight, empty source with a weight,
    // short weight, modulus 7 and 11), types/TestDateRoundFormatStringContracts.al. New here: the defaults, the Learn example and modulus 0/1.
    [Test]
    procedure StrCheckSum_DefaultsAndDocsExample()
    var
        Obs: Codeunit "Probe Observer";
        R: Integer;
    begin
        Obs.Observe('docs_4378_1234_7', Format(StrCheckSum('4378', '1234', 7)));
        Obs.Observe('empty_noweight', Format(StrCheckSum('')));
        Obs.Observe('12345_noweight', Format(StrCheckSum('12345')));
        Obs.Observe('12345_w11111', Format(StrCheckSum('12345', '11111')));
        Obs.Observe('12345_w11111_10', Format(StrCheckSum('12345', '11111', 10)));
        Obs.Observe('123_longweight', Format(StrCheckSum('123', '12345')));
        asserterror R := StrCheckSum('123', '111', 0);
        Obs.ObserveError('mod0');
        Obs.Observe('mod1', Format(StrCheckSum('123', '111', 1)));
        Obs.Finish();
    end;

    // Item 59 (StrSubstNo with a placeholder repeated non-adjacently). Already pinned: text/lt-text-functions/StrSubstNo.Codeunit.al
    // (adjacent %1%1), errors/lt-error-handling/ErTErrorFormat.al ('%2%1').
    [Test]
    procedure StrSubstNo_RepeatedNonAdjacent()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('learn', StrSubstNo('Test %1 %3 %1', 555, 666, 777));
        Obs.Observe('forum', StrSubstNo('%1%2%1', 9, 0));
        Obs.Observe('sep', StrSubstNo('%2%1%3%1%4%1', ';', '1', '2', '3'));
        Obs.Observe('three', StrSubstNo('%1-%2-%1-%2-%1', 'a', 'b'));
        Obs.Finish();
    end;

    // Item 60 (UTF-16 strings). Already pinned: text/lt-text-instance/Index1.Codeunit.al (StrLen of an emoji = 2 units, its code units,
    // Substring(1, 1) of a pair, ToUpper keeps the length). New here: CopyStr that splits a pair, and case conversion outside the BMP
    // (U+10428 DESERET SMALL LETTER LONG I and U+10400 DESERET CAPITAL LETTER LONG I).
    [Test]
    procedure Utf16_SurrogatePairs()
    var
        Obs: Codeunit "Probe Observer";
        T: Text;
        Small: Text;
        Capital: Text;
    begin
        T := 'a';
        T[2] := 55357;
        T[3] := 56832;
        T[4] := 'b';
        Obs.Observe('copy_1_2', Codes(CopyStr(T, 1, 2)));
        Obs.Observe('copy_3', Codes(CopyStr(T, 3)));
        Obs.Observe('copy_3_1', Codes(CopyStr(T, 3, 1)));
        Obs.Observe('delstr_2_1', Codes(DelStr(T, 2, 1)));
        Obs.Observe('strpos_low', Format(StrPos(T, CopyStr(T, 3, 1))));
        Small[1] := 55297;
        Small[2] := 56360;
        Capital[1] := 55297;
        Capital[2] := 56320;
        Obs.Observe('UpperCase_deseret', Codes(UpperCase(Small)));
        Obs.Observe('ToUpper_deseret', Codes(Small.ToUpper()));
        Obs.Observe('LowerCase_deseret', Codes(LowerCase(Capital)));
        Obs.Observe('ToLower_deseret', Codes(Capital.ToLower()));
        Obs.Observe('compare_upper', Format(UpperCase(Small) = Capital));
        Obs.Finish();
    end;

    // Item 61 (Split with a Char returned by a procedure). The lead's case has the procedure in another app (not pinnable in one app); here
    // the procedure is in another codeunit of the same app. The multi-character separator is already pinned: text/lt-text-instance/
    // Split1.Codeunit.al:105.
    [Test]
    procedure Split_CharFromProcedure()
    var
        Obs: Codeunit "Probe Observer";
        Provider: Codeunit "LT CR Sep Provider";
        Parts: List of [Text];
        Txt: Text;
    begin
        Txt := 'a;b;;c';
        Parts := Txt.Split(Provider.GetSeparator());
        Obs.Observe('char_count', Format(Parts.Count()));
        Obs.Observe('char_3', Parts.Get(3));
        Obs.Observe('char_4', Parts.Get(4));
        Parts := 'Alpha::Bravo::Charlie'.Split('::');
        Obs.Observe('double_colon', Format(Parts.Count()) + '|' + Parts.Get(2));
        Parts := 'Alpha::Bravo::Charlie'.Split(Provider.GetColon());
        Obs.Observe('colon_char', Format(Parts.Count()));
        Obs.Finish();
    end;
}

codeunit 85121 "LT CR Sep Provider"
{
    procedure GetSeparator(): Char
    begin
        exit(';');
    end;

    procedure GetColon(): Char
    begin
        exit(':');
    end;
}
