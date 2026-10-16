// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 70325, codeunit 70327
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Codeunit.Run(Number, var Record) with an own table and TableNo (Run(Text, Record) needs runtime 17: skipped)
// BC versions: 29 (27 and 28 by CI)

table 70325 "LT P93 Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[50]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 70326 "LT P93 Runner"
{
    TableNo = "LT P93 Rec";

    trigger OnRun()
    begin
        Rec.Txt := 'run:' + Rec.Txt;
        if Rec.Id < 0 then
            Error('negative id');
        if Rec.Id = 999 then
            Rec.Modify();
    end;
}

codeunit 70327 "LT P93 CodeunitRun"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Run_WithRecord_InMemory()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P93 Rec";
        Ok: Boolean;
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Txt := 'a';
        asserterror Ok := Codeunit.Run(Codeunit::"LT P93 Runner", Rec);
        Observer.ObserveError('af50');
        Observer.Observe('ret', Format(Ok));
        Observer.Observe('txt', Rec.Txt);
        Observer.Observe('id', Format(Rec.Id));
        Observer.Observe('stored', Format(Rec.Count()));
        Ok := Codeunit.Run(Codeunit::"LT P93 Runner", Rec);
        Observer.Observe('ret-again', Format(Ok));
        Observer.Observe('txt-again', Rec.Txt);
        Observer.Finish();
    end;

    [Test]
    procedure Run_WithRecord_Error()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P93 Rec";
        Ok: Boolean;
    begin
        Rec.DeleteAll();
        Rec.Id := -1;
        Rec.Txt := 'a';
        asserterror Ok := Codeunit.Run(Codeunit::"LT P93 Runner", Rec);
        Observer.ObserveError('af72');
        Observer.Observe('ret', Format(Ok));
        Observer.Observe('err', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        Observer.Observe('txt', Rec.Txt);
        Observer.Finish();
    end;

    [Test]
    procedure Run_WithRecord_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P93 Rec";
    begin
        Rec.DeleteAll();
        Rec.Id := -1;
        Rec.Txt := 'a';
        asserterror Codeunit.Run(Codeunit::"LT P93 Runner", Rec);
        Observer.ObserveError('run-error');
        Observer.Observe('txt', Rec.Txt);
        Observer.Finish();
    end;

    [Test]
    procedure Run_WithRecord_Stored()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P93 Rec";
        Check: Record "LT P93 Rec";
        Ok: Boolean;
    begin
        Rec.DeleteAll();
        Rec.Id := 999;
        Rec.Txt := 'a';
        Rec.Insert();
        asserterror Ok := Codeunit.Run(Codeunit::"LT P93 Runner", Rec);
        Observer.ObserveError('af108');
        Observer.Observe('ret', Format(Ok));
        Observer.Observe('mem-txt', Rec.Txt);
        asserterror Check.Get(999);
        Observer.ObserveError('af112');
        Observer.Observe('db-txt', Check.Txt);
        Observer.Finish();
    end;

    [Test]
    procedure Run_WithoutRecord_TableNoCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Ok := Codeunit.Run(Codeunit::"LT P93 Runner");
        Observer.Observe('ret', Format(Ok));
        Observer.Observe('err', GetLastErrorText());
        Observer.Finish();
    end;
}
