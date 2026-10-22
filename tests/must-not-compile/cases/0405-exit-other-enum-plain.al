// @expect AL0122 | Cannot implicitly convert type 'Enum "MNC E405 A"' to 'Enum "MNC E405 B"'. Use an explicit conversion or change the type.
// exit returns an enum of another type from a procedure whose enum lacks AssignmentCompatibility.
enum 50051 "MNC E405 A"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50052 "MNC E405 B"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50053 "MNC E405 C"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

codeunit 50050 "MNC C405"
{
    procedure Run1(): Enum "MNC E405 B"
    var
        S: Enum "MNC E405 A";
    begin
        exit(S);
    end;
}
