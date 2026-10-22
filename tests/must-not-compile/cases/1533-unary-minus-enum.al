// @expect AL0172 | Operator '-' is ambiguous on an operand of type 'Enum "MNC BU E1533"'
// Unary minus on an Enum variable (corpus issue 672, item 42).
enum 51533 "MNC BU E1533"
{
    value(0; A) { }
    value(1; B) { }
}

codeunit 51534 "MNC BU 1533"
{
    procedure Run1()
    var
        E: Enum "MNC BU E1533";
        I: Integer;
    begin
        I := -E;
    end;
}
