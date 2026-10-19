// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// MaxStrLen for Text, Code, labels.
// BC versions: 29 (27 and 28 by CI)

codeunit 70512 "LT TxB MaxStrLen"
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
    procedure MaxStrLenVariables()
    begin
        T5 := '';
        C5 := '';
        C10 := '';
        Obs.Observe('t5', Format(MaxStrLen(T5)));
        Obs.Observe('c5', Format(MaxStrLen(C5)));
        Obs.Observe('c10', Format(MaxStrLen(C10)));
        Obs.Observe('t', Format(MaxStrLen(T)));
        T := 'abc';
        Obs.Observe('tafter', Format(MaxStrLen(T)));
        T5 := 'abc';
        Obs.Observe('t5after', Format(MaxStrLen(T5)));
        T := PadStr('',100,'x');
        Obs.Observe('tlong', Format(MaxStrLen(T)));
        Clear(T5);
        Obs.Observe('t5clear', Format(MaxStrLen(T5)));
        Obs.Observe('label', Format(MaxStrLen(TLabel)));
        Obs.Observe('labelc', Format(MaxStrLen(CLabel)));
        Obs.Observe('literal', Format(MaxStrLen('abc')));
        Obs.Observe('emptyliteral', Format(MaxStrLen('')));
        Obs.Observe('copy', Format(MaxStrLen(CopyStr('abc',1))));
        Obs.Observe('lower', Format(MaxStrLen(LowerCase('abc'))));
        Obs.Expect('t5', '5');
        Obs.Expect('c5', '5');
        Obs.Expect('c10', '10');
        Obs.Expect('t', '2147483647');
        Obs.Expect('tafter', '2147483647');
        Obs.Expect('t5after', '5');
        Obs.Expect('tlong', '2147483647');
        Obs.Expect('t5clear', '5');
        Obs.Expect('label', '2048');
        Obs.Expect('labelc', '2048');
        Obs.Expect('literal', '2147483647');
        Obs.Expect('emptyliteral', '2147483647');
        Obs.Expect('copy', '2147483647');
        Obs.Expect('lower', '2147483647');
        Obs.Verify();
    end;

    [Test]
    procedure MaxStrLenSubstTemp()
    begin
        T2 := 'x';
        T := PadStr('',10,'a');
        Obs.Observe('fmt', Format(MaxStrLen(Format(1))));
        Obs.Observe('t2', Format(MaxStrLen(T2)));
        C5 := 'abcde';
        Obs.Observe('c5full', Format(MaxStrLen(C5)));
        Obs.Observe('c5len', Format(StrLen(C5)));
        Obs.Observe('sameBoth', Format(MaxStrLen(T5) = MaxStrLen(C5)));
        Obs.Observe('vs', Format(MaxStrLen(C10) > MaxStrLen(C5)));
        Obs.Expect('fmt', '2147483647');
        Obs.Expect('t2', '2147483647');
        Obs.Expect('c5full', '5');
        Obs.Expect('c5len', '5');
        Obs.Expect('sameBoth', 'Yes');
        Obs.Expect('vs', 'Yes');
        Obs.Verify();
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 45: MaxStrLen of a Text parameter. Reported as 2147483647 for a
    // var Text parameter on BC 16 to 19 (NAV 2018 gave the length of the argument). A Code[20] argument for a var Text
    // parameter does not compile (AL0133, tests/must-not-compile/cases/1538).
    [Test]
    procedure LT_BU_MaxStrLen_TextParameters()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record Item;
        T30: Text[30];
        T: Text;
        C20: Code[20];
    begin
        Observer.Observe('var text with field text100', Format(MaxOfVarText(Item.Description)));
        Observer.Observe('var text with text30', Format(MaxOfVarText(T30)));
        Observer.Observe('var text with text', Format(MaxOfVarText(T)));
        Observer.Observe('var text30 with field text100', Format(MaxOfVarText30(Item.Description)));
        Observer.Observe('var text30 with text30', Format(MaxOfVarText30(T30)));
        Observer.Observe('text with field text100', Format(MaxOfText(Item.Description)));
        Observer.Observe('text with code20', Format(MaxOfText(C20)));
        Observer.Observe('text30 with field text100', Format(MaxOfText30(Item.Description)));
        Observer.Observe('var code30 with code20', Format(MaxOfVarCode30(C20)));
        Observer.Finish();
    end;

    local procedure MaxOfVarText(var s: Text): Integer
    begin
        exit(MaxStrLen(s));
    end;

    local procedure MaxOfVarText30(var s: Text[30]): Integer
    begin
        exit(MaxStrLen(s));
    end;

    local procedure MaxOfText(s: Text): Integer
    begin
        exit(MaxStrLen(s));
    end;

    local procedure MaxOfText30(s: Text[30]): Integer
    begin
        exit(MaxStrLen(s));
    end;

    local procedure MaxOfVarCode30(var s: Code[30]): Integer
    begin
        exit(MaxStrLen(s));
    end;
}
