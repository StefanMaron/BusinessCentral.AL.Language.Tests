// @expect AL0175 | Operator '=' cannot be applied to operands of type 'Variant' and 'Enum "MNC Variant Kind"'
// @expect AL0175 | Operator '<>' cannot be applied to operands of type 'Variant' and 'Enum "MNC Variant Kind"'
// @expect AL0175 | Operator '=' cannot be applied to operands of type 'Variant' and 'Integer'
// @expect AL0175 | Operator '=' cannot be applied to operands of type 'Enum "MNC Variant Kind"' and 'Variant'
// @expect AL0175 | Operator '=' cannot be applied to operands of type 'Variant' and 'Variant'
// A Variant cannot be an operand of = or <>, whatever the other side is: an enum member, an integer, an enum variable, another Variant (issue 580 item 6).
// A case statement over a Variant does compile: tests/al-language/types/lt-variant-unassigned/VariantUnassignedEnum.al.
enum 50996 "MNC Variant Kind"
{
    value(0; Zero) { }
    value(1; One) { }
}

codeunit 50996 "MNC Variant Compare"
{
    procedure Probe()
    var
        V: Variant;
        W: Variant;
        Kind: Enum "MNC Variant Kind";
    begin
        if V = Kind::One then;
        if V <> Kind::One then;
        if V = 0 then;
        if Kind = V then;
        if V = W then;
    end;
}
