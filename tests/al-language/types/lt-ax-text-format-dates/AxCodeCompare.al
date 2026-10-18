// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/code/code-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Facts: comparing Code and Text values that look like numbers ('1.5'/'10', '-1'/'1', '1E3'/'999', '1E3'/'1000', '+1'/'1', '1,5'/'10'):
//   Code with Code, Code with Text, Text with Code, and two Code fields of a record; Codes with a space, an underscore or a dot inside
//   against digit-only Codes; the in operator with a range ['a' .. 'z'] when the value or the range ends are Code or Text in mixed case.
//   Each comparison is written as the operators that hold: > < = <> (for example '>!' means A > B and A <> B).
// BC versions: 27.5+

table 80402 "LT AX Code Pair"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Integer) { }
        field(2; C1; Code[20]) { }
        field(3; C2; Code[20]) { }
    }

    keys
    {
        key(PK; PK) { Clustered = true; }
    }
}

codeunit 80422 "LT AX Code Compare"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Ops(Gt: Boolean; Lt: Boolean; Eq: Boolean; Ne: Boolean): Text
    var
        S: Text;
    begin
        if Gt then
            S += '>';
        if Lt then
            S += '<';
        if Eq then
            S += '=';
        if Ne then
            S += '!';
        exit(S);
    end;

    local procedure CC(A: Code[20]; B: Code[20]): Text
    begin
        exit(Ops(A > B, A < B, A = B, A <> B));
    end;

    local procedure CT(A: Code[20]; B: Text): Text
    begin
        exit(Ops(A > B, A < B, A = B, A <> B));
    end;

    local procedure TC(A: Text; B: Code[20]): Text
    begin
        exit(Ops(A > B, A < B, A = B, A <> B));
    end;

    local procedure FF(A: Code[20]; B: Code[20]): Text
    var
        R: Record "LT AX Code Pair";
    begin
        R.C1 := A;
        R.C2 := B;
        exit(Ops(R.C1 > R.C2, R.C1 < R.C2, R.C1 = R.C2, R.C1 <> R.C2));
    end;

    local procedure All(A: Text; B: Text): Text
    begin
        exit('cc' + CC(A, B) + ' ct' + CT(A, B) + ' tc' + TC(A, B) + ' ff' + FF(A, B));
    end;

    [Test]
    procedure NumberLike_CodeAndText_Pairs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1.5/10', All('1.5', '10'));
        Observer.Observe('-1/1', All('-1', '1'));
        Observer.Observe('1E3/999', All('1E3', '999'));
        Observer.Observe('1E3/1000', All('1E3', '1000'));
        Observer.Observe('+1/1', All('+1', '1'));
        Observer.Observe('1,5/10', All('1,5', '10'));
        Observer.Finish();
    end;

    [Test]
    procedure NumberLike_Reversed_Pairs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('10/1.5', All('10', '1.5'));
        Observer.Observe('1/-1', All('1', '-1'));
        Observer.Observe('1000/1E3', All('1000', '1E3'));
        Observer.Observe('1/+1', All('1', '+1'));
        Observer.Observe('10/1,5', All('10', '1,5'));
        Observer.Observe('1e3/999 text', 'ct' + CT('1E3', '1e3') + ' tc' + TC('1e3', '999'));
        Observer.Finish();
    end;

    local procedure CF(A: Code[20]; B: Code[20]): Text
    begin
        exit('cc' + CC(A, B) + ' ff' + FF(A, B));
    end;

    [Test]
    procedure InnerSeparator_VsDigits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1 2/12', CF('1 2', '12'));
        Observer.Observe('1_2/12', CF('1_2', '12'));
        Observer.Observe('1.2/12', CF('1.2', '12'));
        Observer.Observe('1 2/9', CF('1 2', '9'));
        Observer.Observe('1_2/9', CF('1_2', '9'));
        Observer.Observe('1.2/9', CF('1.2', '9'));
        Observer.Observe('10 5/9', CF('10 5', '9'));
        Observer.Observe('10_5/9', CF('10_5', '9'));
        Observer.Observe('10.5/9', CF('10.5', '9'));
        Observer.Observe('9/1 2', CF('9', '1 2'));
        Observer.Observe('9/1_2', CF('9', '1_2'));
        Observer.Observe('9/1.2', CF('9', '1.2'));
        Observer.Finish();
    end;

    [Test]
    procedure InnerSeparator_SameLength()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1 2/102', CF('1 2', '102'));
        Observer.Observe('1_2/102', CF('1_2', '102'));
        Observer.Observe('1.2/102', CF('1.2', '102'));
        Observer.Observe('1 2/1_2', CF('1 2', '1_2'));
        Observer.Observe('1.2/1_2', CF('1.2', '1_2'));
        Observer.Observe('1 2/1.2', CF('1 2', '1.2'));
        Observer.Finish();
    end;

    [Test]
    procedure InRange_CodeAndTextMixedCase()
    var
        Observer: Codeunit "Probe Observer";
        CVal: Code[10];
        CLo: Code[10];
        CHi: Code[10];
        TVal: Text;
        TLo: Text;
        THi: Text;
    begin
        CVal := 'K';
        CLo := 'a';
        CHi := 'z';
        TLo := 'a';
        THi := 'z';
        Observer.Observe('CK in[Ca..Cz]', Format(CVal in [CLo .. CHi]));
        Observer.Observe('CK in[Ta..Tz]', Format(CVal in [TLo .. THi]));
        Observer.Observe('CK in[A..z]', Format(CVal in ['A' .. 'z']));
        Observer.Observe('CK in[a..Z]', Format(CVal in ['a' .. 'Z']));
        TVal := 'K';
        Observer.Observe('TK in[Ca..Cz]', Format(TVal in [CLo .. CHi]));
        Observer.Observe('TK in[Ta..Tz]', Format(TVal in [TLo .. THi]));
        Observer.Observe('TK in[A..z]', Format(TVal in ['A' .. 'z']));
        Observer.Observe('TK in[a..Z]', Format(TVal in ['a' .. 'Z']));
        TVal := 'k';
        Observer.Observe('Tk in[Ca..Cz]', Format(TVal in [CLo .. CHi]));
        Observer.Observe('Tk in[a..z]', Format(TVal in ['a' .. 'z']));
        Observer.Observe('Tk in[A..Z]', Format(TVal in ['A' .. 'Z']));
        Observer.Observe('Tk in[CodeVal]', Format(TVal in [CVal]));
        Observer.Finish();
    end;
}
