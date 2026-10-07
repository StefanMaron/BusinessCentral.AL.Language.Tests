// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-value-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: TPF Row (69932), TPF List (69935), TPF Enum (69932)
// BC versions: 27.0+

codeunit 69935 "TPF List Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Probe_ListRow()
    var
        Row: Record "TPF Row";
        List: TestPage "TPF List";
        Obs: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Num := 1234567;
        Row.Dec2 := 1234567.89;
        Row.Flag := true;
        Row.Opt := Row.Opt::Beta;
        Row.Enm := "TPF Enum"::Two;
        Row.Dt := 20240302D;
        Row.Tm := 123456T;
        Row.DtTm := CreateDateTime(20240302D, 123456T);
        Evaluate(Row.Gd, '{11111111-2222-3333-4444-555555555555}');
        Row.Dur := 5000;
        Row.Insert();
        List.OpenEdit();
        List.GoToKey('R1');
        Obs := 'Num=[' + List.Num.Value() + '] Dec2=[' + List.Dec2.Value() + '] Flag=[' + List.Flag.Value() + '] Opt=[' + List.Opt.Value() + '] Enm=[' + List.Enm.Value() + ']';
        Obs += ' Dt=[' + List.Dt.Value() + '] Tm=[' + List.Tm.Value() + '] DtTm=[' + List.DtTm.Value() + '] Gd=[' + List.Gd.Value() + '] Dur=[' + List.Dur.Value() + ']';
        List.Close();
        Error('%1', Obs);
    end;

    [Test]
    procedure Probe_ListDraftLine()
    var
        Row: Record "TPF Row";
        List: TestPage "TPF List";
        Obs: Text;
    begin
        Row.DeleteAll();
        List.OpenEdit();
        Obs := 'Num=[' + List.Num.Value() + '] Dec2=[' + List.Dec2.Value() + '] Flag=[' + List.Flag.Value() + '] Opt=[' + List.Opt.Value() + '] Enm=[' + List.Enm.Value() + ']';
        Obs += ' Dt=[' + List.Dt.Value() + '] Tm=[' + List.Tm.Value() + '] DtTm=[' + List.DtTm.Value() + '] Gd=[' + List.Gd.Value() + '] Dur=[' + List.Dur.Value() + ']';
        List.Close();
        Error('%1', Obs);
    end;
}
