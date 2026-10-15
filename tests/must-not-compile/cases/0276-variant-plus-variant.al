// @expect AL0175 | Operator '+' cannot be applied to operands of type 'Variant' and 'Variant'
// Two Variants are added.
codeunit 50087 "MNC C276"
{
    procedure Run1()
    var
        A: Variant;
        B: Variant;
        C: Variant;
    begin
        C := A + B;
    end;
}
