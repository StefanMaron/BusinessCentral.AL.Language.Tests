// @expect AL0175 | Operator '-' cannot be applied to operands of type 'Integer' and 'Date'
// An Integer minus a Date. Corpus issue 672 item 6 (AL issue 417).
codeunit 50511 "MNC C1511"
{
    procedure Run1()
    var
        D: Date;
        I: Integer;
        X: Integer;
    begin
        X := I - D;
    end;
}
