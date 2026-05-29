tableextension 60024 "ALT Triggered Order Ext" extends "ALT Triggered"
{
    fields
    {
        modify("Watched Field")
        {
            trigger OnBeforeValidate()
            var
                TrigLog: Record "ALT Trigger Log";
            begin
                TrigLog.Init();
                TrigLog.TriggerName := 'TableExtOnBeforeValidate';
                TrigLog.SourceEntryNo := Rec."Entry No.";
                TrigLog.OldValue := xRec."Watched Field";
                TrigLog.NewValue := Rec."Watched Field";
                TrigLog.Insert();
            end;

            trigger OnAfterValidate()
            var
                TrigLog: Record "ALT Trigger Log";
            begin
                TrigLog.Init();
                TrigLog.TriggerName := 'TableExtOnAfterValidate';
                TrigLog.SourceEntryNo := Rec."Entry No.";
                TrigLog.OldValue := xRec."Watched Field";
                TrigLog.NewValue := Rec."Watched Field";
                TrigLog.Insert();
            end;
        }
    }

    trigger OnBeforeInsert()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'TableExtOnBeforeInsert';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.NewEntryNo := Rec."Entry No.";
        TrigLog.NewIntegerValue := Rec.Value;
        TrigLog.NewValue := Rec."Watched Field";
        TrigLog.Insert();
    end;

    trigger OnInsert()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'TableExtOnInsert';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.NewEntryNo := Rec."Entry No.";
        TrigLog.NewIntegerValue := Rec.Value;
        TrigLog.NewValue := Rec."Watched Field";
        TrigLog.Insert();
    end;

    trigger OnAfterInsert()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'TableExtOnAfterInsert';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.NewEntryNo := Rec."Entry No.";
        TrigLog.NewIntegerValue := Rec.Value;
        TrigLog.NewValue := Rec."Watched Field";
        TrigLog.Insert();
    end;

    trigger OnBeforeModify()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'TableExtOnBeforeModify';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.OldEntryNo := xRec."Entry No.";
        TrigLog.NewEntryNo := Rec."Entry No.";
        TrigLog.OldIntegerValue := xRec.Value;
        TrigLog.NewIntegerValue := Rec.Value;
        TrigLog.OldValue := xRec."Watched Field";
        TrigLog.NewValue := Rec."Watched Field";
        TrigLog.Insert();
    end;

    trigger OnModify()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'TableExtOnModify';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.OldEntryNo := xRec."Entry No.";
        TrigLog.NewEntryNo := Rec."Entry No.";
        TrigLog.OldIntegerValue := xRec.Value;
        TrigLog.NewIntegerValue := Rec.Value;
        TrigLog.OldValue := xRec."Watched Field";
        TrigLog.NewValue := Rec."Watched Field";
        TrigLog.Insert();
    end;

    trigger OnAfterModify()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'TableExtOnAfterModify';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.OldEntryNo := xRec."Entry No.";
        TrigLog.NewEntryNo := Rec."Entry No.";
        TrigLog.OldIntegerValue := xRec.Value;
        TrigLog.NewIntegerValue := Rec.Value;
        TrigLog.OldValue := xRec."Watched Field";
        TrigLog.NewValue := Rec."Watched Field";
        TrigLog.Insert();
    end;

    trigger OnBeforeDelete()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'TableExtOnBeforeDelete';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.NewEntryNo := Rec."Entry No.";
        TrigLog.NewIntegerValue := Rec.Value;
        TrigLog.NewValue := Rec."Watched Field";
        TrigLog.Insert();
    end;

    trigger OnDelete()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'TableExtOnDelete';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.NewEntryNo := Rec."Entry No.";
        TrigLog.NewIntegerValue := Rec.Value;
        TrigLog.NewValue := Rec."Watched Field";
        TrigLog.Insert();
    end;

    trigger OnAfterDelete()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'TableExtOnAfterDelete';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.NewEntryNo := Rec."Entry No.";
        TrigLog.NewIntegerValue := Rec.Value;
        TrigLog.NewValue := Rec."Watched Field";
        TrigLog.Insert();
    end;

    trigger OnBeforeRename()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'TableExtOnBeforeRename';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.OldEntryNo := xRec."Entry No.";
        TrigLog.NewEntryNo := Rec."Entry No.";
        TrigLog.OldIntegerValue := xRec.Value;
        TrigLog.NewIntegerValue := Rec.Value;
        TrigLog.Insert();
    end;

    trigger OnRename()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'TableExtOnRename';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.OldEntryNo := xRec."Entry No.";
        TrigLog.NewEntryNo := Rec."Entry No.";
        TrigLog.OldIntegerValue := xRec.Value;
        TrigLog.NewIntegerValue := Rec.Value;
        TrigLog.Insert();
    end;

    trigger OnAfterRename()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'TableExtOnAfterRename';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.OldEntryNo := xRec."Entry No.";
        TrigLog.NewEntryNo := Rec."Entry No.";
        TrigLog.OldIntegerValue := xRec.Value;
        TrigLog.NewIntegerValue := Rec.Value;
        TrigLog.Insert();
    end;
}
