// @expect AL0172 | Operator '-' is ambiguous on an operand of type 'Option'
// Unary minus on an Option variable does not compile (corpus issue 672, item 42). `-1 * Option` compiles and gives the negated ordinal
// (tests/al-language/misc/lt-cq-odd-leads/CqOddLeads.al Item42).
codeunit 51728 "MNC CQ C1728"
{
    procedure Negate()
    var
        Alignment: Option Left,Center,Right;
        Other: Option Left,Center,Right;
    begin
        Alignment := Alignment::Center;
        Other := -Alignment;
    end;
}
