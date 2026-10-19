// @expect AL0172 | Operator '-' is ambiguous on an operand of type 'Enum "MNC CQ E1729"'
// Unary minus on an Enum variable does not compile (corpus issue 672, item 42).
enum 51729 "MNC CQ E1729"
{
    Extensible = false;
    value(0; A) { }
    value(1; B) { }
}
codeunit 51729 "MNC CQ C1729"
{
    procedure Negate()
    var
        E: Enum "MNC CQ E1729";
        I: Integer;
    begin
        E := E::B;
        I := -E;
    end;
}
