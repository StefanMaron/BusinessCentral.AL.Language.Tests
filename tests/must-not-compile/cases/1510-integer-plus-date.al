// @expect AL0175 | Operator '+' cannot be applied to operands of type 'Integer' and 'Date'
// @expect AL0175 | Operator '+' cannot be applied to operands of type 'Integer' and 'Date'
// @expect AL0175 | Operator '+' cannot be applied to operands of type 'Integer' and 'Date'
// An Integer on the LEFT of + with a Date on the right (a variable, Today() and a date literal); Date + Integer compiles
// (types/lt-expression-operators-literals/ExpressionBinaryRisky.al). Corpus issue 672 item 6 (AL issue 417).
codeunit 50510 "MNC C1510"
{
    procedure Run1()
    var
        D: Date;
        I: Integer;
        R: Date;
    begin
        I := 3;
        R := I + D;
        R := 1 + Today();
        R := 1 + 20240105D;
    end;
}
