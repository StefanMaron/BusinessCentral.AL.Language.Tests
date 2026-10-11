// Fixtures for TestXRecStampFields.al (codeunit 67812). Deliberately its OWN table and recorder:
// the shared ALT Triggered fixture logs only the user fields of Rec and xRec, and the probe needs the
// system fields and an AutoIncrement key read from inside each trigger.

table 67810 "xRec Stamp Probe"
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
        Capture('OnInsert');
    end;

    trigger OnModify()
    begin
        Capture('OnModify');
    end;

    trigger OnDelete()
    begin
        Capture('OnDelete');
    end;

    local procedure Capture(TriggerName: Text)
    var
        Recorder: Codeunit "xRec Stamp Recorder";
    begin
        Recorder.Put(TriggerName, 'Rec.EntryNo', Format(Rec."Entry No.", 0, 9));
        Recorder.Put(TriggerName, 'xRec.EntryNo', Format(xRec."Entry No.", 0, 9));
        Recorder.Put(TriggerName, 'Rec.SystemId', Format(Rec.SystemId, 0, 9));
        Recorder.Put(TriggerName, 'xRec.SystemId', Format(xRec.SystemId, 0, 9));
        Recorder.Put(TriggerName, 'Rec.SystemCreatedAt', Format(Rec.SystemCreatedAt, 0, 9));
        Recorder.Put(TriggerName, 'xRec.SystemCreatedAt', Format(xRec.SystemCreatedAt, 0, 9));
        Recorder.Put(TriggerName, 'Rec.SystemModifiedAt', Format(Rec.SystemModifiedAt, 0, 9));
        Recorder.Put(TriggerName, 'xRec.SystemModifiedAt', Format(xRec.SystemModifiedAt, 0, 9));
        Recorder.Put(TriggerName, 'Rec.SystemCreatedBy', Format(Rec.SystemCreatedBy, 0, 9));
        Recorder.Put(TriggerName, 'xRec.SystemCreatedBy', Format(xRec.SystemCreatedBy, 0, 9));
        Recorder.Put(TriggerName, 'Rec.SystemModifiedBy', Format(Rec.SystemModifiedBy, 0, 9));
        Recorder.Put(TriggerName, 'xRec.SystemModifiedBy', Format(xRec.SystemModifiedBy, 0, 9));
        Recorder.Put(TriggerName, 'Rec.Payload', Rec.Payload);
        Recorder.Put(TriggerName, 'xRec.Payload', xRec.Payload);
    end;
}

// SingleInstance so what a trigger saw survives the call that ran it; the value is written during the
// operation and read back by the test after it returns.
codeunit 67811 "xRec Stamp Recorder"
{
    SingleInstance = true;

    var
        Seen: Dictionary of [Text, Text];

    procedure Wipe()
    begin
        Clear(Seen);
    end;

    procedure Put(TriggerName: Text; What: Text; Value: Text)
    begin
        Seen.Set(TriggerName + '|' + What, Value);
    end;

    procedure Has(TriggerName: Text; What: Text): Boolean
    begin
        exit(Seen.ContainsKey(TriggerName + '|' + What));
    end;

    procedure Read(TriggerName: Text; What: Text): Text
    begin
        exit(Seen.Get(TriggerName + '|' + What));
    end;

    // One letter per observation, so a probe message stays inside Error()'s length limit:
    // 0 = the type's default, P = the value stored before the operation, Q = the value stored after it,
    // ? = anything else.
    procedure Classify(TriggerName: Text; What: Text; Pre: Text; Post: Text): Text
    var
        V: Text;
    begin
        V := Read(TriggerName, What);
        if (V = '') or (V = '{00000000-0000-0000-0000-000000000000}') then
            exit('0');
        if (Pre <> '') and (V = Pre) then
            exit('P');
        if V = Post then
            exit('Q');
        exit('?');
    end;
}
