// Fixtures for TestAutoIncrementGuardedRun.al (codeunit 67840): a guarded Codeunit.Run that fails after it wrote to a
// table with an AutoIncrement key. One table and one failing codeunit per shape, so no shape shares a counter, and
// each table is first used by its own test, so the counter starts at 1.

table 67840 "GuardRun Probe A"
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

table 67841 "GuardRun Probe B"
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

table 67842 "GuardRun Probe C"
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

table 67843 "GuardRun Probe D"
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

table 67845 "GuardRun Probe F"
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

table 67846 "GuardRun Probe G"
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

table 67847 "GuardRun Probe H"
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

table 67848 "GuardRun Probe I"
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

table 67850 "GuardRun Probe K"
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

codeunit 67841 "GuardRun Inner A"
{
    trigger OnRun()
    var
        R: Record "GuardRun Probe A";
    begin
        R.Truncate(true);
        R.Payload := 'inner';
        R.Insert(true);
        Error('inner error, key %1', R."Entry No.");
    end;
}

codeunit 67842 "GuardRun Inner B"
{
    trigger OnRun()
    var
        R: Record "GuardRun Probe B";
    begin
        R.Truncate(false);
        R.Payload := 'inner';
        R.Insert(true);
        Error('inner error, key %1', R."Entry No.");
    end;
}

codeunit 67843 "GuardRun Inner C"
{
    trigger OnRun()
    var
        R: Record "GuardRun Probe C";
    begin
        R.Payload := 'inner';
        R.Insert(true);
        Error('inner error, key %1', R."Entry No.");
    end;
}

codeunit 67844 "GuardRun Inner D"
{
    trigger OnRun()
    var
        R: Record "GuardRun Probe D";
    begin
        R.DeleteAll();
        R.Payload := 'inner';
        R.Insert(true);
        Error('inner error, key %1', R."Entry No.");
    end;
}

codeunit 67846 "GuardRun Inner F"
{
    trigger OnRun()
    var
        R: Record "GuardRun Probe F";
    begin
        R.Truncate(true);
        R.Payload := 'inner';
        R.Insert(true);
        Error('inner error, key %1', R."Entry No.");
    end;
}

codeunit 67847 "GuardRun Inner G"
{
    trigger OnRun()
    var
        R: Record "GuardRun Probe G";
    begin
        R.Truncate(true);
        R.Payload := 'inner';
        R.Insert(true);
        Error('inner error, key %1', R."Entry No.");
    end;
}

codeunit 67848 "GuardRun Inner H"
{
    trigger OnRun()
    var
        R: Record "GuardRun Probe H";
    begin
        R.Truncate(true);
        R.Payload := 'inner';
        R.Insert(true);
        Error('inner error, key %1', R."Entry No.");
    end;
}

codeunit 67849 "GuardRun Inner I"
{
    trigger OnRun()
    var
        R: Record "GuardRun Probe I";
    begin
        R.Truncate(true);
        R.Payload := 'inner';
        R.Insert(true);
        Error('inner error, key %1', R."Entry No.");
    end;
}

codeunit 67851 "GuardRun Inner K"
{
    trigger OnRun()
    var
        R: Record "GuardRun Probe K";
    begin
        R.Truncate(true);
        R.Payload := 'inner';
        R.Insert(true);
        Error('inner error, key %1', R."Entry No.");
    end;
}

// Shape H: an outer run that swallows a failed inner run, writes, and succeeds.
codeunit 67853 "GuardRun Outer H"
{
    trigger OnRun()
    var
        R: Record "GuardRun Probe H";
        Ok: Boolean;
    begin
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner H");
        R.Payload := 'outer';
        R.Insert(true);
    end;
}

// Shape I: an outer run that swallows a failed inner run, writes, and then fails itself.
codeunit 67854 "GuardRun Outer I"
{
    trigger OnRun()
    var
        R: Record "GuardRun Probe I";
        Ok: Boolean;
    begin
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner I");
        R.Payload := 'outer';
        R.Insert(true);
        Error('outer error, key %1', R."Entry No.");
    end;
}
