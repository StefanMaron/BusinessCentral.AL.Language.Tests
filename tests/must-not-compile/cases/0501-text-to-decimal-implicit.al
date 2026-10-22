// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Decimal'
// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Decimal'
// A Text literal and a Text variable cannot be assigned to a Decimal without Evaluate (issue 580 item 5). A Variant that holds a Text can
// (tests/al-language/types/lt-evaluate-decimal/EvaluateDecimal.al).
codeunit 50995 "MNC Text To Decimal"
{
    procedure Probe()
    var
        D: Decimal;
        T: Text;
    begin
        D := '100';
        D := T;
    end;
}
