// @expect AL0122 | Cannot implicitly convert type 'Code[20]' to 'Enum "MNC E413 A"'. Use an explicit conversion or change the type.
// A Code variable is assigned to an enum.
enum 50131 "MNC E413 A"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50132 "MNC E413 B"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50133 "MNC E413 C"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

codeunit 50130 "MNC C413"
{
    procedure Run1()
    var
        C: Code[20];
        T: Enum "MNC E413 A";
    begin
        T := C;
    end;
}
