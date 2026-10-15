// @expect AL0122 | Cannot implicitly convert type 'Boolean' to 'Integer'. Use an explicit conversion or change the type.
// A Boolean is assigned to an Integer.
codeunit 59433 "MNC P79 0433"
{
    procedure Run1()
    var
        B: Boolean;
        I: Integer;
    begin
        I := B;
    end;
}
