// @expect AL0421 | A ‘foreach’ statement can only be used with an expression of an enumerable type.
// A foreach iterates over an Integer.
codeunit 50102 "MNC C289"
{
    procedure Run1()
    var
        I: Integer;
        J: Integer;
    begin
        foreach J in I do;
    end;
}
