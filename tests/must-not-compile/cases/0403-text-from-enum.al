// @expect AL0122 | Cannot implicitly convert type 'Enum "MNC E403 A"' to 'Text'. Use an explicit conversion or change the type.
// A Text variable is assigned an enum value.
enum 50031 "MNC E403 A"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50032 "MNC E403 B"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50033 "MNC E403 C"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

codeunit 50030 "MNC C403"
{
    procedure Run1()
    var
        X: Text;
        T: Enum "MNC E403 A";
    begin
        X := T;
    end;
}
