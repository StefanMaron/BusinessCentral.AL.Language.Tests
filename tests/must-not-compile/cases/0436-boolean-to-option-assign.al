// @expect AL0122 | Cannot implicitly convert type 'Boolean' to 'Option'. Use an explicit conversion or change the type.
// A Boolean is assigned to an Option.
codeunit 59436 "MNC P79 0436"
{
    procedure Run1()
    var
        B: Boolean;
        O: Option A,B,C;
    begin
        O := B;
    end;
}
