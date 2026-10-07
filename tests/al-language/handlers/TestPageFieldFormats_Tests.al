// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-assertequals-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: TPF Row (69932), TPF Card (69932), TPF Enum (69932), TPF Media Row (69933), TPF Media Card (69933)
// BC versions: 27.0+
//
// PROBE REVISION: every Probe_* test records what BC answers and ends in Error(<observations>), so
// it is red by design. The Eq_* tests assert the natural expectation; a FAIL names the pair BC saw.

codeunit 69932 "TPF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Open(var Row: Record "TPF Row"; var Card: TestPage "TPF Card")
    var
        Old: Record "TPF Row";
    begin
        Old.DeleteAll();
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey(Row.PK);
    end;


    local procedure V_Num(v: Integer): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Num := v;
        Open(Row, Card);
        T := Card.Num.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_Big(v: Text): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Evaluate(Row.Big, v);
        Open(Row, Card);
        T := Card.Big.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_Dec2(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Dec2 := v;
        Open(Row, Card);
        T := Card.Dec2.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_Dec1(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Dec1 := v;
        Open(Row, Card);
        T := Card.Dec1.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_Dec5(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Dec5 := v;
        Open(Row, Card);
        T := Card.Dec5.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_DecDef(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.DecDef := v;
        Open(Row, Card);
        T := Card.DecDef.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_DecRng(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.DecRng := v;
        Open(Row, Card);
        T := Card.DecRng.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_DecBZ(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.DecBZ := v;
        Open(Row, Card);
        T := Card.DecBZ.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_DecBZT(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.DecBZT := v;
        Open(Row, Card);
        T := Card.DecBZT.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_DecBNP(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNP := v;
        Open(Row, Card);
        T := Card.DecBNP.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_DecBNN(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNN := v;
        Open(Row, Card);
        T := Card.DecBNN.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_DecAF(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.DecAF := v;
        Open(Row, Card);
        T := Card.DecAF.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_NumBZ(v: Integer): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.NumBZ := v;
        Open(Row, Card);
        T := Card.NumBZ.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_Flag(v: Boolean): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Flag := v;
        Open(Row, Card);
        T := Card.Flag.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_Opt(v: Integer): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Opt := v;
        Open(Row, Card);
        T := Card.Opt.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_Enm(v: Integer): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Enm := "TPF Enum".FromInteger(v);
        Open(Row, Card);
        T := Card.Enm.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_Dt(v: Date): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Dt := v;
        Open(Row, Card);
        T := Card.Dt.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_Tm(v: Time): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Tm := v;
        Open(Row, Card);
        T := Card.Tm.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_DtTm(v: DateTime): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.DtTm := v;
        Open(Row, Card);
        T := Card.DtTm.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_Cd(v: Code[20]): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Cd := v;
        Open(Row, Card);
        T := Card.Cd.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_Txt(v: Text[50]): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Txt := v;
        Open(Row, Card);
        T := Card.Txt.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_Gd(v: Text): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Evaluate(Row.Gd, v);
        Open(Row, Card);
        T := Card.Gd.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    local procedure V_Dur(v: Integer): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Dur := v;
        Open(Row, Card);
        T := Card.Dur.Value();
        Card.Close();
        exit('(' + Format(v) + ')=[' + T + '] ');
    end;

    [Test]
    procedure Probe_Value_Num()
    var
        Obs: Text;
    begin
        Obs += V_Num(0);
        Obs += V_Num(42);
        Obs += V_Num(1000);
        Obs += V_Num(1234567);
        Obs += V_Num(-1234567);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_Big()
    var
        Obs: Text;
    begin
        Obs += V_Big('9000000000');
        Obs += V_Big('1234567890123');
        Obs += V_Big('-5000');
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_Dec2()
    var
        Obs: Text;
    begin
        Obs += V_Dec2(0);
        Obs += V_Dec2(999.5);
        Obs += V_Dec2(1000);
        Obs += V_Dec2(1234567.89);
        Obs += V_Dec2(-1234567.89);
        Obs += V_Dec2(0.005);
        Obs += V_Dec2(0.015);
        Obs += V_Dec2(99999999999999.99);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_Dec1()
    var
        Obs: Text;
    begin
        Obs += V_Dec1(3.25);
        Obs += V_Dec1(1234.56);
        Obs += V_Dec1(0);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_Dec5()
    var
        Obs: Text;
    begin
        Obs += V_Dec5(1.5);
        Obs += V_Dec5(1234.12345);
        Obs += V_Dec5(0);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_DecDef()
    var
        Obs: Text;
    begin
        Obs += V_DecDef(0);
        Obs += V_DecDef(3.14159);
        Obs += V_DecDef(1234.5);
        Obs += V_DecDef(1234567.891);
        Obs += V_DecDef(1000);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_DecRng()
    var
        Obs: Text;
    begin
        Obs += V_DecRng(1000);
        Obs += V_DecRng(1234.5);
        Obs += V_DecRng(1.123456);
        Obs += V_DecRng(0);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_DecBZ()
    var
        Obs: Text;
    begin
        Obs += V_DecBZ(0);
        Obs += V_DecBZ(5);
        Obs += V_DecBZ(1000);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_DecBZT()
    var
        Obs: Text;
    begin
        Obs += V_DecBZT(0);
        Obs += V_DecBZT(5);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_DecBNP()
    var
        Obs: Text;
    begin
        Obs += V_DecBNP(-5);
        Obs += V_DecBNP(0);
        Obs += V_DecBNP(5);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_DecBNN()
    var
        Obs: Text;
    begin
        Obs += V_DecBNN(-5);
        Obs += V_DecBNN(0);
        Obs += V_DecBNN(5);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_DecAF()
    var
        Obs: Text;
    begin
        Obs += V_DecAF(1234.5);
        Obs += V_DecAF(0);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_NumBZ()
    var
        Obs: Text;
    begin
        Obs += V_NumBZ(0);
        Obs += V_NumBZ(7);
        Obs += V_NumBZ(1000);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_Flag()
    var
        Obs: Text;
    begin
        Obs += V_Flag(true);
        Obs += V_Flag(false);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_Opt()
    var
        Obs: Text;
    begin
        Obs += V_Opt(0);
        Obs += V_Opt(1);
        Obs += V_Opt(2);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_Enm()
    var
        Obs: Text;
    begin
        Obs += V_Enm(0);
        Obs += V_Enm(1);
        Obs += V_Enm(2);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_Dt()
    var
        Obs: Text;
    begin
        Obs += V_Dt(20240302D);
        Obs += V_Dt(0D);
        Obs += V_Dt(20241231D);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_Tm()
    var
        Obs: Text;
    begin
        Obs += V_Tm(123456T);
        Obs += V_Tm(0T);
        Obs += V_Tm(235959T);
        Obs += V_Tm(000001T);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_DtTm()
    var
        Obs: Text;
    begin
        Obs += V_DtTm(CreateDateTime(20240302D, 123456T));
        Obs += V_DtTm(0DT);
        Obs += V_DtTm(CreateDateTime(20240302D, 0T));
        Obs += V_DtTm(CreateDateTime(20241231D, 235959T));
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_Cd()
    var
        Obs: Text;
    begin
        Obs += V_Cd('ABC');
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_Txt()
    var
        Obs: Text;
    begin
        Obs += V_Txt('text');
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_Gd()
    var
        Obs: Text;
    begin
        Obs += V_Gd('{11111111-2222-3333-4444-555555555555}');
        Obs += V_Gd('{00000000-0000-0000-0000-000000000000}');
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_Dur()
    var
        Obs: Text;
    begin
        Obs += V_Dur(0);
        Obs += V_Dur(5000);
        Obs += V_Dur(3723000);
        Obs += V_Dur(90000000);
        Obs += V_Dur(86400000);
        Obs += V_Dur(1);
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_PageVariables()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        Obs: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec2 := 1234567.89;
        Row.Num := 1234567;
        Row.Dt := 20240302D;
        Row.Dur := 5000;
        Row.Flag := true;
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Obs := 'D=[' + Card.GlobDec.Value() + '] N=[' + Card.GlobNum.Value() + '] Dt=[' + Card.GlobDt.Value() + '] Dur=[' + Card.GlobDur.Value() + '] F=[' + Card.GlobFlag.Value() + ']';
        Card.Close();
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_Value_Media()
    var
        Row: Record "TPF Media Row";
        Card: TestPage "TPF Media Card";
        Obs: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Obs := 'Pic=[' + Card.Pic.Value() + ']';
        Obs += ' One=[' + Card.One.Value() + ']';
        Card.Close();
        Error('%1', Obs);
    end;


    [Test]
    procedure Eq_Num_1234567()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Num := 1234567;
        Open(Row, Card);
        Card.Num.AssertEquals(1234567);
        Card.Close();
    end;

    [Test]
    procedure Eq_Num_42()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Num := 42;
        Open(Row, Card);
        Card.Num.AssertEquals(42);
        Card.Close();
    end;

    [Test]
    procedure Eq_Num_1000()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Num := 1000;
        Open(Row, Card);
        Card.Num.AssertEquals(1000);
        Card.Close();
    end;

    [Test]
    procedure Eq_Num_DecimalExpected()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Num := 1000;
        Open(Row, Card);
        Card.Num.AssertEquals(1000.0);
        Card.Close();
    end;

    [Test]
    procedure Eq_Big_9000000000()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        B: BigInteger;
    begin
        Row.Init();
        Row.PK := 'R1';
        Evaluate(Row.Big, '9000000000');
        B := Row.Big;
        Open(Row, Card);
        Card.Big.AssertEquals(B);
        Card.Close();
    end;

    [Test]
    procedure Eq_Big_5000()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Big := 5000;
        Open(Row, Card);
        Card.Big.AssertEquals(5000);
        Card.Close();
    end;

    [Test]
    procedure Eq_Dec1_325()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec1 := 3.25;
        Open(Row, Card);
        Card.Dec1.AssertEquals(3.25);
        Card.Close();
    end;

    [Test]
    procedure Eq_Dec1_123456()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec1 := 1234.56;
        Open(Row, Card);
        Card.Dec1.AssertEquals(1234.56);
        Card.Close();
    end;

    [Test]
    procedure Eq_Dec5_15()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec5 := 1.5;
        Open(Row, Card);
        Card.Dec5.AssertEquals(1.5);
        Card.Close();
    end;

    [Test]
    procedure Eq_Dec5_123412345()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec5 := 1234.12345;
        Open(Row, Card);
        Card.Dec5.AssertEquals(1234.12345);
        Card.Close();
    end;

    [Test]
    procedure Eq_DecDef_12345()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecDef := 1234.5;
        Open(Row, Card);
        Card.DecDef.AssertEquals(1234.5);
        Card.Close();
    end;

    [Test]
    procedure Eq_DecDef_0()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecDef := 0;
        Open(Row, Card);
        Card.DecDef.AssertEquals(0);
        Card.Close();
    end;

    [Test]
    procedure Eq_DecDef_314159()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecDef := 3.14159;
        Open(Row, Card);
        Card.DecDef.AssertEquals(3.14159);
        Card.Close();
    end;

    [Test]
    procedure Eq_DecRng_12345()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecRng := 1234.5;
        Open(Row, Card);
        Card.DecRng.AssertEquals(1234.5);
        Card.Close();
    end;

    [Test]
    procedure Eq_DecRng_1000()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecRng := 1000;
        Open(Row, Card);
        Card.DecRng.AssertEquals(1000);
        Card.Close();
    end;

    [Test]
    procedure Eq_DecBZ_Zero_Zero()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBZ := 0;
        Open(Row, Card);
        Card.DecBZ.AssertEquals(0);
        Card.Close();
    end;

    [Test]
    procedure Eq_DecBZ_Zero_Empty()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBZ := 0;
        Open(Row, Card);
        Card.DecBZ.AssertEquals('');
        Card.Close();
    end;

    [Test]
    procedure Eq_DecBZ_5()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBZ := 5;
        Open(Row, Card);
        Card.DecBZ.AssertEquals(5);
        Card.Close();
    end;

    [Test]
    procedure Eq_DecBZT_Zero_Zero()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBZT := 0;
        Open(Row, Card);
        Card.DecBZT.AssertEquals(0);
        Card.Close();
    end;

    [Test]
    procedure Eq_DecBZT_Zero_Empty()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBZT := 0;
        Open(Row, Card);
        Card.DecBZT.AssertEquals('');
        Card.Close();
    end;

    [Test]
    procedure Eq_DecBNP_Zero_Zero()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNP := 0;
        Open(Row, Card);
        Card.DecBNP.AssertEquals(0);
        Card.Close();
    end;

    [Test]
    procedure Eq_DecBNP_Zero_Empty()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNP := 0;
        Open(Row, Card);
        Card.DecBNP.AssertEquals('');
        Card.Close();
    end;

    [Test]
    procedure Eq_DecBNP_Pos5()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNP := 5;
        Open(Row, Card);
        Card.DecBNP.AssertEquals(5);
        Card.Close();
    end;

    [Test]
    procedure Eq_DecBNP_Neg5()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNP := -5;
        Open(Row, Card);
        Card.DecBNP.AssertEquals(-5);
        Card.Close();
    end;

    [Test]
    procedure Eq_DecBNN_Neg5_Neg5()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNN := -5;
        Open(Row, Card);
        Card.DecBNN.AssertEquals(-5);
        Card.Close();
    end;

    [Test]
    procedure Eq_DecBNN_Neg5_Empty()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNN := -5;
        Open(Row, Card);
        Card.DecBNN.AssertEquals('');
        Card.Close();
    end;

    [Test]
    procedure Eq_DecBNN_Pos5()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNN := 5;
        Open(Row, Card);
        Card.DecBNN.AssertEquals(5);
        Card.Close();
    end;

    [Test]
    procedure Eq_DecAF_12345()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecAF := 1234.5;
        Open(Row, Card);
        Card.DecAF.AssertEquals(1234.5);
        Card.Close();
    end;

    [Test]
    procedure Eq_NumBZ_Zero_Zero()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.NumBZ := 0;
        Open(Row, Card);
        Card.NumBZ.AssertEquals(0);
        Card.Close();
    end;

    [Test]
    procedure Eq_NumBZ_Zero_Empty()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.NumBZ := 0;
        Open(Row, Card);
        Card.NumBZ.AssertEquals('');
        Card.Close();
    end;

    [Test]
    procedure Eq_NumBZ_7()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.NumBZ := 7;
        Open(Row, Card);
        Card.NumBZ.AssertEquals(7);
        Card.Close();
    end;

    [Test]
    procedure Eq_Flag_True()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Flag := true;
        Open(Row, Card);
        Card.Flag.AssertEquals(true);
        Card.Close();
    end;

    [Test]
    procedure Eq_Flag_False()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Flag := false;
        Open(Row, Card);
        Card.Flag.AssertEquals(false);
        Card.Close();
    end;

    [Test]
    procedure Eq_Opt_Member()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Opt := Row.Opt::Beta;
        Open(Row, Card);
        Card.Opt.AssertEquals(Row.Opt::Beta);
        Card.Close();
    end;

    [Test]
    procedure Eq_Opt_Ordinal()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Opt := Row.Opt::Beta;
        Open(Row, Card);
        Card.Opt.AssertEquals(1);
        Card.Close();
    end;

    [Test]
    procedure Eq_Opt_Caption()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Opt := Row.Opt::Beta;
        Open(Row, Card);
        Card.Opt.AssertEquals('Zwei');
        Card.Close();
    end;

    [Test]
    procedure Eq_Opt_MemberName()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Opt := Row.Opt::Beta;
        Open(Row, Card);
        Card.Opt.AssertEquals('Beta');
        Card.Close();
    end;

    [Test]
    procedure Eq_Enm_Value()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Enm := "TPF Enum"::Two;
        Open(Row, Card);
        Card.Enm.AssertEquals("TPF Enum"::Two);
        Card.Close();
    end;

    [Test]
    procedure Eq_Enm_Ordinal()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Enm := "TPF Enum"::Two;
        Open(Row, Card);
        Card.Enm.AssertEquals(1);
        Card.Close();
    end;

    [Test]
    procedure Eq_Enm_Caption()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Enm := "TPF Enum"::Two;
        Open(Row, Card);
        Card.Enm.AssertEquals('Zwei');
        Card.Close();
    end;

    [Test]
    procedure Eq_Enm_Name()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Enm := "TPF Enum"::Two;
        Open(Row, Card);
        Card.Enm.AssertEquals('Two');
        Card.Close();
    end;

    [Test]
    procedure Eq_Dt_Date()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dt := 20240302D;
        Open(Row, Card);
        Card.Dt.AssertEquals(20240302D);
        Card.Close();
    end;

    [Test]
    procedure Eq_Dt_Blank()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dt := 0D;
        Open(Row, Card);
        Card.Dt.AssertEquals(0D);
        Card.Close();
    end;

    [Test]
    procedure Eq_Dt_Text()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dt := 20240302D;
        Open(Row, Card);
        Card.Dt.AssertEquals('3/2/2024');
        Card.Close();
    end;

    [Test]
    procedure Eq_Tm_Time()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Tm := 123456T;
        Open(Row, Card);
        Card.Tm.AssertEquals(123456T);
        Card.Close();
    end;

    [Test]
    procedure Eq_Tm_Blank()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Tm := 0T;
        Open(Row, Card);
        Card.Tm.AssertEquals(0T);
        Card.Close();
    end;

    [Test]
    procedure Eq_DtTm_Value()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DtTm := CreateDateTime(20240302D, 123456T);
        Open(Row, Card);
        Card.DtTm.AssertEquals(CreateDateTime(20240302D, 123456T));
        Card.Close();
    end;

    [Test]
    procedure Eq_DtTm_Blank()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DtTm := 0DT;
        Open(Row, Card);
        Card.DtTm.AssertEquals(0DT);
        Card.Close();
    end;

    [Test]
    procedure Eq_Cd_Text()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Cd := 'ABC';
        Open(Row, Card);
        Card.Cd.AssertEquals('ABC');
        Card.Close();
    end;

    [Test]
    procedure Eq_Txt_Text()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Txt := 'text';
        Open(Row, Card);
        Card.Txt.AssertEquals('text');
        Card.Close();
    end;

    [Test]
    procedure Eq_Gd_Guid()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        G: Guid;
    begin
        Row.Init();
        Row.PK := 'R1';
        Evaluate(Row.Gd, '{11111111-2222-3333-4444-555555555555}');
        G := Row.Gd;
        Open(Row, Card);
        Card.Gd.AssertEquals(G);
        Card.Close();
    end;

    [Test]
    procedure Eq_Gd_Text()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Evaluate(Row.Gd, '{11111111-2222-3333-4444-555555555555}');
        Open(Row, Card);
        Card.Gd.AssertEquals('{11111111-2222-3333-4444-555555555555}');
        Card.Close();
    end;

    [Test]
    procedure Eq_Gd_Null()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        G: Guid;
    begin
        Row.Init();
        Row.PK := 'R1';
        Clear(Row.Gd);
        G := Row.Gd;
        Open(Row, Card);
        Card.Gd.AssertEquals(G);
        Card.Close();
    end;

    [Test]
    procedure Eq_Dur_Value()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        D: Duration;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dur := 5000;
        D := 5000;
        Open(Row, Card);
        Card.Dur.AssertEquals(D);
        Card.Close();
    end;

    [Test]
    procedure Eq_Dur_Integer()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dur := 5000;
        Open(Row, Card);
        Card.Dur.AssertEquals(5000);
        Card.Close();
    end;

    [Test]
    procedure Eq_Dur_Text()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dur := 5000;
        Open(Row, Card);
        Card.Dur.AssertEquals('5 seconds');
        Card.Close();
    end;

    [Test]
    procedure Eq_Dur_Zero()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        D: Duration;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dur := 0;
        D := 0;
        Open(Row, Card);
        Card.Dur.AssertEquals(D);
        Card.Close();
    end;

    [Test]
    procedure Eq_Dur_BigValue()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        D: Duration;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dur := 3723000;
        D := 3723000;
        Open(Row, Card);
        Card.Dur.AssertEquals(D);
        Card.Close();
    end;

    [Test]
    procedure Eq_GlobDec_1234567()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec2 := 1234567.89;
        Open(Row, Card);
        Card.GlobDec.AssertEquals(1234567.89);
        Card.Close();
    end;

    [Test]
    procedure Eq_GlobNum_1234567()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Num := 1234567;
        Open(Row, Card);
        Card.GlobNum.AssertEquals(1234567);
        Card.Close();
    end;

    [Test]
    procedure Eq_GlobDt_Date()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dt := 20240302D;
        Open(Row, Card);
        Card.GlobDt.AssertEquals(20240302D);
        Card.Close();
    end;

    [Test]
    procedure Eq_GlobDur_Value()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        D: Duration;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dur := 5000;
        D := 5000;
        Open(Row, Card);
        Card.GlobDur.AssertEquals(D);
        Card.Close();
    end;
}
