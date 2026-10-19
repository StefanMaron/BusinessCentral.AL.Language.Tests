// @expect AL0122 | Cannot implicitly convert type 'Char' to 'Enum "MNC E419 A"'. Use an explicit conversion or change the type.
// A Char is assigned to an enum.
enum 50191 "MNC E419 A"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50192 "MNC E419 B"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50193 "MNC E419 C"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

codeunit 50190 "MNC C419"
{
    procedure Run1()
    var
        Ch: Char;
        T: Enum "MNC E419 A";
    begin
        T := Ch;
    end;
}
