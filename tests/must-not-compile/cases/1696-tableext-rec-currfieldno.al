// @expect AL0161 | 'CurrFieldNo' is inaccessible due to its protection level
// Rec.CurrFieldNo in a table extension procedure (corpus issue 669, item 31). The unqualified CurrFieldNo := 10 in the
// same procedure compiles (events/lt-cm-trigger-leads/CmTriggerLeads.al, Item31_TableExtension_AssignsCurrFieldNo).
table 50000 "MNC CM Tab"
{
    fields { field(1; Id; Integer) { } }
}

tableextension 50001 "MNC CM Tab Ext" extends "MNC CM Tab"
{
    procedure SetIt(Value: Integer)
    begin
        CurrFieldNo := Value;
        Rec.CurrFieldNo := Value;
    end;
}
