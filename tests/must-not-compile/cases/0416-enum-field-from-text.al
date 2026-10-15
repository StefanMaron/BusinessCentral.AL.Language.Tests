// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Enum "MNC E416 A"'. Use an explicit conversion or change the type.
// A Text is assigned to an enum field of a table.
enum 50161 "MNC E416 A"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50162 "MNC E416 B"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50163 "MNC E416 C"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

table 50164 "MNC T416"
{
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Kind; Enum "MNC E416 A") { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 50160 "MNC C416"
{
    procedure Run1()
    var
        X: Text;
        R: Record "MNC T416";
    begin
        R.Kind := X;
    end;
}
