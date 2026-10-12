// PROBE -- records what a real service tier answers; replaced by assertions once measured.
codeunit 67826 "Test AutoInc Counter Edge"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Trace: TextBuilder;

    local procedure Note(What: Text; Value: Text)
    begin
        Trace.Append(What + '=' + Value + '; ');
    end;

    local procedure Done(CaseName: Text; RowsText: Text)
    begin
        Error('PROBE %1 :: %2 rows=[%3]', CaseName, Trace.ToText(), RowsText);
    end;

    local procedure ZeroA(Name: Text): Integer
    var
        P: Record "AutoInc Edge A";
        Ok: Boolean;
    begin
        P."Entry No." := 0;
        P.Payload := CopyStr(Name, 1, 30);
        Ok := P.Insert(true);
        Note(Name + '.ok', Format(Ok));
        Note(Name + '.key', Format(P."Entry No.", 0, 9));
        exit(P."Entry No.");
    end;

    local procedure RefuseA()
    var
        P: Record "AutoInc Edge A";
    begin
        P.Payload := 'refuse';
        asserterror P.Insert(true);
        Note('refused.err', GetLastErrorText());
        Note('refused.key', Format(P."Entry No.", 0, 9));
    end;

    local procedure RowsA(): Text
    var
        P: Record "AutoInc Edge A";
        R: Text;
    begin
        R := 'cnt=' + Format(P.Count()) + ':';
        if P.FindSet() then
            repeat
                R += Format(P."Entry No.", 0, 9) + ',';
            until P.Next() = 0;
        exit(R);
    end;

    local procedure ZeroB(Name: Text): Integer
    var
        P: Record "AutoInc Edge B";
        Ok: Boolean;
    begin
        P."Entry No." := 0;
        P.Payload := CopyStr(Name, 1, 30);
        Ok := P.Insert(true);
        Note(Name + '.ok', Format(Ok));
        Note(Name + '.key', Format(P."Entry No.", 0, 9));
        exit(P."Entry No.");
    end;

    local procedure RefuseB()
    var
        P: Record "AutoInc Edge B";
    begin
        P.Payload := 'refuse';
        asserterror P.Insert(true);
        Note('refused.err', GetLastErrorText());
        Note('refused.key', Format(P."Entry No.", 0, 9));
    end;

    local procedure RowsB(): Text
    var
        P: Record "AutoInc Edge B";
        R: Text;
    begin
        R := 'cnt=' + Format(P.Count()) + ':';
        if P.FindSet() then
            repeat
                R += Format(P."Entry No.", 0, 9) + ',';
            until P.Next() = 0;
        exit(R);
    end;

    local procedure ZeroC(Name: Text): Integer
    var
        P: Record "AutoInc Edge C";
        Ok: Boolean;
    begin
        P."Entry No." := 0;
        P.Payload := CopyStr(Name, 1, 30);
        Ok := P.Insert(true);
        Note(Name + '.ok', Format(Ok));
        Note(Name + '.key', Format(P."Entry No.", 0, 9));
        exit(P."Entry No.");
    end;

    local procedure RefuseC()
    var
        P: Record "AutoInc Edge C";
    begin
        P.Payload := 'refuse';
        asserterror P.Insert(true);
        Note('refused.err', GetLastErrorText());
        Note('refused.key', Format(P."Entry No.", 0, 9));
    end;

    local procedure RowsC(): Text
    var
        P: Record "AutoInc Edge C";
        R: Text;
    begin
        R := 'cnt=' + Format(P.Count()) + ':';
        if P.FindSet() then
            repeat
                R += Format(P."Entry No.", 0, 9) + ',';
            until P.Next() = 0;
        exit(R);
    end;

    local procedure ZeroD(Name: Text): Integer
    var
        P: Record "AutoInc Edge D";
        Ok: Boolean;
    begin
        P."Entry No." := 0;
        P.Payload := CopyStr(Name, 1, 30);
        Ok := P.Insert(true);
        Note(Name + '.ok', Format(Ok));
        Note(Name + '.key', Format(P."Entry No.", 0, 9));
        exit(P."Entry No.");
    end;

    local procedure RefuseD()
    var
        P: Record "AutoInc Edge D";
    begin
        P.Payload := 'refuse';
        asserterror P.Insert(true);
        Note('refused.err', GetLastErrorText());
        Note('refused.key', Format(P."Entry No.", 0, 9));
    end;

    local procedure RowsD(): Text
    var
        P: Record "AutoInc Edge D";
        R: Text;
    begin
        R := 'cnt=' + Format(P.Count()) + ':';
        if P.FindSet() then
            repeat
                R += Format(P."Entry No.", 0, 9) + ',';
            until P.Next() = 0;
        exit(R);
    end;

    local procedure ZeroE(Name: Text): Integer
    var
        P: Record "AutoInc Edge E";
        Ok: Boolean;
    begin
        P."Entry No." := 0;
        P.Payload := CopyStr(Name, 1, 30);
        Ok := P.Insert(true);
        Note(Name + '.ok', Format(Ok));
        Note(Name + '.key', Format(P."Entry No.", 0, 9));
        exit(P."Entry No.");
    end;

    local procedure RefuseE()
    var
        P: Record "AutoInc Edge E";
    begin
        P.Payload := 'refuse';
        asserterror P.Insert(true);
        Note('refused.err', GetLastErrorText());
        Note('refused.key', Format(P."Entry No.", 0, 9));
    end;

    local procedure RowsE(): Text
    var
        P: Record "AutoInc Edge E";
        R: Text;
    begin
        R := 'cnt=' + Format(P.Count()) + ':';
        if P.FindSet() then
            repeat
                R += Format(P."Entry No.", 0, 9) + ',';
            until P.Next() = 0;
        exit(R);
    end;

    // F1: Truncate(true), one zero-key Insert, an Insert refused by OnInsert, another zero-key Insert.
    [Test]
    procedure Probe_G1_TruncateOneRefuseOne()
    var
        P: Record "AutoInc Edge A";
    begin
        Clear(Trace);
        P.Truncate(true);
        ZeroA('z1');
        RefuseA();
        ZeroA('z3');
        Done('G1', RowsA());
    end;

    // G2: the same with two rows before the refused Insert.
    [Test]
    procedure Probe_G2_TruncateTwoRefuseOne()
    var
        P: Record "AutoInc Edge B";
    begin
        Clear(Trace);
        P.Truncate(true);
        ZeroB('z1');
        ZeroB('z2');
        RefuseB();
        ZeroB('z4');
        Done('G2', RowsB());
    end;

    // G3: counter used and committed, then a second Truncate(true) in a fresh transaction.
    [Test]
    procedure Probe_G3_CommittedUseThenTruncateRefuse()
    var
        P: Record "AutoInc Edge C";
    begin
        Clear(Trace);
        P.Truncate(true);
        ZeroC('c1');
        ZeroC('c2');
        ZeroC('c3');
        Commit();
        P.Truncate(true);
        ZeroC('w1');
        RefuseC();
        ZeroC('w3');
        Done('G3', RowsC());
    end;

    // G4: Truncate(true) committed before the first Insert.
    [Test]
    procedure Probe_G4_TruncateCommitThenOneRefuseOne()
    var
        P: Record "AutoInc Edge D";
    begin
        Clear(Trace);
        P.Truncate(true);
        Commit();
        ZeroD('z1');
        RefuseD();
        ZeroD('z3');
        Done('G4', RowsD());
    end;

    // G5: the DeleteAll twin of G1 (no Truncate at all), with the rows read.
    [Test]
    procedure Probe_G5_DeleteAllOneRefuseOne()
    var
        P: Record "AutoInc Edge E";
    begin
        Clear(Trace);
        P.DeleteAll();
        ZeroE('z1');
        RefuseE();
        ZeroE('z3');
        Done('G5', RowsE());
    end;

    // H1: BigInteger key: an explicit key above Int32, then zero-key Inserts.
    [Test]
    procedure Probe_H1_BigIntegerExplicitAboveInt32()
    var
        B: Record "AutoInc Edge Big";
        Big: BigInteger;
        Ok: Boolean;
    begin
        Clear(Trace);
        B.DeleteAll();
        Big := 500000000;
        Big := Big * 10;
        B.Payload := 'z1';
        B.Insert(true);
        Note('z1.key', Format(B."Entry No.", 0, 9));
        Clear(B);
        B."Entry No." := Big;
        B.Payload := 'exp';
        Ok := B.Insert(true);
        Note('exp.ok', Format(Ok));
        Note('exp.key', Format(B."Entry No.", 0, 9));
        Clear(B);
        B.Payload := 'z3';
        Ok := B.Insert(true);
        Note('z3.ok', Format(Ok));
        Note('z3.key', Format(B."Entry No.", 0, 9));
        Clear(B);
        B.Payload := 'z4';
        B.Insert(true);
        Note('z4.key', Format(B."Entry No.", 0, 9));
        Done('H1', Format(B.Count()));
    end;

    // H2: Integer key: an explicit key one below Int32.MaxValue, then two zero-key Inserts.
    [Test]
    procedure Probe_H2_IntegerExplicitJustBelowMax()
    var
        I: Record "AutoInc Edge IntMax A";
    begin
        Clear(Trace);
        I.DeleteAll();
        I."Entry No." := 2147483646;
        I.Payload := 'exp';
        I.Insert(true);
        Note('exp.key', Format(I."Entry No.", 0, 9));
        Clear(I);
        I.Payload := 'z2';
        asserterror I.Insert(true);
        Note('z2.err', GetLastErrorText());
        Note('z2.key', Format(I."Entry No.", 0, 9));
        Clear(I);
        I.Payload := 'z3';
        asserterror I.Insert(true);
        Note('z3.err', GetLastErrorText());
        Note('z3.key', Format(I."Entry No.", 0, 9));
        Done('H2', Format(I.Count()));
    end;

    // H3: Integer key: an explicit key of Int32.MaxValue, then a zero-key Insert.
    [Test]
    procedure Probe_H3_IntegerExplicitAtMax()
    var
        I: Record "AutoInc Edge IntMax B";
    begin
        Clear(Trace);
        I.DeleteAll();
        I."Entry No." := 2147483647;
        I.Payload := 'exp';
        I.Insert(true);
        Note('exp.key', Format(I."Entry No.", 0, 9));
        Clear(I);
        I.Payload := 'z2';
        asserterror I.Insert(true);
        Note('z2.err', GetLastErrorText());
        Note('z2.key', Format(I."Entry No.", 0, 9));
        Done('H3', Format(I.Count()));
    end;

    // K1: a zero-key Insert refused on a unique secondary key, with NO Boolean receiver (asserterror).
    [Test]
    procedure Probe_K1_UniqueKeyRefusedUnderAsserterror()
    var
        U: Record "AutoInc Unique Probe";
    begin
        Clear(Trace);
        U.DeleteAll();
        U.Code := 'X';
        U.Insert(true);
        Note('first.key', Format(U."Entry No.", 0, 9));
        Clear(U);
        U.Code := 'X';
        asserterror U.Insert(true);
        Note('err', GetLastErrorText());
        Note('refused.key', Format(U."Entry No.", 0, 9));
        Done('K1', Format(U.Count()));
    end;

    // R1: Rename of a composite key that leaves the AutoIncrement field alone.
    [Test]
    procedure Probe_R1_RenameCodeOnly()
    var
        C: Record "AutoInc Edge Composite";
        K: Integer;
    begin
        Clear(Trace);
        C.DeleteAll();
        C.Code := 'A';
        C.Insert(true);
        K := C."Entry No.";
        Note('ins.key', Format(K, 0, 9));
        C.Get(K, 'A');
        asserterror C.Rename(K, 'B');
        Note('rename.err', GetLastErrorText());
        Note('rec.key', Format(C."Entry No.", 0, 9) + '/' + C.Code);
        Done('R1', Format(C.Count()));
    end;

    // R2: Rename that changes the AutoIncrement field of a composite key.
    [Test]
    procedure Probe_R2_RenameEntryNo()
    var
        C: Record "AutoInc Edge Composite";
        K: Integer;
    begin
        Clear(Trace);
        C.DeleteAll();
        C.Code := 'A';
        C.Insert(true);
        K := C."Entry No.";
        C.Get(K, 'A');
        asserterror C.Rename(K + 50, 'A');
        Note('rename.err', GetLastErrorText());
        Done('R2', Format(C.Count()));
    end;
}
