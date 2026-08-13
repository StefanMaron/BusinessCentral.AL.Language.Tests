// ALT Universal declares no field triggers of its own. This extension pins the
// contract that a tableextension-added field's OnValidate runs even when the
// base table has no field triggers at all — the common shape of a per-tenant
// extension adding validated fields to a plain table.
tableextension 60025 "ALT Universal Validated Ext" extends "ALT Universal"
{
    fields
    {
        field(60250; "Ext Validated"; Text[50])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                TrigLog: Record "ALT Trigger Log";
            begin
                TrigLog.Init();
                TrigLog.TriggerName := 'UniversalExtOnValidate';
                TrigLog.SourceEntryNo := Rec."Entry No.";
                TrigLog.OldValue := xRec."Ext Validated";
                TrigLog.NewValue := Rec."Ext Validated";
                TrigLog.Insert();
            end;
        }
    }
}
