// @expect AL0398 | Constant value '0.0' is outside of the valid ordinal range for this Option type
// @expect AL0398 | Constant value '1.5' is outside of the valid ordinal range for this Option type
// An Option tested with `in` against a list of Decimal constants (writer QS). `O = 1.5` compiles; a Decimal constant in the list
// of an `in` on an Option does not.
codeunit 50000 "MNC Option In Decimals"
{
    procedure Probe(): Boolean
    var
        O: Option None,Quantity,Amount;
    begin
        exit(O in [0.0, 1.5]);
    end;
}
