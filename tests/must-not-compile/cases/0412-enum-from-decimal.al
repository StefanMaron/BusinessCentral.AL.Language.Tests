// @expect AL0122 | Cannot implicitly convert type 'Decimal' to 'Enum "MNC E412 A"'. Use an explicit conversion or change the type.
// A Decimal variable is assigned to an enum.
enum 50121 "MNC E412 A"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50122 "MNC E412 B"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50123 "MNC E412 C"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

codeunit 50120 "MNC C412"
{
    procedure Run1()
    var
        Dc: Decimal;
        T: Enum "MNC E412 A";
    begin
        T := Dc;
    end;
}
