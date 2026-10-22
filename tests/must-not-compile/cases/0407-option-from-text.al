// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Option'. Use an explicit conversion or change the type.
// An Option variable is assigned a Text.
enum 50071 "MNC E407 A"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50072 "MNC E407 B"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50073 "MNC E407 C"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

codeunit 50070 "MNC C407"
{
    procedure Run1()
    var
        X: Text;
        O: Option A,B,C;
    begin
        O := X;
    end;
}
