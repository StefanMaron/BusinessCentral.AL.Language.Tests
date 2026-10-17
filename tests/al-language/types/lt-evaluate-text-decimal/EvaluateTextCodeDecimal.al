// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunit 74889
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: Evaluate into a Text and a Code[n] with and without a format number (0, 1, 2, 9): the stored value and its length for leading and trailing blanks,
//   text longer than the variable, lower case; Evaluate into a Decimal for mixed letter and digit text ('attributeValue1', 'uri1', 'EU1', '12D', '1E3', '1,5', ...):
//   which are rejected, the error text and code, and the value left in the variable; the same with format number 9.
// BC versions: all (CI)

codeunit 74889 "LT EVT Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure EvText(var Observer: Codeunit "Probe Observer"; Tag: Text; Input: Text; Format2: Integer)
    var
        T: Text;
        Ok: Boolean;
    begin
        T := 'before';
        Ok := Evaluate(T, Input, Format2);
        Observer.Observe(Tag + 'Ok', Format(Ok));
        if Ok then
            Observer.Observe(Tag + 'Value', '[' + T + '] len=' + Format(StrLen(T)))
        else begin
            Observer.ObserveError(Tag + 'Err');
            Observer.Observe(Tag + 'Kept', '[' + T + ']');
        end;
    end;

    local procedure EvCode(var Observer: Codeunit "Probe Observer"; Tag: Text; Input: Text; Format2: Integer)
    var
        C: Code[5];
        Ok: Boolean;
    begin
        C := 'BEF';
        Ok := Evaluate(C, Input, Format2);
        Observer.Observe(Tag + 'Ok', Format(Ok));
        if Ok then
            Observer.Observe(Tag + 'Value', '[' + C + '] len=' + Format(StrLen(C)))
        else begin
            Observer.ObserveError(Tag + 'Err');
            Observer.Observe(Tag + 'Kept', '[' + C + ']');
        end;
    end;

    local procedure EvDec(var Observer: Codeunit "Probe Observer"; Tag: Text; Input: Text; Format2: Integer)
    var
        D: Decimal;
        Ok: Boolean;
    begin
        D := 7;
        if Format2 < 0 then
            Ok := Evaluate(D, Input)
        else
            Ok := Evaluate(D, Input, Format2);
        Observer.Observe(Tag + 'Ok', Format(Ok));
        if Ok then
            Observer.Observe(Tag + 'Value', Format(D, 0, 9))
        else begin
            Observer.ObserveError(Tag + 'Err');
            Observer.Observe(Tag + 'Kept', Format(D, 0, 9));
        end;
    end;

    [Test]
    procedure Text_FormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        n: Integer;
    begin
        for n := 0 to 2 do begin
            EvText(Observer, 'plain' + Format(n), 'abc', n);
            EvText(Observer, 'lead' + Format(n), '  abc', n);
            EvText(Observer, 'trail' + Format(n), 'abc  ', n);
            EvText(Observer, 'empty' + Format(n), '', n);
            EvText(Observer, 'blank' + Format(n), '   ', n);
        end;
        EvText(Observer, 'plain9', 'abc', 9);
        EvText(Observer, 'lead9', '  abc', 9);
        EvText(Observer, 'trail9', 'abc  ', 9);
        EvText(Observer, 'amp9', 'a&amp;b', 9);
        Observer.Finish();
    end;

    [Test]
    procedure Code_FormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        n: Integer;
    begin
        for n := 0 to 2 do begin
            EvCode(Observer, 'lower' + Format(n), 'abc', n);
            EvCode(Observer, 'exact' + Format(n), 'abcde', n);
            EvCode(Observer, 'trailFits' + Format(n), 'abcde   ', n);
            EvCode(Observer, 'tooLong' + Format(n), 'abcdef', n);
            EvCode(Observer, 'leadBlank' + Format(n), '  abc', n);
            EvCode(Observer, 'leadFull' + Format(n), ' abcde', n);
            EvCode(Observer, 'blank' + Format(n), '   ', n);
        end;
        EvCode(Observer, 'lower9', 'abc', 9);
        EvCode(Observer, 'trailFits9', 'abcde   ', 9);
        EvCode(Observer, 'tooLong9', 'abcdef', 9);
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_MixedLetterDigit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvDec(Observer, 'attributeValue1', 'attributeValue1', -1);
        EvDec(Observer, 'uri1', 'uri1', -1);
        EvDec(Observer, 'EU1', 'EU1', -1);
        EvDec(Observer, 'd12', '12D', -1);
        EvDec(Observer, 'lowerd12', '12d', -1);
        EvDec(Observer, 'e1e3', '1E3', -1);
        EvDec(Observer, 'lowere1e3', '1e3', -1);
        EvDec(Observer, 'comma15', '1,5', -1);
        EvDec(Observer, 'e5', 'E5', -1);
        EvDec(Observer, 'x1', 'x1', -1);
        EvDec(Observer, 'onex', '1x', -1);
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_OtherInputs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvDec(Observer, 'e', '1E', -1);
        EvDec(Observer, 'eMinus', '1E-2', -1);
        EvDec(Observer, 'ePlus', '1E+2', -1);
        EvDec(Observer, 'frac', '1.5E2', -1);
        EvDec(Observer, 'dFrac', '1.5D', -1);
        EvDec(Observer, 'dd', '1D2', -1);
        EvDec(Observer, 'onlyD', 'D', -1);
        EvDec(Observer, 'plus', '+5', -1);
        EvDec(Observer, 'dash', '-', -1);
        EvDec(Observer, 'dot', '.5', -1);
        EvDec(Observer, 'trailDot', '5.', -1);
        EvDec(Observer, 'hex', '0x10', -1);
        EvDec(Observer, 'inner', '1 2', -1);
        EvDec(Observer, 'padded', ' 12 ', -1);
        EvDec(Observer, 'thousands', '1,000.5', -1);
        EvDec(Observer, 'percent', '5%', -1);
        EvDec(Observer, 'empty', '', -1);
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_MixedLetterDigit_Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvDec(Observer, 'attributeValue1', 'attributeValue1', 9);
        EvDec(Observer, 'uri1', 'uri1', 9);
        EvDec(Observer, 'EU1', 'EU1', 9);
        EvDec(Observer, 'd12', '12D', 9);
        EvDec(Observer, 'e1e3', '1E3', 9);
        EvDec(Observer, 'lowere1e3', '1e3', 9);
        EvDec(Observer, 'comma15', '1,5', 9);
        EvDec(Observer, 'dot15', '1.5', 9);
        Observer.Finish();
    end;
}
