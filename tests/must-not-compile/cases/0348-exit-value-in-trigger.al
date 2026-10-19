// @expect AL0139 | Since 'OnRun' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in the OnRun trigger.
codeunit 50166 "MNC C348"
{
    trigger OnRun()
    begin
        exit(1);
    end;
}
