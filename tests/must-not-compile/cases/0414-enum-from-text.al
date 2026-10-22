// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Enum "MNC E414 A"'. Use an explicit conversion or change the type.
// A Text variable is assigned to an enum.
enum 50141 "MNC E414 A"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50142 "MNC E414 B"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50143 "MNC E414 C"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

codeunit 50140 "MNC C414"
{
    procedure Run1()
    var
        X: Text;
        T: Enum "MNC E414 A";
    begin
        T := X;
    end;
}
