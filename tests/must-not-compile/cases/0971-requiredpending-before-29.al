// @expect AL0112 | RequiredPending is not a valid attribute
// @until 28
// The RequiredPending attribute exists from BC 29.
codeunit 59015 "MNC ReqPending 0971"
{
    [RequiredPending('Use the new procedure', '29.0')]
    procedure Run1()
    begin
    end;
}
