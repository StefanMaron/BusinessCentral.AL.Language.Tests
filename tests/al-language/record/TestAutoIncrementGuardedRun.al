// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope (Cloud-compatible)
// PROBE for StefanMaron/BusinessCentral.AL.Runner#5527: every test ends with Error('PROBE ...') so the cloud legs and
// the Windows nightly print the measured shape in the failure message.

codeunit 67840 "Test AutoInc Guarded Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ProbeA_TruncateTrue_InGuardedRun()
    // Truncate(true) then Insert then Error in a guarded run; Commit before.
    var
        R: Record "GuardRun Probe A";
        Ok: Boolean;
        Ins: Boolean;
        C3: Integer;
        Next: Integer;
        Report: Text;
        RunErr: Text;
    begin
        R.Truncate(true);
        ZA();
        ZA();
        C3 := ZA();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner A");
        RunErr := GetLastErrorText();
        Clear(R);
        R.Payload := 'next';
        Ins := R.Insert(true);
        Next := R."Entry No.";
        Report := KeysA();
        Error('PROBE A :: ok=%1 runErr=%2 insOk=%3 nextKey=%4 count=%5 keys=%6 c3=%7', Ok, RunErr, Ins, Next, R.Count(), Report, C3);
    end;

    [Test]
    procedure ProbeB_TruncateFalse_InGuardedRun()
    // Truncate(false) twin of A.
    var
        R: Record "GuardRun Probe B";
        Ok: Boolean;
        Ins: Boolean;
        C3: Integer;
        Next: Integer;
        Report: Text;
        RunErr: Text;
    begin
        R.Truncate(true);
        ZB();
        ZB();
        C3 := ZB();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner B");
        RunErr := GetLastErrorText();
        Clear(R);
        R.Payload := 'next';
        Ins := R.Insert(true);
        Next := R."Entry No.";
        Report := KeysB();
        Error('PROBE B :: ok=%1 runErr=%2 insOk=%3 nextKey=%4 count=%5 keys=%6 c3=%7', Ok, RunErr, Ins, Next, R.Count(), Report, C3);
    end;

    [Test]
    procedure ProbeC_PlainInsert_InGuardedRun()
    // No Truncate: a plain Insert then Error.
    var
        R: Record "GuardRun Probe C";
        Ok: Boolean;
        Ins: Boolean;
        C3: Integer;
        Next: Integer;
        Report: Text;
        RunErr: Text;
    begin
        R.Truncate(true);
        ZC();
        ZC();
        C3 := ZC();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner C");
        RunErr := GetLastErrorText();
        Clear(R);
        R.Payload := 'next';
        Ins := R.Insert(true);
        Next := R."Entry No.";
        Report := KeysC();
        Error('PROBE C :: ok=%1 runErr=%2 insOk=%3 nextKey=%4 count=%5 keys=%6 c3=%7', Ok, RunErr, Ins, Next, R.Count(), Report, C3);
    end;

    [Test]
    procedure ProbeD_DeleteAll_InGuardedRun()
    // DeleteAll twin of A.
    var
        R: Record "GuardRun Probe D";
        Ok: Boolean;
        Ins: Boolean;
        C3: Integer;
        Next: Integer;
        Report: Text;
        RunErr: Text;
    begin
        R.Truncate(true);
        ZD();
        ZD();
        C3 := ZD();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner D");
        RunErr := GetLastErrorText();
        Clear(R);
        R.Payload := 'next';
        Ins := R.Insert(true);
        Next := R."Entry No.";
        Report := KeysD();
        Error('PROBE D :: ok=%1 runErr=%2 insOk=%3 nextKey=%4 count=%5 keys=%6 c3=%7', Ok, RunErr, Ins, Next, R.Count(), Report, C3);
    end;

    [Test]
    procedure ProbeE_NoCommitBefore()
    // A without the Commit before the guarded run.
    var
        R: Record "GuardRun Probe E";
        Ok: Boolean;
        Ins: Boolean;
        C3: Integer;
        Next: Integer;
        Report: Text;
        RunErr: Text;
    begin
        R.Truncate(true);
        ZE();
        ZE();
        C3 := ZE();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner E");
        RunErr := GetLastErrorText();
        Clear(R);
        R.Payload := 'next';
        Ins := R.Insert(true);
        Next := R."Entry No.";
        Report := KeysE();
        Error('PROBE E :: ok=%1 runErr=%2 insOk=%3 nextKey=%4 count=%5 keys=%6 c3=%7', Ok, RunErr, Ins, Next, R.Count(), Report, C3);
    end;

    [Test]
    procedure ProbeF_DeletedLastRow()
    // A with the highest key deleted and committed before the guarded run (counter vs the rows' high-water mark).
    var
        R: Record "GuardRun Probe F";
        Ok: Boolean;
        Ins: Boolean;
        C3: Integer;
        Next: Integer;
        Report: Text;
        RunErr: Text;
    begin
        R.Truncate(true);
        ZF();
        ZF();
        C3 := ZF();
        R.Get(C3);
        R.Delete();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner F");
        RunErr := GetLastErrorText();
        Clear(R);
        R.Payload := 'next';
        Ins := R.Insert(true);
        Next := R."Entry No.";
        Report := KeysF();
        Error('PROBE F :: ok=%1 runErr=%2 insOk=%3 nextKey=%4 count=%5 keys=%6 c3=%7', Ok, RunErr, Ins, Next, R.Count(), Report, C3);
    end;

    [Test]
    procedure ProbeG_NeverUsedTable()
    // A on a table whose counter has never been taken (restarted counter equals the initial one).
    var
        R: Record "GuardRun Probe G";
        Ok: Boolean;
        Ins: Boolean;
        C3: Integer;
        Next: Integer;
        Report: Text;
        RunErr: Text;
    begin
        R.Truncate(true);
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner G");
        RunErr := GetLastErrorText();
        Clear(R);
        R.Payload := 'next';
        Ins := R.Insert(true);
        Next := R."Entry No.";
        Report := KeysG();
        Error('PROBE G :: ok=%1 runErr=%2 insOk=%3 nextKey=%4 count=%5 keys=%6 c3=%7', Ok, RunErr, Ins, Next, R.Count(), Report, C3);
    end;

    [Test]
    procedure ProbeH_NestedInnerFails_OuterSucceeds()
    // Outer guarded run swallows a failing inner run that truncated, inserts, and succeeds.
    var
        R: Record "GuardRun Probe H";
        Ok: Boolean;
        Ins: Boolean;
        C3: Integer;
        Next: Integer;
        Report: Text;
        RunErr: Text;
    begin
        R.Truncate(true);
        ZH();
        ZH();
        C3 := ZH();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Outer H");
        RunErr := GetLastErrorText();
        Clear(R);
        R.Payload := 'next';
        Ins := R.Insert(true);
        Next := R."Entry No.";
        Report := KeysH();
        Error('PROBE H :: ok=%1 runErr=%2 insOk=%3 nextKey=%4 count=%5 keys=%6 c3=%7', Ok, RunErr, Ins, Next, R.Count(), Report, C3);
    end;

    [Test]
    procedure ProbeI_NestedInnerFails_OuterFails()
    // Outer guarded run swallows a failing inner run that truncated, inserts, and fails.
    var
        R: Record "GuardRun Probe I";
        Ok: Boolean;
        Ins: Boolean;
        C3: Integer;
        Next: Integer;
        Report: Text;
        RunErr: Text;
    begin
        R.Truncate(true);
        ZI();
        ZI();
        C3 := ZI();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Outer I");
        RunErr := GetLastErrorText();
        Clear(R);
        R.Payload := 'next';
        Ins := R.Insert(true);
        Next := R."Entry No.";
        Report := KeysI();
        Error('PROBE I :: ok=%1 runErr=%2 insOk=%3 nextKey=%4 count=%5 keys=%6 c3=%7', Ok, RunErr, Ins, Next, R.Count(), Report, C3);
    end;

    [Test]
    procedure ProbeK_TruncateTrue_InGuardedRun_PrimedWithDeleteAll()
    // A, but the caller never truncates: it primes with DeleteAll.
    var
        R: Record "GuardRun Probe K";
        Ok: Boolean;
        Ins: Boolean;
        C3: Integer;
        Next: Integer;
        Report: Text;
        RunErr: Text;
    begin
        R.DeleteAll();
        ZK();
        ZK();
        C3 := ZK();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner K");
        RunErr := GetLastErrorText();
        Clear(R);
        R.Payload := 'next';
        Ins := R.Insert(true);
        Next := R."Entry No.";
        Report := KeysK();
        Error('PROBE K :: ok=%1 runErr=%2 insOk=%3 nextKey=%4 count=%5 keys=%6 c3=%7', Ok, RunErr, Ins, Next, R.Count(), Report, C3);
    end;

    [Test]
    procedure ProbeL_DeleteAll_InGuardedRun_PrimedWithDeleteAll()
    // D, but the caller never truncates: no Truncate anywhere (control).
    var
        R: Record "GuardRun Probe L";
        Ok: Boolean;
        Ins: Boolean;
        C3: Integer;
        Next: Integer;
        Report: Text;
        RunErr: Text;
    begin
        R.DeleteAll();
        ZL();
        ZL();
        C3 := ZL();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner L");
        RunErr := GetLastErrorText();
        Clear(R);
        R.Payload := 'next';
        Ins := R.Insert(true);
        Next := R."Entry No.";
        Report := KeysL();
        Error('PROBE L :: ok=%1 runErr=%2 insOk=%3 nextKey=%4 count=%5 keys=%6 c3=%7', Ok, RunErr, Ins, Next, R.Count(), Report, C3);
    end;

    [Test]
    procedure ProbeJ_TruncateInCallerThenGuardedInsert()
    // The caller truncates (uncommitted), then a guarded run inserts and fails.
    var
        R: Record "GuardRun Probe J";
        Ok: Boolean;
        Ins: Boolean;
        C3: Integer;
        Next: Integer;
        Report: Text;
        RunErr: Text;
    begin
        R.Truncate(true);
        ZJ();
        ZJ();
        C3 := ZJ();
        Commit();
        R.Truncate(true);
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner J");
        RunErr := GetLastErrorText();
        Clear(R);
        R.Payload := 'next';
        Ins := R.Insert(true);
        Next := R."Entry No.";
        Report := KeysJ();
        Error('PROBE J :: ok=%1 runErr=%2 insOk=%3 nextKey=%4 count=%5 keys=%6 c3=%7', Ok, RunErr, Ins, Next, R.Count(), Report, C3);
    end;

    local procedure ZA(): Integer
    var
        R: Record "GuardRun Probe A";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure KeysA(): Text
    var
        R: Record "GuardRun Probe A";
        T: Text;
    begin
        R.SetCurrentKey("Entry No.");
        if R.FindSet() then
            repeat
                T += Format(R."Entry No.") + ',';
            until R.Next() = 0;
        exit(T);
    end;

    local procedure ZB(): Integer
    var
        R: Record "GuardRun Probe B";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure KeysB(): Text
    var
        R: Record "GuardRun Probe B";
        T: Text;
    begin
        R.SetCurrentKey("Entry No.");
        if R.FindSet() then
            repeat
                T += Format(R."Entry No.") + ',';
            until R.Next() = 0;
        exit(T);
    end;

    local procedure ZC(): Integer
    var
        R: Record "GuardRun Probe C";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure KeysC(): Text
    var
        R: Record "GuardRun Probe C";
        T: Text;
    begin
        R.SetCurrentKey("Entry No.");
        if R.FindSet() then
            repeat
                T += Format(R."Entry No.") + ',';
            until R.Next() = 0;
        exit(T);
    end;

    local procedure ZD(): Integer
    var
        R: Record "GuardRun Probe D";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure KeysD(): Text
    var
        R: Record "GuardRun Probe D";
        T: Text;
    begin
        R.SetCurrentKey("Entry No.");
        if R.FindSet() then
            repeat
                T += Format(R."Entry No.") + ',';
            until R.Next() = 0;
        exit(T);
    end;

    local procedure ZE(): Integer
    var
        R: Record "GuardRun Probe E";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure KeysE(): Text
    var
        R: Record "GuardRun Probe E";
        T: Text;
    begin
        R.SetCurrentKey("Entry No.");
        if R.FindSet() then
            repeat
                T += Format(R."Entry No.") + ',';
            until R.Next() = 0;
        exit(T);
    end;

    local procedure ZF(): Integer
    var
        R: Record "GuardRun Probe F";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure KeysF(): Text
    var
        R: Record "GuardRun Probe F";
        T: Text;
    begin
        R.SetCurrentKey("Entry No.");
        if R.FindSet() then
            repeat
                T += Format(R."Entry No.") + ',';
            until R.Next() = 0;
        exit(T);
    end;

    local procedure ZG(): Integer
    var
        R: Record "GuardRun Probe G";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure KeysG(): Text
    var
        R: Record "GuardRun Probe G";
        T: Text;
    begin
        R.SetCurrentKey("Entry No.");
        if R.FindSet() then
            repeat
                T += Format(R."Entry No.") + ',';
            until R.Next() = 0;
        exit(T);
    end;

    local procedure ZH(): Integer
    var
        R: Record "GuardRun Probe H";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure KeysH(): Text
    var
        R: Record "GuardRun Probe H";
        T: Text;
    begin
        R.SetCurrentKey("Entry No.");
        if R.FindSet() then
            repeat
                T += Format(R."Entry No.") + ',';
            until R.Next() = 0;
        exit(T);
    end;

    local procedure ZI(): Integer
    var
        R: Record "GuardRun Probe I";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure KeysI(): Text
    var
        R: Record "GuardRun Probe I";
        T: Text;
    begin
        R.SetCurrentKey("Entry No.");
        if R.FindSet() then
            repeat
                T += Format(R."Entry No.") + ',';
            until R.Next() = 0;
        exit(T);
    end;

    local procedure ZJ(): Integer
    var
        R: Record "GuardRun Probe J";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure KeysJ(): Text
    var
        R: Record "GuardRun Probe J";
        T: Text;
    begin
        R.SetCurrentKey("Entry No.");
        if R.FindSet() then
            repeat
                T += Format(R."Entry No.") + ',';
            until R.Next() = 0;
        exit(T);
    end;

    local procedure ZK(): Integer
    var
        R: Record "GuardRun Probe K";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure KeysK(): Text
    var
        R: Record "GuardRun Probe K";
        T: Text;
    begin
        R.SetCurrentKey("Entry No.");
        if R.FindSet() then
            repeat
                T += Format(R."Entry No.") + ',';
            until R.Next() = 0;
        exit(T);
    end;

    local procedure ZL(): Integer
    var
        R: Record "GuardRun Probe L";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure KeysL(): Text
    var
        R: Record "GuardRun Probe L";
        T: Text;
    begin
        R.SetCurrentKey("Entry No.");
        if R.FindSet() then
            repeat
                T += Format(R."Entry No.") + ',';
            until R.Next() = 0;
        exit(T);
    end;
}
