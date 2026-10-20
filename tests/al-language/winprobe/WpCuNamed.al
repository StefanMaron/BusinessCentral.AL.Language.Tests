// Windows-check scratch probe (branch al-runtime-rs-staging-winprobe only): Codeunit.Run by qualified name of a codeunit in a namespace.
namespace LTCU.Probe;

codeunit 85308 "LT CU Named Run"
{
    TableNo = "LT CU Row";

    trigger OnRun()
    begin
        Rec.Name := 'x';
    end;
}
