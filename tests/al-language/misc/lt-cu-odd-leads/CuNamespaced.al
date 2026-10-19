// Fixture of the "LT CU" probes (corpus #670 item 42): a TableNo codeunit inside a namespace, for Codeunit.Run by qualified name (BC 28+).
// Scope: in-scope
namespace LTCU.Probe;

codeunit 85308 "LT CU Named Run"
{
    TableNo = "LT CU Row";

    trigger OnRun()
    begin
        Rec.Name := 'set by named OnRun';
    end;
}
