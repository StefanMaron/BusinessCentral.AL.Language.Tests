// @expect AL0122 | Cannot implicitly convert type 'Decimal' to 'Enum "MNC E415 A"'. Use an explicit conversion or change the type.
// A Decimal is assigned to an enum field of a table.
enum 50151 "MNC E415 A"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50152 "MNC E415 B"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

enum 50153 "MNC E415 C"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

table 50154 "MNC T415"
{
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Kind; Enum "MNC E415 A") { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 50150 "MNC C415"
{
    procedure Run1()
    var
        Dc: Decimal;
        R: Record "MNC T415";
    begin
        R.Kind := Dc;
    end;
}
