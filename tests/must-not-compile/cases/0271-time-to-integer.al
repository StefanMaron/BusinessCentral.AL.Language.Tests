// @expect AL0122 | Cannot implicitly convert type 'Time' to 'Integer'. Use an explicit conversion or change the type.
// A Time is assigned to an Integer.
codeunit 50082 "MNC C271"
{
    procedure Run1()
    var
        I: Integer;
        M: Time;
    begin
        I := M;
    end;
}
