// PROBE -- records what a real service tier answers; replaced by assertions once measured.
codeunit 67822 "Test AutoIncrement Explicit Key"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Control: Codeunit "AutoInc Explicit Control";
        Trace: TextBuilder;

    local procedure Initialize()
    var
        P: Record "AutoInc Explicit Probe";
        U: Record "AutoInc Unique Probe";
    begin
        P.Truncate(true);
        U.Truncate(true);
        Control.Reset();
        Clear(Trace);
    end;

    local procedure Zero(Name: Text): Integer
    var
        P: Record "AutoInc Explicit Probe";
        Ok: Boolean;
    begin
        P."Entry No." := 0;
        P.Payload := CopyStr(Name, 1, 30);
        Ok := P.Insert(false);
        Note(Name + '.ok', Format(Ok));
        Note(Name + '.key', Format(P."Entry No.", 0, 9));
        exit(P."Entry No.");
    end;

    local procedure Explicit(Name: Text; KeyValue: Integer): Boolean
    var
        P: Record "AutoInc Explicit Probe";
        Ok: Boolean;
    begin
        P."Entry No." := KeyValue;
        P.Payload := CopyStr(Name, 1, 30);
        Ok := P.Insert(false);
        Note(Name + '.ok', Format(Ok));
        Note(Name + '.key', Format(P."Entry No.", 0, 9));
        exit(Ok);
    end;

    local procedure Note(What: Text; Value: Text)
    begin
        Trace.Append(What + '=' + Value + '; ');
    end;

    local procedure Done(CaseName: Text)
    var
        P: Record "AutoInc Explicit Probe";
        Rows: Text;
    begin
        if P.FindSet() then
            repeat
                Rows += Format(P."Entry No.", 0, 9) + ',';
            until P.Next() = 0;
        Error('PROBE %1 :: %2 rows=[%3]', CaseName, Trace.ToText(), Rows);
    end;

    [Test]
    procedure Probe_A1_CallerExplicitAbove()
    var
        K1: Integer;
    begin
        Initialize();
        K1 := Zero('z1');
        Explicit('exp', K1 + 10);
        Zero('z3');
        Zero('z4');
        Done('A1');
    end;

    [Test]
    procedure Probe_A2_CallerExplicitFirstOnFreshCounter()
    begin
        Initialize();
        Explicit('exp', 100);
        Zero('z2');
        Zero('z3');
        Done('A2');
    end;

    [Test]
    procedure Probe_A3_CallerExplicitEqualsNext()
    var
        K1: Integer;
    begin
        Initialize();
        K1 := Zero('z1');
        Explicit('exp', K1 + 1);
        Zero('z3');
        Done('A3');
    end;

    [Test]
    procedure Probe_B1_OnInsertAssignsAbove()
    var
        K1: Integer;
    begin
        Initialize();
        K1 := Zero('z1');
        Control.AssignKeyInOnInsert(K1 + 10);
        Zero('trig');
        Note('trig.sawInOnInsert', Format(Control.GetSawInOnInsert(), 0, 9));
        Control.Reset();
        Zero('z3');
        Done('B1');
    end;

    [Test]
    procedure Probe_B2_OnInsertAssignsEqualsNext()
    var
        K1: Integer;
    begin
        Initialize();
        K1 := Zero('z1');
        Control.AssignKeyInOnInsert(K1 + 1);
        Zero('trig');
        Control.Reset();
        Zero('z3');
        Done('B2');
    end;

    [Test]
    procedure Probe_B3_OnInsertAssignsOnFreshCounter()
    begin
        Initialize();
        Control.AssignKeyInOnInsert(100);
        Zero('trig');
        Control.Reset();
        Zero('z2');
        Done('B3');
    end;

    [Test]
    procedure Probe_B4_BeforeInsertSubscriberAssignsAbove()
    var
        Sub: Codeunit "AutoInc Explicit Subscriber";
        K1: Integer;
    begin
        Initialize();
        K1 := Zero('z1');
        Sub.SetKey(K1 + 10);
        BindSubscription(Sub);
        Zero('sub');
        UnbindSubscription(Sub);
        Zero('z3');
        Done('B4');
    end;

    [Test]
    procedure Probe_C1_ExplicitBelowCounterIntoGap()
    begin
        Initialize();
        Zero('z1');
        Zero('z2');
        Zero('z3');
        DeleteKey(2);
        Explicit('exp', 2);
        Zero('z5');
        Done('C1');
    end;

    [Test]
    procedure Probe_C2_DeleteAllDoesNotRewindCounter()
    var
        P: Record "AutoInc Explicit Probe";
    begin
        Initialize();
        Zero('z1');
        Zero('z2');
        Zero('z3');
        P.DeleteAll();
        Zero('z4');
        Done('C2');
    end;

    [Test]
    procedure Probe_C3_ExplicitLowAfterDeleteAll()
    var
        P: Record "AutoInc Explicit Probe";
    begin
        Initialize();
        Zero('z1');
        Zero('z2');
        Zero('z3');
        P.DeleteAll();
        Explicit('exp', 1);
        Zero('z5');
        Done('C3');
    end;

    [Test]
    procedure Probe_C4_ExplicitDuplicateOfStoredKey()
    var
        K1: Integer;
    begin
        Initialize();
        K1 := Zero('z1');
        Explicit('dup', K1);
        Zero('z3');
        Done('C4');
    end;

    [Test]
    procedure Probe_D_ExplicitZeroOnRecordThatHeldAKey()
    var
        P: Record "AutoInc Explicit Probe";
        Ok: Boolean;
    begin
        Initialize();
        Zero('z1');
        P.Payload := 'again';
        Ok := P.Insert(false);
        Note('again.ok', Format(Ok));
        Note('again.key', Format(P."Entry No.", 0, 9));
        P.Init();
        P."Entry No." := 0;
        P.Payload := 'zeroed';
        Ok := P.Insert(false);
        Note('zeroed.ok', Format(Ok));
        Note('zeroed.key', Format(P."Entry No.", 0, 9));
        Done('D');
    end;

    [Test]
    procedure Probe_E1_RenameToHigherKey()
    var
        P: Record "AutoInc Explicit Probe";
        K1: Integer;
    begin
        Initialize();
        K1 := Zero('z1');
        P.Get(K1);
        P.Rename(K1 + 50);
        Note('renamed.key', Format(P."Entry No.", 0, 9));
        Zero('z3');
        Done('E1');
    end;

    [Test]
    procedure Probe_E2_RenameToLowerKey()
    var
        P: Record "AutoInc Explicit Probe";
        K2: Integer;
    begin
        Initialize();
        Zero('z1');
        K2 := Zero('z2');
        P.Get(K2);
        P.Rename(K2 + 50);
        Zero('z3');
        P.Get(K2 + 50);
        P.Rename(0);
        Note('renamedDown.key', Format(P."Entry No.", 0, 9));
        Zero('z4');
        Done('E2');
    end;

    [Test]
    procedure Probe_F1_OnInsertErrorConsumesNothing()
    var
        P: Record "AutoInc Explicit Probe";
    begin
        Initialize();
        Zero('z1');
        Control.FailInOnInsert();
        P.Payload := 'refused';
        asserterror P.Insert(true);
        Note('refused.err', GetLastErrorText());
        Control.Reset();
        Zero('z3');
        Done('F1');
    end;

    [Test]
    procedure Probe_F2_UniqueKeyViolationConsumesTheCounter()
    var
        U: Record "AutoInc Unique Probe";
        Ok: Boolean;
    begin
        Initialize();
        U.Code := 'X';
        Ok := U.Insert(false);
        Note('u1.ok', Format(Ok));
        Note('u1.key', Format(U."Entry No.", 0, 9));
        Clear(U);
        U.Code := 'X';
        Ok := U.Insert(false);
        Note('u2.ok', Format(Ok));
        Note('u2.key', Format(U."Entry No.", 0, 9));
        Clear(U);
        U.Code := 'Y';
        Ok := U.Insert(false);
        Note('u3.ok', Format(Ok));
        Note('u3.key', Format(U."Entry No.", 0, 9));
        Done('F2');
    end;

    local procedure DeleteKey(KeyValue: Integer)
    var
        P: Record "AutoInc Explicit Probe";
    begin
        P.Get(KeyValue);
        P.Delete(false);
    end;
}
