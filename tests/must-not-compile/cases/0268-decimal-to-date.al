// @expect AL0122 | Cannot implicitly convert type 'Decimal' to 'Date'. Use an explicit conversion or change the type.
// A Decimal is assigned to a Date.
codeunit 50079 "MNC C268"
{
    procedure Run1()
    var
        D: Date;
        M: Decimal;
    begin
        D := M;
    end;
}
