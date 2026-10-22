// @expect AL0581 | The length for the type 'Code' must be positive
// A Code[0] variable (corpus issue 672, item 43; the Text form is case 0340).
codeunit 51537 "MNC BU 1537"
{
    procedure Run1()
    var
        C: Code[0];
    begin
        C := '';
    end;
}
