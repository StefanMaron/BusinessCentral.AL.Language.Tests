// @expect AL0122 | Cannot implicitly convert type 'Char' to 'Enum "MNC E267"'. Use an explicit conversion or change the type.
// A Text literal is assigned to an enum variable.
enum 50077 "MNC E267"
{
    value(0; A) { }
}

codeunit 50078 "MNC C267"
{
    procedure Run1()
    var
        E: Enum "MNC E267";
    begin
        E := 'A';
    end;
}
