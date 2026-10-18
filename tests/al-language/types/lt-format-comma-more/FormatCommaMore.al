// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope. Format with a format string that contains <Comma,...>.
// Fixtures used: Probe Observer (69160) from the AL Language Coverage Tests app; self-contained codeunit 67357
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: <Comma,,> before <Decimals>; <Comma,.> with <Integer Thousand> and <Decimals,3>; <Comma,.> on a Decimal, a BigInteger, a Duration and a DateTime. A format string BC rejects is recorded as error text and code.
//   No locale-dependent value: the session language is set to 1033 for the run and restored.
//   Corpus issue 576 item 3.
// BC versions: 27, 28, 29

codeunit 67357 "LT FCM Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFormat(Value: Variant; Fmt: Text; var Result: Text)
    begin
        Result := Format(Value, 0, Fmt);
    end;

    local procedure Run(Name: Text; Value: Variant; Fmt: Text; var Observer: Codeunit "Probe Observer")
    var
        Result: Text;
    begin
        ClearLastError();
        Result := '';
        if TryFormat(Value, Fmt, Result) then
            Observer.Observe(Name, 'ok:' + Result)
        else begin
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
    end;

    [Test]
    procedure Format_CommaBeforeDecimals_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        Run('big', 1234567.891, '<Integer><Comma,,><Decimals>', Observer);
        Run('small', 0.5, '<Integer><Comma,,><Decimals>', Observer);
        Run('negative', -1234.5, '<Integer><Comma,,><Decimals>', Observer);
        Run('whole', 1000, '<Integer><Comma,,><Decimals>', Observer);
        Run('thousand_big', 1234567.891, '<Integer Thousand><Comma,,><Decimals>', Observer);
        Run('dot_big', 1234567.891, '<Integer><Comma,.><Decimals>', Observer);
        Run('dot_whole', 1000, '<Integer><Comma,.><Decimals>', Observer);
        GlobalLanguage(Saved);
        Observer.Finish();
    end;

    [Test]
    procedure Format_CommaWithThousandAndWidth_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        Run('thousand_dot_dec3', 1234567.891, '<Integer Thousand><Comma,.><Decimals,3>', Observer);
        Run('thousand_dot_dec3_whole', 1234567, '<Integer Thousand><Comma,.><Decimals,3>', Observer);
        Run('thousand_dot_dec3_small', 0.5, '<Integer Thousand><Comma,.><Decimals,3>', Observer);
        Run('thousand_dot_dec3_negative', -1234.5, '<Integer Thousand><Comma,.><Decimals,3>', Observer);
        Run('width10', 1234.5, '<Integer,10><Comma,.><Decimals,3>', Observer);
        Run('thousand_width12', 1234567.891, '<Integer Thousand,12><Comma,.><Decimals,3>', Observer);
        Run('sign', -1234.5, '<Sign><Integer Thousand><Comma,.><Decimals,2>', Observer);
        Run('padded', 1234.5, '<Integer,8><Filler Character,0><Comma,.><Decimals,2>', Observer);
        GlobalLanguage(Saved);
        Observer.Finish();
    end;

    [Test]
    procedure Format_CommaOnOtherTypes()
    var
        Observer: Codeunit "Probe Observer";
        BigValue: BigInteger;
        Dur: Duration;
        Stamp: DateTime;
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        BigValue := 1234567890123L;
        Dur := 3723000;
        Stamp := CreateDateTime(DMY2Date(15, 6, 2026), 134500T);
        Run('biginteger', BigValue, '<Integer Thousand><Comma,.><Decimals>', Observer);
        Run('biginteger_comma', BigValue, '<Integer><Comma,,><Decimals>', Observer);
        Run('duration', Dur, '<Integer Thousand><Comma,.><Decimals>', Observer);
        Run('duration_comma', Dur, '<Integer><Comma,,><Decimals>', Observer);
        Run('datetime', Stamp, '<Integer Thousand><Comma,.><Decimals>', Observer);
        Run('datetime_comma', Stamp, '<Integer><Comma,,><Decimals>', Observer);
        GlobalLanguage(Saved);
        Observer.Finish();
    end;
}
