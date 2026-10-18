// @expect AL0895 | The native procedure 'Run1' can only be declared in the system object ID range within the platform symbols app.
// @expect AL0895 | The native procedure 'Run1' can only be declared in the system object ID range within the platform symbols app.
// @from 28
// @appjson {"runtime": "17.0"}
// The Native attribute needs runtime 17.0; at that runtime a procedure with a body outside the platform symbols app is rejected (once for the object, once for the attribute).
codeunit 59130 "MNC Native17 0994"
{
    [Native]
    procedure Run1()
    begin
    end;
}
