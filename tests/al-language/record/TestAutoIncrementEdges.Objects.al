// Fixtures for TestAutoIncrementEdges.al (codeunit 67826). Their own objects, with no SingleInstance control
// codeunit: a row asks its own OnInsert to refuse through its Payload.

table 67825 "AutoInc Edge A"
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

    trigger OnInsert()
    begin
        if Rec.Payload = 'refuse' then
            Error('AutoInc edge: OnInsert refused the row');
    end;
}

table 67829 "AutoInc Edge B"
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

    trigger OnInsert()
    begin
        if Rec.Payload = 'refuse' then
            Error('AutoInc edge: OnInsert refused the row');
    end;
}

table 67830 "AutoInc Edge C"
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

    trigger OnInsert()
    begin
        if Rec.Payload = 'refuse' then
            Error('AutoInc edge: OnInsert refused the row');
    end;
}

table 67831 "AutoInc Edge D"
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

    trigger OnInsert()
    begin
        if Rec.Payload = 'refuse' then
            Error('AutoInc edge: OnInsert refused the row');
    end;
}

table 67832 "AutoInc Edge E"
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

    trigger OnInsert()
    begin
        if Rec.Payload = 'refuse' then
            Error('AutoInc edge: OnInsert refused the row');
    end;
}

table 67835 "AutoInc Edge F"
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

    trigger OnInsert()
    begin
        if Rec.Payload = 'refuse' then
            Error('AutoInc edge: OnInsert refused the row');
    end;
}

table 67836 "AutoInc Edge G"
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

    trigger OnInsert()
    begin
        if Rec.Payload = 'refuse' then
            Error('AutoInc edge: OnInsert refused the row');
    end;
}

table 67837 "AutoInc Edge H"
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

    trigger OnInsert()
    begin
        if Rec.Payload = 'refuse' then
            Error('AutoInc edge: OnInsert refused the row');
    end;
}

table 67827 "AutoInc Edge Big"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; BigInteger)
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

// The AutoIncrement field is part of a composite primary key, so a Rename can change the other key field only.
table 67834 "AutoInc Edge Composite"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; Code; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(3; Payload; Text[30])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.", Code)
        {
            Clustered = true;
        }
    }
}
