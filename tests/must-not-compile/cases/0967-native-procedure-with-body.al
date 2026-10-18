// @expect AL0895 | The native procedure 'Run1' can only be declared in the system object ID range within the platform symbols app.
// @expect AL0895 | The native procedure 'Run1' can only be declared in the system object ID range within the platform symbols app.
// @until 27
// The Native attribute on a procedure with a body outside the platform symbols app.
codeunit 58995 "MNC Native 0967"
{
    [Native]
    procedure Run1()
    begin
    end;
}
