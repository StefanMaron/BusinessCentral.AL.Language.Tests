// @expect AL0118 | The name 'Missing' does not exist in the current context.
// An undeclared variable is assigned in a codeunit.
codeunit 50001 "MNC C200"
{
    procedure Run1()
    begin
        Missing := 1;
    end;
}
