// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// StrLen of text, code, empty, unicode, trailing blanks, long text.
// BC versions: 29 (27 and 28 by CI)

codeunit 70500 "LT TxB StrLen"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        T: Text;
        T2: Text;
        T5: Text[5];
        C5: Code[5];
        C10: Code[10];
        I: Integer;
        D: Decimal;
        TLabel: Label 'Hello World', Locked = true;
        CLabel: Label 'abc', Locked = true, MaxLength = 10;

    [Test]
    procedure StrLenBasic()
    begin
        Obs.Observe('a1', Format(StrLen('')));
        Obs.Observe('a2', Format(StrLen('a')));
        Obs.Observe('a3', Format(StrLen('Hello')));
        Obs.Observe('a4', Format(StrLen('  ')));
        Obs.Observe('a5', Format(StrLen(' a ')));
        Obs.Observe('a6', Format(StrLen('abc   ')));
        Obs.Observe('a7', Format(StrLen('äöü')));
        Obs.Observe('a8', Format(StrLen('日本語')));
        Obs.Observe('a9', Format(StrLen('a'+'b')));
        Obs.Observe('a10', Format(StrLen(PadStr('',100,'x'))));
        Obs.Observe('a11', Format(StrLen(TLabel)));
        Obs.Observe('a12', Format(StrLen(CLabel)));
        Obs.Expect('a1', '0');
        Obs.Expect('a2', '1');
        Obs.Expect('a3', '5');
        Obs.Expect('a4', '2');
        Obs.Expect('a5', '3');
        Obs.Expect('a6', '6');
        Obs.Expect('a7', '3');
        Obs.Expect('a8', '3');
        Obs.Expect('a9', '2');
        Obs.Expect('a10', '100');
        Obs.Expect('a11', '11');
        Obs.Expect('a12', '3');
        Obs.Verify();
    end;

    [Test]
    procedure StrLenVariables()
    begin
        T := 'abc  ';
        C5 := '  ab ';
        T5 := 'abcde';
        Obs.Observe('t', Format(StrLen(T)));
        Obs.Observe('c', Format(StrLen(C5)));
        Obs.Observe('t5', Format(StrLen(T5)));
        T := '';
        Obs.Observe('empty', Format(StrLen(T)));
        Clear(C5);
        Obs.Observe('clear', Format(StrLen(C5)));
        T := PadStr('',2000,'a');
        Obs.Observe('long', Format(StrLen(T)));
        T := T + T;
        Obs.Observe('long2', Format(StrLen(T)));
        Obs.Observe('lowerc', Format(StrLen(LowerCase('ABC'))));
        Obs.Observe('fmt', Format(StrLen(Format(12345))));
        Obs.Observe('fmtneg', Format(StrLen(Format(-1.5))));
        Obs.Expect('t', '5');
        Obs.Expect('c', '2');
        Obs.Expect('t5', '5');
        Obs.Expect('empty', '0');
        Obs.Expect('clear', '0');
        Obs.Expect('long', '2000');
        Obs.Expect('long2', '4000');
        Obs.Expect('lowerc', '3');
        Obs.Expect('fmt', '5');
        Obs.Expect('fmtneg', '4');
        Obs.Verify();
    end;

}
