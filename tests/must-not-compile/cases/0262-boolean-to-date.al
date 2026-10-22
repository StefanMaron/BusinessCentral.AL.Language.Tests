// @expect AL0122 | Cannot implicitly convert type 'Boolean' to 'Date'. Use an explicit conversion or change the type.
// A Boolean is assigned to a Date.
codeunit 50070 "MNC C262"
{
    procedure Run1()
    var
        B: Boolean;
        D: Date;
    begin
        D := B;
    end;
}
