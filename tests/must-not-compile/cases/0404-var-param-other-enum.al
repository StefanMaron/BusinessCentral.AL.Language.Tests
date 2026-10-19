// @expect AL0133 | Argument 1: cannot convert from 'Enum "MNC E404 A"' to 'var Enum "MNC E404 B"'
// An enum of another type is passed to a var parameter.
enum 50041 "MNC E404 A"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50042 "MNC E404 B"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50043 "MNC E404 C"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

codeunit 50040 "MNC C404"
{
    local procedure Take2(var X: Enum "MNC E404 B")
    begin
    end;

    procedure Run1()
    var
        S: Enum "MNC E404 A";
        D: Enum "MNC E404 A";
    begin
        Take2(S);
    end;
}
