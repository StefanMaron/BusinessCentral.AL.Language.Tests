// Fixtures for "Test Rename Key Relation" (60018): parents whose rename must reach a
// referencing field that is part of the child's PRIMARY KEY, and a per-tenant parent whose
// rename must reach a per-company child.
table 60009 "ALT Rename Key Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}

// The referencing field leads the primary key, and the table declares no triggers.
table 60010 "ALT Rename Key Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Parent Code"; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "ALT Rename Key Parent";
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Parent Code", "Line No.")
        {
            Clustered = true;
        }
    }
}

// Same key shape, plus an OnRename trigger that counts how often it ran.
table 60011 "ALT Rename Key Trig Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Parent Code"; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "ALT Rename Key Parent";
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Rename Trigger Runs"; Integer)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Parent Code", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnRename()
    begin
        "Rename Trigger Runs" += 1;
    end;
}

table 60012 "ALT Rename Tenant Parent"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}

// Per-company (the default), referencing the per-tenant parent from a non-key field.
table 60013 "ALT Rename Company Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Parent Code"; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "ALT Rename Tenant Parent";
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
