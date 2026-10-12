// Fixtures for TestAutoIncrementExplicitKey.al (codeunit 67822). Deliberately their OWN objects: a SingleInstance
// fixture shared between two test codeunits is refused by the repo's own guard (issue #261).

table 67820 "AutoInc Explicit Probe"
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
    var
        Control: Codeunit "AutoInc Explicit Control";
    begin
        Control.NoteOnInsertSaw(Rec."Entry No.");
        case Control.GetMode() of
            1:
                Rec."Entry No." := Control.GetAssignedKey();
            2:
                Error('AutoInc probe: OnInsert refused the row');
        end;
    end;
}

// A second table whose secondary key is unique, so an Insert can fail AFTER the primary key was chosen.
table 67823 "AutoInc Unique Probe"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; Code; Code[20])
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
        key(Uniq; Code)
        {
            Unique = true;
        }
    }
}

// SingleInstance so what a trigger did and what it is told to do survive the calls between them.
codeunit 67821 "AutoInc Explicit Control"
{
    SingleInstance = true;

    var
        Mode: Integer;
        AssignedKey: Integer;
        SawInOnInsert: Integer;

    procedure Reset()
    begin
        Mode := 0;
        AssignedKey := 0;
        SawInOnInsert := -1;
    end;

    procedure AssignKeyInOnInsert(NewKey: Integer)
    begin
        Mode := 1;
        AssignedKey := NewKey;
    end;

    procedure FailInOnInsert()
    begin
        Mode := 2;
    end;

    procedure GetMode(): Integer
    begin
        exit(Mode);
    end;

    procedure GetAssignedKey(): Integer
    begin
        exit(AssignedKey);
    end;

    procedure NoteOnInsertSaw(KeyValue: Integer)
    begin
        SawInOnInsert := KeyValue;
    end;

    procedure GetSawInOnInsert(): Integer
    begin
        exit(SawInOnInsert);
    end;
}

// Manual so it only observes the tests that bind it.
codeunit 67824 "AutoInc Explicit Subscriber"
{
    EventSubscriberInstance = Manual;

    var
        AssignedKey: Integer;

    procedure SetKey(NewKey: Integer)
    begin
        AssignedKey := NewKey;
    end;

    [EventSubscriber(ObjectType::Table, Database::"AutoInc Explicit Probe", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsert(var Rec: Record "AutoInc Explicit Probe")
    begin
        Rec."Entry No." := AssignedKey;
    end;
}
