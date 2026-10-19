// @expect AL0122 | Cannot implicitly convert type 'Codeunit "MNC C324"' to 'Interface "MNC I324"'. Use an explicit conversion or change the type.
// A codeunit that does not implement the interface is assigned to it.
interface "MNC I324"
{
    procedure Calc(A: Integer): Integer;
}

codeunit 50141 "MNC C324"
{
}

codeunit 50142 "MNC D324"
{
    procedure Run1()
    var
        I: Interface "MNC I324";
        C: Codeunit "MNC C324";
    begin
        I := C;
    end;
}
