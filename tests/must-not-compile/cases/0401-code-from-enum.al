// @expect AL0122 | Cannot implicitly convert type 'Enum "MNC E401 A"' to 'Code[20]'. Use an explicit conversion or change the type.
// A Code variable is assigned an enum value.
enum 50011 "MNC E401 A"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50012 "MNC E401 B"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50013 "MNC E401 C"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

codeunit 50010 "MNC C401"
{
    procedure Run1()
    var
        C: Code[20];
        T: Enum "MNC E401 A";
    begin
        C := T;
    end;
}
