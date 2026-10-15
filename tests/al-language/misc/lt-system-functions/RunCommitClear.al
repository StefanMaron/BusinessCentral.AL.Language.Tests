// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 72520
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Codeunit.Run result and rollback of its writes, Commit in a test, Clear and ClearAll on variables and records.
// BC versions: 29 (27 and 28 by CI)

table 72520 "LT SyT Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Amount; Decimal) { InitValue = 7; }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 72517 "LT SyT Runner"
{
    TableNo = "LT SyT Row";

    trigger OnRun()
    var
        Row: Record "LT SyT Row";
    begin
        Row.Code := Rec.Code + '-RUN';
        Row.Insert();
        case Rec.Name of
            'error':
                Error('runner failed');
            'commit':
                Commit();
            'commit-error':
                begin
                    Commit();
                    Error('after commit');
                end;
            'modify':
                begin
                    Rec.Amount := 99;
                    Rec.Name := 'changed';
                end;
        end;
    end;
}

codeunit 72518 "LT SyT Run Commit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure CountRows(): Integer
    var
        Row: Record "LT SyT Row";
    begin
        exit(Row.Count());
    end;

    [Test]
    procedure CodeunitRun_Success()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SyT Row";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        asserterror Ok := Codeunit.Run(Codeunit::"LT SyT Runner", Row);
        Observer.ObserveError('af75');
        Observer.Observe('result', Format(Ok));
        Observer.Observe('rows', Format(CountRows()));
        Observer.Expect('af75|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af75|code', 'DB:Ok');
        Observer.Expect('result', 'No');
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitRun_Error_RollsBack()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SyT Row";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Name := 'error';
        asserterror Ok := Codeunit.Run(Codeunit::"LT SyT Runner", Row);
        Observer.ObserveError('af92');
        Observer.Observe('result', Format(Ok));
        Observer.Observe('rows', Format(CountRows()));
        Observer.Observe('text', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        ClearLastError();
        Observer.Expect('af92|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af92|code', 'DB:Ok');
        Observer.Expect('result', 'No');
        Observer.Expect('rows', '0');
        Observer.Expect('text', '');
        Observer.Expect('code', '');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitRun_WithoutResultUse_Error()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SyT Row";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Name := 'error';
        asserterror Codeunit.Run(Codeunit::"LT SyT Runner", Row);
        Observer.ObserveError('statement form');
        Observer.Observe('rows', Format(CountRows()));
        Observer.Expect('statement form|text', 'runner failed');
        Observer.Expect('statement form|code', 'Dialog');
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitRun_RecordByReference()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SyT Row";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Name := 'modify';
        asserterror Ok := Codeunit.Run(Codeunit::"LT SyT Runner", Row);
        Observer.ObserveError('af127');
        Observer.Observe('result', Format(Ok));
        Observer.Observe('amount', Format(Row.Amount));
        Observer.Observe('name', Row.Name);
        Observer.Expect('af127|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af127|code', 'DB:Ok');
        Observer.Expect('result', 'No');
        Observer.Expect('amount', '7');
        Observer.Expect('name', 'modify');
        Observer.Verify();
    end;

    [Test]
    procedure Commit_InTest()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SyT Row";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Name := 'commit';
        asserterror Ok := Codeunit.Run(Codeunit::"LT SyT Runner", Row);
        Observer.ObserveError('af158');
        Observer.Observe('commit in run result', Format(Ok));
        Observer.Observe('rows', Format(CountRows()));
        Row.DeleteAll();
        Commit();
        Observer.Observe('rows after delete and commit', Format(CountRows()));
        Observer.Expect('af158|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af158|code', 'DB:Ok');
        Observer.Expect('commit in run result', 'No');
        Observer.Expect('rows', '0');
        Observer.Expect('rows after delete and commit', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Commit_ThenError_KeepsCommitted()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SyT Row";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Commit();
        Row.Code := 'A';
        Row.Name := 'commit-error';
        Ok := Codeunit.Run(Codeunit::"LT SyT Runner", Row);
        Observer.Observe('result', Format(Ok));
        Observer.Observe('rows after commit then error', Format(CountRows()));
        ClearLastError();
        Row.DeleteAll();
        Commit();
        Observer.Expect('result', 'No');
        Observer.Expect('rows after commit then error', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Asserterror_RollsBackWrites()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SyT Row";
    begin
        Row.DeleteAll();
        Commit();
        asserterror begin
            Row.Code := 'X';
            Row.Insert();
            Error('stop');
        end;
        Observer.ObserveError('stop');
        Observer.Observe('rows after asserterror', Format(CountRows()));
        Row.Code := 'Y';
        Row.Insert();
        asserterror Error('later');
        ClearLastError();
        Observer.Observe('earlier uncommitted insert', Format(CountRows()));
        Row.DeleteAll();
        Commit();
        Observer.Expect('stop|text', 'stop');
        Observer.Expect('stop|code', 'Dialog');
        Observer.Expect('rows after asserterror', '0');
        Observer.Expect('earlier uncommitted insert', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Commit_Repeated()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SyT Row";
    begin
        Row.DeleteAll();
        Commit();
        Commit();
        Row.Code := 'A';
        Row.Insert();
        Commit();
        Observer.Observe('rows', Format(CountRows()));
        Row.DeleteAll();
        Commit();
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;
}

codeunit 72519 "LT SyT Clear"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Global: Integer;
        GlobalText: Text;

    [Test]
    procedure Clear_SimpleTypes()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        D: Decimal;
        T: Text;
        C: Code[10];
        B: Boolean;
        Dt: Date;
        Tm: Time;
        DT2: DateTime;
        O: Option A,B,C;
        G: Guid;
        Bi: BigInteger;
        Dur: Duration;
    begin
        I := 5;
        D := 1.5;
        T := 'x';
        C := 'abc';
        B := true;
        Dt := DMY2Date(1, 1, 2000);
        Tm := 120000T;
        DT2 := CreateDateTime(Dt, Tm);
        O := O::C;
        G := CreateGuid();
        Evaluate(Bi, '9999999999');
        Dur := 5000;
        Clear(I);
        Clear(D);
        Clear(T);
        Clear(C);
        Clear(B);
        Clear(Dt);
        Clear(Tm);
        Clear(DT2);
        Clear(O);
        Clear(G);
        Clear(Bi);
        Clear(Dur);
        Observer.Observe('integer', Format(I));
        Observer.Observe('decimal', Format(D));
        Observer.Observe('text', '[' + T + ']');
        Observer.Observe('code', '[' + C + ']');
        Observer.Observe('boolean', Format(B));
        Observer.Observe('date', Format(Dt, 0, 9));
        Observer.Observe('time', Format(Tm, 0, 9));
        Observer.Observe('datetime', Format(DT2, 0, 9));
        Observer.Observe('option', Format(O));
        Observer.Observe('guid null', Format(IsNullGuid(G)));
        Observer.Observe('biginteger', Format(Bi));
        Observer.Observe('duration', Format(Dur, 0, 9));
        Observer.Expect('integer', '0');
        Observer.Expect('decimal', '0');
        Observer.Expect('text', '[]');
        Observer.Expect('code', '[]');
        Observer.Expect('boolean', 'No');
        Observer.Expect('date', '');
        Observer.Expect('time', '');
        Observer.Expect('datetime', '');
        Observer.Expect('option', 'A');
        Observer.Expect('guid null', 'Yes');
        Observer.Expect('biginteger', '0');
        Observer.Expect('duration', 'P0DT0H0M0.0S');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_Record_ResetsInitValueAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SyT Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Observer.Observe('init value amount', Format(Row.Amount));
        Row.Amount := 3;
        Row.Name := 'n';
        Row.SetFilter(Code, 'A*');
        Observer.Observe('filter before', Row.GetFilter(Code));
        Clear(Row);
        Observer.Observe('amount after clear', Format(Row.Amount));
        Observer.Observe('name after clear', '[' + Row.Name + ']');
        Observer.Observe('filter after clear', Format(Row.GetFilter(Code) = ''));
        Observer.Expect('init value amount', '7');
        Observer.Expect('filter before', 'A*');
        Observer.Expect('amount after clear', '7');
        Observer.Expect('name after clear', '[]');
        Observer.Expect('filter after clear', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_Record_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Record "LT SyT Row" temporary;
    begin
        Tmp.Code := 'T1';
        Tmp.Insert();
        Observer.Observe('count', Format(Tmp.Count()));
        Clear(Tmp);
        Observer.Observe('count after Clear', Format(Tmp.Count()));
        Observer.Observe('still temporary', Format(Tmp.IsTemporary()));
        Tmp.Code := 'T2';
        Tmp.Insert();
        Tmp.DeleteAll();
        Observer.Observe('count after DeleteAll', Format(Tmp.Count()));
        Observer.Expect('count', '1');
        Observer.Expect('count after Clear', '1');
        Observer.Expect('still temporary', 'Yes');
        Observer.Expect('count after DeleteAll', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_Collections()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        D: Dictionary of [Text, Integer];
        Tx: TextBuilder;
    begin
        L.Add(1);
        D.Add('a', 1);
        Tx.Append('abc');
        Clear(L);
        Clear(D);
        Clear(Tx);
        Observer.Observe('list', Format(L.Count()));
        Observer.Observe('dict', Format(D.Count()));
        Observer.Observe('builder', Format(Tx.Length()));
        Observer.Expect('list', '0');
        Observer.Expect('dict', '0');
        Observer.Expect('builder', '0');
        Observer.Verify();
    end;

    local procedure SetGlobals()
    begin
        Global := 42;
        GlobalText := 'global';
    end;

    [Test]
    procedure ClearAll_Globals()
    var
        Observer: Codeunit "Probe Observer";
        Local1: Integer;
    begin
        SetGlobals();
        Local1 := 7;
        ClearAll();
        Observer.Observe('global int', Format(Global));
        Observer.Observe('global text', '[' + GlobalText + ']');
        Observer.Observe('local int', Format(Local1));
        Observer.Expect('global int', '0');
        Observer.Expect('global text', '[]');
        Observer.Expect('local int', '7');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_Locals_And_Parameters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('proc', ClearAllInside(5));
        Observer.Expect('proc', '5|loc|0');
        Observer.Verify();
    end;

    local procedure ClearAllInside(Param: Integer): Text
    var
        Loc: Text;
    begin
        Loc := 'loc';
        Global := 11;
        ClearAll();
        exit(Format(Param) + '|' + Loc + '|' + Format(Global));
    end;

    [Test]
    procedure ClearLastError_Semantics()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('first');
        Observer.Observe('before', GetLastErrorText());
        ClearLastError();
        Observer.Observe('after', '[' + GetLastErrorText() + ']');
        ClearLastError();
        Observer.Observe('twice', '[' + GetLastErrorText() + ']');
        Observer.Expect('before', 'first');
        Observer.Expect('after', '[]');
        Observer.Expect('twice', '[]');
        Observer.Verify();
    end;
}
