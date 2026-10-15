// @expect AL0164 | The trigger 'OnRun' is already defined
// A codeunit has two OnRun triggers.
codeunit 50113 "MNC C300"
{
    trigger OnRun()
    begin
    end;

    trigger OnRun()
    begin
    end;
}
