// @expect AL0122 | Cannot implicitly convert type 'Boolean' to 'Code[10]'. Use an explicit conversion or change the type.
// A Boolean does not assign to a Code variable (issue 649 item 5).
codeunit 51191 "MNC AX Boolean To Code"
{
    procedure Probe(): Code[10]
    var
        B: Boolean;
        C: Code[10];
    begin
        B := true;
        C := B;
        exit(C);
    end;
}
