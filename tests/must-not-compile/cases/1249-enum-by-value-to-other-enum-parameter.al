// @expect AL0133 | Argument 1: cannot convert from 'Enum "MNC BB Enum A"' to 'Enum "MNC BB Enum B"'
// An enum value of type A passed by value to a parameter of enum type B that lacks AssignmentCompatibility: AL0133 (not AL0122; var is case
// 0404, exit is case 0405). With AssignmentCompatibility = true on B the call compiles: tests/al-language/enum/lt-bb-enum-compat.
enum 50000 "MNC BB Enum A"
{
    value(0; Zero) { }
    value(1; One) { }
}
enum 50001 "MNC BB Enum B"
{
    value(0; Zero) { }
    value(1; One) { }
}
codeunit 50002 "MNC BB Codeunit"
{
    procedure Take(B: Enum "MNC BB Enum B"): Integer
    begin
        exit(B.AsInteger());
    end;

    procedure DoIt(): Integer
    var
        A: Enum "MNC BB Enum A";
    begin
        A := A::One;
        exit(Take(A));
    end;
}
