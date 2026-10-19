// @expect AL0122 | Cannot implicitly convert type 'Variant' to 'Enum "MNC E263"'. Use an explicit conversion or change the type.
// A Variant is assigned to an enum variable.
enum 50071 "MNC E263"
{
    value(0; A) { }
}

codeunit 50072 "MNC C263"
{
    procedure Run1()
    var
        V: Variant;
        E: Enum "MNC E263";
    begin
        E := V;
    end;
}
