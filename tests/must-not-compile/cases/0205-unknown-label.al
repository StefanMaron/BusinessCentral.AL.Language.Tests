// @expect AL0118 | The name 'MissingLbl' does not exist in the current context.
// A label name that is never declared is passed to Error.
codeunit 50008 "MNC C205"
{
    procedure Run1()
    begin
        Error(MissingLbl);
    end;
}
