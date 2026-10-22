// @expect AL0118 | The name 'NoSuchProc' does not exist in the current context.
// A procedure that does not exist is called in a codeunit.
codeunit 50002 "MNC C201"
{
    procedure Run1()
    begin
        NoSuchProc();
    end;
}
