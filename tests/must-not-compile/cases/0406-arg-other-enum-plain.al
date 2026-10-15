// @expect AL0133 | Argument 1: cannot convert from 'Enum "MNC E406 A"' to 'Enum "MNC E406 B"'
// An enum of another type is passed by value to a parameter of an enum without AssignmentCompatibility.
enum 50061 "MNC E406 A"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50062 "MNC E406 B"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50063 "MNC E406 C"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

codeunit 50060 "MNC C406"
{
    local procedure Take1(X: Enum "MNC E406 B")
    begin
    end;

    procedure Run1()
    var
        S: Enum "MNC E406 A";
    begin
        Take1(S);
    end;
}
