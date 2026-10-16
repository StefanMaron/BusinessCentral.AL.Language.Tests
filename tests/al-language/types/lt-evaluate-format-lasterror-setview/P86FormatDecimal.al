// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format of a Decimal with standard format numbers 0 to 9 and with format strings (Precision, Standard Format, Sign, Integer Thousand, ...) for negative, zero, large and small values
// BC versions: 29 (27 and 28 by CI)

codeunit 73529 "LT P86 Format Decimal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryNum(D: Decimal; N: Integer; var R: Text)
    begin
        R := Format(D, 0, N);
    end;

    local procedure FN(D: Decimal; N: Integer): Text
    var
        R: Text;
    begin
        R := '<unset>';
        if TryNum(D, N, R) then
            exit('[' + R + ']');
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryStr(D: Decimal; Fmt: Text; var R: Text)
    begin
        R := Format(D, 0, Fmt);
    end;

    local procedure FS(D: Decimal; Fmt: Text): Text
    var
        R: Text;
    begin
        R := '<unset>';
        if TryStr(D, Fmt, R) then
            exit('[' + R + ']');
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryLen(D: Decimal; L: Integer; Fmt: Text; var R: Text)
    begin
        R := Format(D, L, Fmt);
    end;

    local procedure FL(D: Decimal; L: Integer; Fmt: Text): Text
    var
        R: Text;
    begin
        R := '<unset>';
        if TryLen(D, L, Fmt, R) then
            exit('[' + R + ']');
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Num_Zero()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), FN(0, i));
        Observer.Finish();
    end;

    [Test]
    procedure Num_Half()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), FN(0.5, i));
        Observer.Finish();
    end;

    [Test]
    procedure Num_NegHalf()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), FN(-0.5, i));
        Observer.Finish();
    end;

    [Test]
    procedure Num_Tiny()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), FN(0.00001, i));
        Observer.Finish();
    end;

    [Test]
    procedure Num_NegTiny()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), FN(-0.00001, i));
        Observer.Finish();
    end;

    [Test]
    procedure Num_Big()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), FN(123456789012345.678, i));
        Observer.Finish();
    end;

    [Test]
    procedure Num_NegBig()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), FN(-123456789012345.678, i));
        Observer.Finish();
    end;

    [Test]
    procedure Num_Thousand()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), FN(1000, i));
        Observer.Finish();
    end;

    [Test]
    procedure Num_NegThousand()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), FN(-1000, i));
        Observer.Finish();
    end;

    [Test]
    procedure Num_Round()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), FN(999.995, i));
        Observer.Finish();
    end;

    [Test]
    procedure Num_Mid()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), FN(1234.5, i));
        Observer.Finish();
    end;

    [Test]
    procedure Num_Nines()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), FN(0.999999999, i));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Mid_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s1', FS(1234.5, '<Precision,2:2>'));
        Observer.Observe('s2', FS(1234.5, '<Precision,0:3>'));
        Observer.Observe('s3', FS(1234.5, '<Precision,3:3>'));
        Observer.Observe('s4', FS(1234.5, '<Precision,2>'));
        Observer.Observe('s5', FS(1234.5, '<Precision,:2>'));
        Observer.Observe('s6', FS(1234.5, '<Precision,0:0>'));
        Observer.Observe('s7', FS(1234.5, '<Precision,10:10>'));
        Observer.Observe('s8', FS(1234.5, '<Sign>'));
        Observer.Observe('s9', FS(1234.5, '<Sign,1>'));
        Observer.Observe('s10', FS(1234.5, '<Sign,2>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Mid_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s11', FS(1234.5, '<Integer>'));
        Observer.Observe('s12', FS(1234.5, '<Integer Thousand>'));
        Observer.Observe('s13', FS(1234.5, '<Decimals>'));
        Observer.Observe('s14', FS(1234.5, '<Decimals,3>'));
        Observer.Observe('s15', FS(1234.5, '<Decimals,0>'));
        Observer.Observe('s16', FS(1234.5, '<Integer><Decimal Separator><Decimals>'));
        Observer.Observe('s17', FS(1234.5, '<Integer Thousand><Decimal Separator><Decimals>'));
        Observer.Observe('s18', FS(1234.5, '<Sign><Integer Thousand><Decimals>'));
        Observer.Observe('s19', FS(1234.5, '<Sign><Integer><Decimal Separator><Decimals>'));
        Observer.Observe('s20', FS(1234.5, '<Thousand Separator>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Mid_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s21', FS(1234.5, '<Decimal Separator>'));
        Observer.Observe('s22', FS(1234.5, '<Integer,10><Decimals,3>'));
        Observer.Observe('s23', FS(1234.5, '<Integer,10><Filler Character,0><Decimals,3>'));
        Observer.Observe('s24', FS(1234.5, '<Filler Character,#><Integer,8>'));
        Observer.Observe('s25', FS(1234.5, '<Standard Format,0>'));
        Observer.Observe('s26', FS(1234.5, '<Standard Format,1>'));
        Observer.Observe('s27', FS(1234.5, '<Standard Format,2>'));
        Observer.Observe('s28', FS(1234.5, '<Standard Format,3>'));
        Observer.Observe('s29', FS(1234.5, '<Standard Format,4>'));
        Observer.Observe('s30', FS(1234.5, '<Standard Format,5>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Mid_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s31', FS(1234.5, '<Standard Format,6>'));
        Observer.Observe('s32', FS(1234.5, '<Standard Format,7>'));
        Observer.Observe('s33', FS(1234.5, '<Standard Format,8>'));
        Observer.Observe('s34', FS(1234.5, '<Standard Format,9>'));
        Observer.Observe('s35', FS(1234.5, '<Standard Format,10>'));
        Observer.Observe('s36', FS(1234.5, '<Standard Format>'));
        Observer.Observe('s37', FS(1234.5, '<Sign><Precision,2:2>'));
        Observer.Observe('s38', FS(1234.5, '<Precision,2:2><Sign>'));
        Observer.Observe('s39', FS(1234.5, '<Integer Thousand><Precision,2:2>'));
        Observer.Observe('s40', FS(1234.5, '<Precision,2:2><Integer Thousand>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Mid_5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s41', FS(1234.5, '<Sign,1><Integer Thousand><Decimals,2>'));
        Observer.Observe('s42', FS(1234.5, '<Sign,2><Integer><Decimals>'));
        Observer.Observe('s43', FS(1234.5, '<1000 Separator>'));
        Observer.Observe('s44', FS(1234.5, '<Currency Symbol>'));
        Observer.Observe('s45', FS(1234.5, '<Unknown>'));
        Observer.Observe('s46', FS(1234.5, '<Precision,2:2'));
        Observer.Observe('s47', FS(1234.5, 'Precision,2:2>'));
        Observer.Observe('s48', FS(1234.5, 'abc'));
        Observer.Observe('s49', FS(1234.5, ''));
        Observer.Observe('s50', FS(1234.5, 'x<Precision,2:2>y'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Mid_6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s51', FS(1234.5, '<Integer,5,>'));
        Observer.Observe('s52', FS(1234.5, '<Precision,a:b>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_NegBig_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s1', FS(-123456789012345.678, '<Precision,2:2>'));
        Observer.Observe('s2', FS(-123456789012345.678, '<Precision,0:3>'));
        Observer.Observe('s3', FS(-123456789012345.678, '<Precision,3:3>'));
        Observer.Observe('s4', FS(-123456789012345.678, '<Precision,2>'));
        Observer.Observe('s5', FS(-123456789012345.678, '<Precision,:2>'));
        Observer.Observe('s6', FS(-123456789012345.678, '<Precision,0:0>'));
        Observer.Observe('s7', FS(-123456789012345.678, '<Precision,10:10>'));
        Observer.Observe('s8', FS(-123456789012345.678, '<Sign>'));
        Observer.Observe('s9', FS(-123456789012345.678, '<Sign,1>'));
        Observer.Observe('s10', FS(-123456789012345.678, '<Sign,2>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_NegBig_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s11', FS(-123456789012345.678, '<Integer>'));
        Observer.Observe('s12', FS(-123456789012345.678, '<Integer Thousand>'));
        Observer.Observe('s13', FS(-123456789012345.678, '<Decimals>'));
        Observer.Observe('s14', FS(-123456789012345.678, '<Decimals,3>'));
        Observer.Observe('s15', FS(-123456789012345.678, '<Decimals,0>'));
        Observer.Observe('s16', FS(-123456789012345.678, '<Integer><Decimal Separator><Decimals>'));
        Observer.Observe('s17', FS(-123456789012345.678, '<Integer Thousand><Decimal Separator><Decimals>'));
        Observer.Observe('s18', FS(-123456789012345.678, '<Sign><Integer Thousand><Decimals>'));
        Observer.Observe('s19', FS(-123456789012345.678, '<Sign><Integer><Decimal Separator><Decimals>'));
        Observer.Observe('s20', FS(-123456789012345.678, '<Thousand Separator>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_NegBig_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s21', FS(-123456789012345.678, '<Decimal Separator>'));
        Observer.Observe('s22', FS(-123456789012345.678, '<Integer,10><Decimals,3>'));
        Observer.Observe('s23', FS(-123456789012345.678, '<Integer,10><Filler Character,0><Decimals,3>'));
        Observer.Observe('s24', FS(-123456789012345.678, '<Filler Character,#><Integer,8>'));
        Observer.Observe('s25', FS(-123456789012345.678, '<Standard Format,0>'));
        Observer.Observe('s26', FS(-123456789012345.678, '<Standard Format,1>'));
        Observer.Observe('s27', FS(-123456789012345.678, '<Standard Format,2>'));
        Observer.Observe('s28', FS(-123456789012345.678, '<Standard Format,3>'));
        Observer.Observe('s29', FS(-123456789012345.678, '<Standard Format,4>'));
        Observer.Observe('s30', FS(-123456789012345.678, '<Standard Format,5>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_NegBig_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s31', FS(-123456789012345.678, '<Standard Format,6>'));
        Observer.Observe('s32', FS(-123456789012345.678, '<Standard Format,7>'));
        Observer.Observe('s33', FS(-123456789012345.678, '<Standard Format,8>'));
        Observer.Observe('s34', FS(-123456789012345.678, '<Standard Format,9>'));
        Observer.Observe('s35', FS(-123456789012345.678, '<Standard Format,10>'));
        Observer.Observe('s36', FS(-123456789012345.678, '<Standard Format>'));
        Observer.Observe('s37', FS(-123456789012345.678, '<Sign><Precision,2:2>'));
        Observer.Observe('s38', FS(-123456789012345.678, '<Precision,2:2><Sign>'));
        Observer.Observe('s39', FS(-123456789012345.678, '<Integer Thousand><Precision,2:2>'));
        Observer.Observe('s40', FS(-123456789012345.678, '<Precision,2:2><Integer Thousand>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_NegBig_5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s41', FS(-123456789012345.678, '<Sign,1><Integer Thousand><Decimals,2>'));
        Observer.Observe('s42', FS(-123456789012345.678, '<Sign,2><Integer><Decimals>'));
        Observer.Observe('s43', FS(-123456789012345.678, '<1000 Separator>'));
        Observer.Observe('s44', FS(-123456789012345.678, '<Currency Symbol>'));
        Observer.Observe('s45', FS(-123456789012345.678, '<Unknown>'));
        Observer.Observe('s46', FS(-123456789012345.678, '<Precision,2:2'));
        Observer.Observe('s47', FS(-123456789012345.678, 'Precision,2:2>'));
        Observer.Observe('s48', FS(-123456789012345.678, 'abc'));
        Observer.Observe('s49', FS(-123456789012345.678, ''));
        Observer.Observe('s50', FS(-123456789012345.678, 'x<Precision,2:2>y'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_NegBig_6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s51', FS(-123456789012345.678, '<Integer,5,>'));
        Observer.Observe('s52', FS(-123456789012345.678, '<Precision,a:b>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Zero_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s1', FS(0, '<Precision,2:2>'));
        Observer.Observe('s2', FS(0, '<Precision,0:3>'));
        Observer.Observe('s3', FS(0, '<Precision,3:3>'));
        Observer.Observe('s4', FS(0, '<Precision,2>'));
        Observer.Observe('s5', FS(0, '<Precision,:2>'));
        Observer.Observe('s6', FS(0, '<Precision,0:0>'));
        Observer.Observe('s7', FS(0, '<Precision,10:10>'));
        Observer.Observe('s8', FS(0, '<Sign>'));
        Observer.Observe('s9', FS(0, '<Sign,1>'));
        Observer.Observe('s10', FS(0, '<Sign,2>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Zero_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s11', FS(0, '<Integer>'));
        Observer.Observe('s12', FS(0, '<Integer Thousand>'));
        Observer.Observe('s13', FS(0, '<Decimals>'));
        Observer.Observe('s14', FS(0, '<Decimals,3>'));
        Observer.Observe('s15', FS(0, '<Decimals,0>'));
        Observer.Observe('s16', FS(0, '<Integer><Decimal Separator><Decimals>'));
        Observer.Observe('s17', FS(0, '<Integer Thousand><Decimal Separator><Decimals>'));
        Observer.Observe('s18', FS(0, '<Sign><Integer Thousand><Decimals>'));
        Observer.Observe('s19', FS(0, '<Sign><Integer><Decimal Separator><Decimals>'));
        Observer.Observe('s20', FS(0, '<Thousand Separator>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Zero_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s21', FS(0, '<Decimal Separator>'));
        Observer.Observe('s22', FS(0, '<Integer,10><Decimals,3>'));
        Observer.Observe('s23', FS(0, '<Integer,10><Filler Character,0><Decimals,3>'));
        Observer.Observe('s24', FS(0, '<Filler Character,#><Integer,8>'));
        Observer.Observe('s25', FS(0, '<Standard Format,0>'));
        Observer.Observe('s26', FS(0, '<Standard Format,1>'));
        Observer.Observe('s27', FS(0, '<Standard Format,2>'));
        Observer.Observe('s28', FS(0, '<Standard Format,3>'));
        Observer.Observe('s29', FS(0, '<Standard Format,4>'));
        Observer.Observe('s30', FS(0, '<Standard Format,5>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Zero_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s31', FS(0, '<Standard Format,6>'));
        Observer.Observe('s32', FS(0, '<Standard Format,7>'));
        Observer.Observe('s33', FS(0, '<Standard Format,8>'));
        Observer.Observe('s34', FS(0, '<Standard Format,9>'));
        Observer.Observe('s35', FS(0, '<Standard Format,10>'));
        Observer.Observe('s36', FS(0, '<Standard Format>'));
        Observer.Observe('s37', FS(0, '<Sign><Precision,2:2>'));
        Observer.Observe('s38', FS(0, '<Precision,2:2><Sign>'));
        Observer.Observe('s39', FS(0, '<Integer Thousand><Precision,2:2>'));
        Observer.Observe('s40', FS(0, '<Precision,2:2><Integer Thousand>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Zero_5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s41', FS(0, '<Sign,1><Integer Thousand><Decimals,2>'));
        Observer.Observe('s42', FS(0, '<Sign,2><Integer><Decimals>'));
        Observer.Observe('s43', FS(0, '<1000 Separator>'));
        Observer.Observe('s44', FS(0, '<Currency Symbol>'));
        Observer.Observe('s45', FS(0, '<Unknown>'));
        Observer.Observe('s46', FS(0, '<Precision,2:2'));
        Observer.Observe('s47', FS(0, 'Precision,2:2>'));
        Observer.Observe('s48', FS(0, 'abc'));
        Observer.Observe('s49', FS(0, ''));
        Observer.Observe('s50', FS(0, 'x<Precision,2:2>y'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Zero_6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s51', FS(0, '<Integer,5,>'));
        Observer.Observe('s52', FS(0, '<Precision,a:b>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Tiny_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s1', FS(0.00001, '<Precision,2:2>'));
        Observer.Observe('s2', FS(0.00001, '<Precision,0:3>'));
        Observer.Observe('s3', FS(0.00001, '<Precision,3:3>'));
        Observer.Observe('s4', FS(0.00001, '<Precision,2>'));
        Observer.Observe('s5', FS(0.00001, '<Precision,:2>'));
        Observer.Observe('s6', FS(0.00001, '<Precision,0:0>'));
        Observer.Observe('s7', FS(0.00001, '<Precision,10:10>'));
        Observer.Observe('s8', FS(0.00001, '<Sign>'));
        Observer.Observe('s9', FS(0.00001, '<Sign,1>'));
        Observer.Observe('s10', FS(0.00001, '<Sign,2>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Tiny_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s11', FS(0.00001, '<Integer>'));
        Observer.Observe('s12', FS(0.00001, '<Integer Thousand>'));
        Observer.Observe('s13', FS(0.00001, '<Decimals>'));
        Observer.Observe('s14', FS(0.00001, '<Decimals,3>'));
        Observer.Observe('s15', FS(0.00001, '<Decimals,0>'));
        Observer.Observe('s16', FS(0.00001, '<Integer><Decimal Separator><Decimals>'));
        Observer.Observe('s17', FS(0.00001, '<Integer Thousand><Decimal Separator><Decimals>'));
        Observer.Observe('s18', FS(0.00001, '<Sign><Integer Thousand><Decimals>'));
        Observer.Observe('s19', FS(0.00001, '<Sign><Integer><Decimal Separator><Decimals>'));
        Observer.Observe('s20', FS(0.00001, '<Thousand Separator>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Tiny_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s21', FS(0.00001, '<Decimal Separator>'));
        Observer.Observe('s22', FS(0.00001, '<Integer,10><Decimals,3>'));
        Observer.Observe('s23', FS(0.00001, '<Integer,10><Filler Character,0><Decimals,3>'));
        Observer.Observe('s24', FS(0.00001, '<Filler Character,#><Integer,8>'));
        Observer.Observe('s25', FS(0.00001, '<Standard Format,0>'));
        Observer.Observe('s26', FS(0.00001, '<Standard Format,1>'));
        Observer.Observe('s27', FS(0.00001, '<Standard Format,2>'));
        Observer.Observe('s28', FS(0.00001, '<Standard Format,3>'));
        Observer.Observe('s29', FS(0.00001, '<Standard Format,4>'));
        Observer.Observe('s30', FS(0.00001, '<Standard Format,5>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Tiny_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s31', FS(0.00001, '<Standard Format,6>'));
        Observer.Observe('s32', FS(0.00001, '<Standard Format,7>'));
        Observer.Observe('s33', FS(0.00001, '<Standard Format,8>'));
        Observer.Observe('s34', FS(0.00001, '<Standard Format,9>'));
        Observer.Observe('s35', FS(0.00001, '<Standard Format,10>'));
        Observer.Observe('s36', FS(0.00001, '<Standard Format>'));
        Observer.Observe('s37', FS(0.00001, '<Sign><Precision,2:2>'));
        Observer.Observe('s38', FS(0.00001, '<Precision,2:2><Sign>'));
        Observer.Observe('s39', FS(0.00001, '<Integer Thousand><Precision,2:2>'));
        Observer.Observe('s40', FS(0.00001, '<Precision,2:2><Integer Thousand>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Tiny_5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s41', FS(0.00001, '<Sign,1><Integer Thousand><Decimals,2>'));
        Observer.Observe('s42', FS(0.00001, '<Sign,2><Integer><Decimals>'));
        Observer.Observe('s43', FS(0.00001, '<1000 Separator>'));
        Observer.Observe('s44', FS(0.00001, '<Currency Symbol>'));
        Observer.Observe('s45', FS(0.00001, '<Unknown>'));
        Observer.Observe('s46', FS(0.00001, '<Precision,2:2'));
        Observer.Observe('s47', FS(0.00001, 'Precision,2:2>'));
        Observer.Observe('s48', FS(0.00001, 'abc'));
        Observer.Observe('s49', FS(0.00001, ''));
        Observer.Observe('s50', FS(0.00001, 'x<Precision,2:2>y'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_Tiny_6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s51', FS(0.00001, '<Integer,5,>'));
        Observer.Observe('s52', FS(0.00001, '<Precision,a:b>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_NegHalf_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s1', FS(-0.5, '<Precision,2:2>'));
        Observer.Observe('s2', FS(-0.5, '<Precision,0:3>'));
        Observer.Observe('s3', FS(-0.5, '<Precision,3:3>'));
        Observer.Observe('s4', FS(-0.5, '<Precision,2>'));
        Observer.Observe('s5', FS(-0.5, '<Precision,:2>'));
        Observer.Observe('s6', FS(-0.5, '<Precision,0:0>'));
        Observer.Observe('s7', FS(-0.5, '<Precision,10:10>'));
        Observer.Observe('s8', FS(-0.5, '<Sign>'));
        Observer.Observe('s9', FS(-0.5, '<Sign,1>'));
        Observer.Observe('s10', FS(-0.5, '<Sign,2>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_NegHalf_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s11', FS(-0.5, '<Integer>'));
        Observer.Observe('s12', FS(-0.5, '<Integer Thousand>'));
        Observer.Observe('s13', FS(-0.5, '<Decimals>'));
        Observer.Observe('s14', FS(-0.5, '<Decimals,3>'));
        Observer.Observe('s15', FS(-0.5, '<Decimals,0>'));
        Observer.Observe('s16', FS(-0.5, '<Integer><Decimal Separator><Decimals>'));
        Observer.Observe('s17', FS(-0.5, '<Integer Thousand><Decimal Separator><Decimals>'));
        Observer.Observe('s18', FS(-0.5, '<Sign><Integer Thousand><Decimals>'));
        Observer.Observe('s19', FS(-0.5, '<Sign><Integer><Decimal Separator><Decimals>'));
        Observer.Observe('s20', FS(-0.5, '<Thousand Separator>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_NegHalf_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s21', FS(-0.5, '<Decimal Separator>'));
        Observer.Observe('s22', FS(-0.5, '<Integer,10><Decimals,3>'));
        Observer.Observe('s23', FS(-0.5, '<Integer,10><Filler Character,0><Decimals,3>'));
        Observer.Observe('s24', FS(-0.5, '<Filler Character,#><Integer,8>'));
        Observer.Observe('s25', FS(-0.5, '<Standard Format,0>'));
        Observer.Observe('s26', FS(-0.5, '<Standard Format,1>'));
        Observer.Observe('s27', FS(-0.5, '<Standard Format,2>'));
        Observer.Observe('s28', FS(-0.5, '<Standard Format,3>'));
        Observer.Observe('s29', FS(-0.5, '<Standard Format,4>'));
        Observer.Observe('s30', FS(-0.5, '<Standard Format,5>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_NegHalf_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s31', FS(-0.5, '<Standard Format,6>'));
        Observer.Observe('s32', FS(-0.5, '<Standard Format,7>'));
        Observer.Observe('s33', FS(-0.5, '<Standard Format,8>'));
        Observer.Observe('s34', FS(-0.5, '<Standard Format,9>'));
        Observer.Observe('s35', FS(-0.5, '<Standard Format,10>'));
        Observer.Observe('s36', FS(-0.5, '<Standard Format>'));
        Observer.Observe('s37', FS(-0.5, '<Sign><Precision,2:2>'));
        Observer.Observe('s38', FS(-0.5, '<Precision,2:2><Sign>'));
        Observer.Observe('s39', FS(-0.5, '<Integer Thousand><Precision,2:2>'));
        Observer.Observe('s40', FS(-0.5, '<Precision,2:2><Integer Thousand>'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_NegHalf_5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s41', FS(-0.5, '<Sign,1><Integer Thousand><Decimals,2>'));
        Observer.Observe('s42', FS(-0.5, '<Sign,2><Integer><Decimals>'));
        Observer.Observe('s43', FS(-0.5, '<1000 Separator>'));
        Observer.Observe('s44', FS(-0.5, '<Currency Symbol>'));
        Observer.Observe('s45', FS(-0.5, '<Unknown>'));
        Observer.Observe('s46', FS(-0.5, '<Precision,2:2'));
        Observer.Observe('s47', FS(-0.5, 'Precision,2:2>'));
        Observer.Observe('s48', FS(-0.5, 'abc'));
        Observer.Observe('s49', FS(-0.5, ''));
        Observer.Observe('s50', FS(-0.5, 'x<Precision,2:2>y'));
        Observer.Finish();
    end;

    [Test]
    procedure Str_NegHalf_6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s51', FS(-0.5, '<Integer,5,>'));
        Observer.Observe('s52', FS(-0.5, '<Precision,a:b>'));
        Observer.Finish();
    end;

    [Test]
    procedure Len_WithFormatString()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('l1', FL(1234.5, 10, '<Precision,2:2>'));
        Observer.Observe('l2', FL(1234.5, 3, '<Precision,2:2>'));
        Observer.Observe('l3', FL(-1234.5, 10, '<Sign><Integer Thousand><Decimals>'));
        Observer.Observe('l4', FL(1234.5, 1, '<Integer Thousand>'));
        Observer.Observe('l5', FL(0, 5, '<Precision,2:2>'));
        Observer.Observe('l6', FL(1234.5, 10, '<Standard Format,0>'));
        Observer.Observe('l7', FL(1234.5, 10, '<Standard Format,1>'));
        Observer.Observe('l8', FL(1234.5, 0, '<Standard Format,9>'));
        Observer.Observe('l9', FL(1234.5, 20, '<Standard Format,9>'));
        Observer.Observe('l10', FL(-0.5, 8, '<Integer><Decimal Separator><Decimals>'));
        Observer.Finish();
    end;
}

