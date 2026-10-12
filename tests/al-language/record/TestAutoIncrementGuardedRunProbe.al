// PROBE for StefanMaron/BusinessCentral.AL.Runner#5527, to be replaced by an assertion or removed once read.
// Shape M: an inner guarded run SUCCEEDS after a Truncate(true) and an Insert, then the outer run Inserts and fails.
// Does the outer failure undo the inner run's Truncate (rows 1 to 3 and the counter back), or is the inner run durable?

table 67855 "GuardRun Probe M"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; Payload; Text[30])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}

codeunit 67855 "GuardRun Inner M"
{
    trigger OnRun()
    var
        R: Record "GuardRun Probe M";
    begin
        R.Truncate(true);
        R.Payload := 'inner';
        R.Insert(true);
    end;
}

codeunit 67856 "GuardRun Outer M"
{
    trigger OnRun()
    var
        R: Record "GuardRun Probe M";
        Ok: Boolean;
    begin
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner M");
        R.Payload := 'outer';
        R.Insert(true);
        Error('outer error, key %1', R."Entry No.");
    end;
}

codeunit 67857 "Test AutoInc Guarded Run Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ProbeM_InnerSucceeds_OuterFails()
    var
        R: Record "GuardRun Probe M";
        Ok: Boolean;
        Ins: Boolean;
        Next: Integer;
        Keys: Text;
        RunErr: Text;
    begin
        R.Truncate(true);
        ZeroM();
        ZeroM();
        ZeroM();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Outer M");
        RunErr := GetLastErrorText();
        Clear(R);
        R.Payload := 'next';
        Ins := R.Insert(true);
        Next := R."Entry No.";
        if R.FindSet() then
            repeat
                Keys += Format(R."Entry No.") + ',';
            until R.Next() = 0;
        Error('PROBE M :: ok=%1 runErr=%2 insOk=%3 nextKey=%4 count=%5 keys=%6', Ok, RunErr, Ins, Next, R.Count(), Keys);
    end;

    local procedure ZeroM(): Integer
    var
        R: Record "GuardRun Probe M";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;
}
