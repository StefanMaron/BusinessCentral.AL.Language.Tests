// @expect AL0172 | Operator '-' is ambiguous on an operand of type 'Option'
// Unary minus on an Option variable, assigned to an Option (corpus issue 672, item 42).
codeunit 51531 "MNC BU 1531"
{
    procedure Run1()
    var
        Alignment: Option Left,Center,Right;
        Other: Option Left,Center,Right;
    begin
        Other := -Alignment;
    end;
}
