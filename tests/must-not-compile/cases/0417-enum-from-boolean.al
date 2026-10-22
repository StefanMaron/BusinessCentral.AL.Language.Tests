// @expect AL0122 | Cannot implicitly convert type 'Boolean' to 'Enum "MNC E417 A"'. Use an explicit conversion or change the type.
// A Boolean is assigned to an enum.
enum 50171 "MNC E417 A"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50172 "MNC E417 B"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50173 "MNC E417 C"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

codeunit 50170 "MNC C417"
{
    procedure Run1()
    var
        Bo: Boolean;
        T: Enum "MNC E417 A";
    begin
        T := Bo;
    end;
}
