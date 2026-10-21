// @expect AL0122 | Cannot implicitly convert type 'Variant' to 'Enum "MNC E1993"'. Use an explicit conversion or change the type.
// Writer QO: a Variant assigned to an Enum field of a record (0263 is the Enum variable; FieldRef.Value of the Enum field takes it:
// tests/al-language/types/lt-bigint-enum-option/BigIntToEnumOption.al QO_Variant_ToEnumFieldRef_Value).
enum 51993 "MNC E1993"
{
    value(0; A) { }
}

table 51993 "MNC T1993"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; E; Enum "MNC E1993") { }
    }
}

codeunit 51993 "MNC C1993"
{
    procedure Run1()
    var
        R: Record "MNC T1993";
        V: Variant;
    begin
        V := 1;
        R.E := V;
    end;
}
