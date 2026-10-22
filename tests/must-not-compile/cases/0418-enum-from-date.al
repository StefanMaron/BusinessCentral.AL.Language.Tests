// @expect AL0122 | Cannot implicitly convert type 'Date' to 'Enum "MNC E418 A"'. Use an explicit conversion or change the type.
// A Date is assigned to an enum.
enum 50181 "MNC E418 A"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50182 "MNC E418 B"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50183 "MNC E418 C"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

codeunit 50180 "MNC C418"
{
    procedure Run1()
    var
        Dt: Date;
        T: Enum "MNC E418 A";
    begin
        T := Dt;
    end;
}
