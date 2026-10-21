// @expect AL0193 | Argument 2: cannot convert from 'Variant' to the type of Argument 1 'Enum "MNC E1992"'
// Writer QO: Validate of an Enum field with a Variant (an Option field takes it: tests/al-language/types/lt-bigint-enum-option/BigIntToEnumOption.al
// QO_Variant_ToOptionField_Validate; FieldRef.Validate of the Enum field takes it too: QO_Variant_ToEnumFieldRef_Validate).
enum 51992 "MNC E1992"
{
    value(0; A) { }
}

table 51992 "MNC T1992"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; E; Enum "MNC E1992") { }
    }
}

codeunit 51992 "MNC C1992"
{
    procedure Run1()
    var
        R: Record "MNC T1992";
        V: Variant;
    begin
        V := 1;
        R.Validate(E, V);
    end;
}
