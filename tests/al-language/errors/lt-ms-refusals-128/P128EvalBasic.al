// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73169, codeunit 73168
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Evaluate into a Code variable ('' and blanks, case, exact length, too long; the previous value after a failure) and into a Text variable (empty text, a Text[n] that is too short), with and
// without the Boolean result used; Evaluate into an Option that is neither an ordinal nor a member name, with numeric OptionCaptions (ordinal 0..2 against captions 1..3).
// BC versions: 29 (27 and 28 by CI)

table 73169 "LT P128 Eval Opt"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; NumCap; Option)
        {
            OptionMembers = A,B,C;
            OptionCaption = '1,2,3';
        }
        field(3; Words; Option)
        {
            OptionMembers = Zero,One,Two;
            OptionCaption = 'Ten,Twenty,Thirty';
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73168 "LT P128 Eval Basic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure EvalCode(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        C: Code[5];
        Ok: Boolean;
    begin
        C := 'KEEP';
        Ok := Evaluate(C, Txt);
        Observer.Observe(Name, Format(Ok) + '|[' + C + ']');
    end;

    local procedure EvalText(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        T: Text;
        Ok: Boolean;
    begin
        T := 'KEEP';
        Ok := Evaluate(T, Txt);
        Observer.Observe(Name, Format(Ok) + '|[' + T + ']');
    end;

    [TryFunction]
    local procedure TryEvalCodeUnused(Txt: Text; var C: Code[5])
    begin
        Evaluate(C, Txt);
    end;

    [TryFunction]
    local procedure TryEvalShortTextUnused(Txt: Text; var T: Text[5])
    begin
        Evaluate(T, Txt);
    end;

    local procedure EvalShortText(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        T: Text[5];
        Ok: Boolean;
    begin
        T := 'KEEP';
        if TryEvalShortTextUnused(Txt, T) then
            Observer.Observe(Name, 'ok|[' + T + ']')
        else begin
            Observer.ObserveError(Name);
            Ok := false;
        end;
    end;

    [Test]
    procedure P128_Evaluate_IntoCode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalCode(Observer, 'empty', '');
        EvalCode(Observer, 'lower', 'abc');
        EvalCode(Observer, 'padded', ' ab ');
        EvalCode(Observer, 'inner blank', 'a b');
        EvalCode(Observer, 'exact length', 'abcde');
        EvalCode(Observer, 'one too long', 'abcdef');
        EvalCode(Observer, 'blank only', ' ');
        EvalCode(Observer, 'digits', '00123');
        EvalCode(Observer, 'unicode', 'äbc');
        Observer.Expect('empty', 'Yes|[]');
        Observer.Expect('lower', 'Yes|[ABC]');
        Observer.Expect('padded', 'Yes|[AB]');
        Observer.Expect('inner blank', 'Yes|[A B]');
        Observer.Expect('exact length', 'Yes|[ABCDE]');
        Observer.Expect('one too long', 'No|[KEEP]');
        Observer.Expect('blank only', 'Yes|[]');
        Observer.Expect('digits', 'Yes|[00123]');
        Observer.Expect('unicode', 'Yes|[ÄBC]');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Evaluate_IntoCode_ResultUnused()
    var
        Observer: Codeunit "Probe Observer";
        C: Code[5];
    begin
        C := 'KEEP';
        if TryEvalCodeUnused('', C) then
            Observer.Observe('empty', 'ok|[' + C + ']')
        else
            Observer.ObserveError('empty');
        C := 'KEEP';
        if TryEvalCodeUnused('abc', C) then
            Observer.Observe('abc', 'ok|[' + C + ']')
        else
            Observer.ObserveError('abc');
        C := 'KEEP';
        if TryEvalCodeUnused('abcdef', C) then
            Observer.Observe('too long', 'ok|[' + C + ']')
        else
            Observer.ObserveError('too long');
        Observer.Expect('empty', 'ok|[]');
        Observer.Expect('abc', 'ok|[ABC]');
        Observer.Expect('too long|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Observer.Expect('too long|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Evaluate_IntoText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalText(Observer, 'empty', '');
        EvalText(Observer, 'plain', 'hello');
        EvalText(Observer, 'padded', ' hello ');
        EvalText(Observer, 'blank only', ' ');
        EvalText(Observer, 'quotes', '''a''');
        EvalText(Observer, 'unicode', 'äöü');
        Observer.Expect('empty', 'Yes|[]');
        Observer.Expect('plain', 'Yes|[hello]');
        Observer.Expect('padded', 'Yes|[ hello ]');
        Observer.Expect('blank only', 'Yes|[ ]');
        Observer.Expect('quotes', 'Yes|[''a'']');
        Observer.Expect('unicode', 'Yes|[äöü]');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Evaluate_IntoShortText_ResultUnused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalShortText(Observer, 'empty', '');
        EvalShortText(Observer, 'fits', 'abcde');
        EvalShortText(Observer, 'too long', 'abcdef');
        Observer.Expect('empty', 'ok|[]');
        Observer.Expect('fits', 'ok|[abcde]');
        Observer.Expect('too long|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Observer.Expect('too long|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Evaluate_IntoOption_LocalVariable()
    var
        Observer: Codeunit "Probe Observer";
        Opt: Option A,B;
        Ok: Boolean;
    begin
        Opt := Opt::B;
        Ok := Evaluate(Opt, '2');
        Observer.Observe('ordinal 2 of 2 members', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, '-1');
        Observer.Observe('minus 1', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, ' 0 ');
        Observer.Observe('padded 0', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, '1.0');
        Observer.Observe('1.0', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, 'a');
        Observer.Observe('lower a', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, '1x');
        Observer.Observe('1x', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, '+1');
        Observer.Observe('plus 1', Format(Ok) + '|' + Format(Opt));
        Observer.Expect('ordinal 2 of 2 members', 'Yes|2');
        Observer.Expect('minus 1', 'No|2');
        Observer.Expect('padded 0', 'Yes|A');
        Observer.Expect('1.0', 'No|A');
        Observer.Expect('lower a', 'Yes|A');
        Observer.Expect('1x', 'No|A');
        Observer.Expect('plus 1', 'Yes|B');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Evaluate_IntoOptionField_NumericCaptions()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P128 Eval Opt";
        Ok: Boolean;
    begin
        Row.NumCap := Row.NumCap::A;
        Ok := Evaluate(Row.NumCap, '0');
        Observer.Observe('0', Format(Ok) + '|' + Format(Row.NumCap) + '|' + Format(Row.NumCap, 0, 2));
        Ok := Evaluate(Row.NumCap, '1');
        Observer.Observe('1', Format(Ok) + '|' + Format(Row.NumCap) + '|' + Format(Row.NumCap, 0, 2));
        Ok := Evaluate(Row.NumCap, '2');
        Observer.Observe('2', Format(Ok) + '|' + Format(Row.NumCap) + '|' + Format(Row.NumCap, 0, 2));
        Ok := Evaluate(Row.NumCap, '3');
        Observer.Observe('3 (caption of C, no such ordinal)', Format(Ok) + '|' + Format(Row.NumCap) + '|' + Format(Row.NumCap, 0, 2));
        Ok := Evaluate(Row.NumCap, '4');
        Observer.Observe('4', Format(Ok) + '|' + Format(Row.NumCap) + '|' + Format(Row.NumCap, 0, 2));
        Ok := Evaluate(Row.Words, 'Twenty');
        Observer.Observe('caption Twenty', Format(Ok) + '|' + Format(Row.Words) + '|' + Format(Row.Words, 0, 2));
        Ok := Evaluate(Row.Words, 'twenty');
        Observer.Observe('caption twenty lower', Format(Ok) + '|' + Format(Row.Words) + '|' + Format(Row.Words, 0, 2));
        Ok := Evaluate(Row.Words, 'Two');
        Observer.Observe('member Two', Format(Ok) + '|' + Format(Row.Words) + '|' + Format(Row.Words, 0, 2));
        Ok := Evaluate(Row.Words, 'Thirty');
        Observer.Observe('caption Thirty', Format(Ok) + '|' + Format(Row.Words) + '|' + Format(Row.Words, 0, 2));
        Ok := Evaluate(Row.Words, 'Three');
        Observer.Observe('neither Three', Format(Ok) + '|' + Format(Row.Words) + '|' + Format(Row.Words, 0, 2));
        Ok := Evaluate(Row.Words, '5');
        Observer.Observe('ordinal 5', Format(Ok) + '|' + Format(Row.Words) + '|' + Format(Row.Words, 0, 2));
        Observer.Expect('0', 'Yes|1|0');
        Observer.Expect('1', 'Yes|1|0');
        Observer.Expect('2', 'Yes|2|1');
        Observer.Expect('3 (caption of C, no such ordinal)', 'Yes|3|2');
        Observer.Expect('4', 'Yes|4|4');
        Observer.Expect('caption Twenty', 'Yes|Twenty|1');
        Observer.Expect('caption twenty lower', 'Yes|Twenty|1');
        Observer.Expect('member Two', 'Yes|Thirty|2');
        Observer.Expect('caption Thirty', 'Yes|Thirty|2');
        Observer.Expect('neither Three', 'No|Thirty|2');
        Observer.Expect('ordinal 5', 'Yes|5|5');
        Observer.Verify();
    end;
}
