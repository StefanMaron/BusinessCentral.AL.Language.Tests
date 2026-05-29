table 60002 "ALT Triggered"
{
    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Name"; Text[50])
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Value"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(4; "Watched Field"; Text[100])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                TrigLog: Record "ALT Trigger Log";
            begin
                TrigLog."TriggerName" := 'OnValidate';
                TrigLog."SourceEntryNo" := Rec."Entry No.";
                TrigLog."NewValue" := Rec."Watched Field";
                TrigLog."LoggedAt" := CurrentDateTime();
                TrigLog.Insert();
            end;
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
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog."TriggerName" := 'OnInsert';
        TrigLog."SourceEntryNo" := Rec."Entry No.";
        TrigLog."OldEntryNo" := xRec."Entry No.";
        TrigLog."NewEntryNo" := Rec."Entry No.";
        TrigLog."OldIntegerValue" := xRec.Value;
        TrigLog."NewIntegerValue" := Rec.Value;
        TrigLog."OldValue" := xRec."Watched Field";
        TrigLog."NewValue" := Rec."Watched Field";
        TrigLog."LoggedAt" := CurrentDateTime();
        TrigLog.Insert();
    end;

    trigger OnModify()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog."TriggerName" := 'OnModify';
        TrigLog."SourceEntryNo" := Rec."Entry No.";
        TrigLog."OldEntryNo" := xRec."Entry No.";
        TrigLog."NewEntryNo" := Rec."Entry No.";
        TrigLog."OldIntegerValue" := xRec.Value;
        TrigLog."NewIntegerValue" := Rec.Value;
        TrigLog."LoggedAt" := CurrentDateTime();
        TrigLog.Insert();
    end;

    trigger OnDelete()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog."TriggerName" := 'OnDelete';
        TrigLog."SourceEntryNo" := Rec."Entry No.";
        TrigLog."OldEntryNo" := xRec."Entry No.";
        TrigLog."NewEntryNo" := Rec."Entry No.";
        TrigLog."OldIntegerValue" := xRec.Value;
        TrigLog."NewIntegerValue" := Rec.Value;
        TrigLog."LoggedAt" := CurrentDateTime();
        TrigLog.Insert();
    end;

    trigger OnRename()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog."TriggerName" := 'OnRename';
        TrigLog."SourceEntryNo" := Rec."Entry No.";
        TrigLog."OldEntryNo" := xRec."Entry No.";
        TrigLog."NewEntryNo" := Rec."Entry No.";
        TrigLog."OldIntegerValue" := xRec.Value;
        TrigLog."NewIntegerValue" := Rec.Value;
        TrigLog."LoggedAt" := CurrentDateTime();
        TrigLog.Insert();
    end;
}

table 60003 "ALT Trigger Log"
{
    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "TriggerName"; Code[30])
        {
            DataClassification = SystemMetadata;
        }
        field(3; "SourceEntryNo"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(4; "OldValue"; Text[100])
        {
            DataClassification = SystemMetadata;
        }
        field(5; "NewValue"; Text[100])
        {
            DataClassification = SystemMetadata;
        }
        field(6; "LoggedAt"; DateTime)  // renamed from Timestamp (conflicts with SystemRowVersion)
        {
            DataClassification = SystemMetadata;
        }
        field(7; "OldEntryNo"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(8; "NewEntryNo"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(9; "OldIntegerValue"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(10; "NewIntegerValue"; Integer)
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
