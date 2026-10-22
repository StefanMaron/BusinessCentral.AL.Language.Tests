// @expect AL0122 | Cannot implicitly convert type 'None' to 'Integer'. Use an explicit conversion or change the type.
// The result of a procedure without a return value is assigned.
codeunit 50086 "MNC C275"
{
    local procedure Nothing()
    begin
    end;

    procedure Run1()
    var
        I: Integer;
    begin
        I := Nothing();
    end;
}
