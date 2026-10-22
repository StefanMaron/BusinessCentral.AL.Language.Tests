// @expect AL0122 | Cannot implicitly convert type 'DateTime' to 'Date'. Use an explicit conversion or change the type.
// A DateTime is assigned to a Date.
codeunit 50080 "MNC C269"
{
    procedure Run1()
    var
        D: Date;
        M: DateTime;
    begin
        D := M;
    end;
}
