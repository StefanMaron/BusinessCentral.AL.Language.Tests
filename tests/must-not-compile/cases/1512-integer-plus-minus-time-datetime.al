// @expect AL0175 | Operator '+' cannot be applied to operands of type 'Integer' and 'Time'
// @expect AL0175 | Operator '-' cannot be applied to operands of type 'Integer' and 'Time'
// @expect AL0175 | Operator '+' cannot be applied to operands of type 'Integer' and 'DateTime'
// @expect AL0175 | Operator '-' cannot be applied to operands of type 'Integer' and 'DateTime'
// An Integer on the LEFT of + and - with a Time or a DateTime on the right; Time + Integer and DateTime + Integer compile
// (types/TestDateTimeIntegerCalcDateContracts.al). Corpus issue 672 item 6 (AL issue 417).
codeunit 50512 "MNC C1512"
{
    procedure Run1()
    var
        I: Integer;
        T: Time;
        DT: DateTime;
        RT: Time;
        RDT: DateTime;
    begin
        RT := I + T;
        RT := I - T;
        RDT := I + DT;
        RDT := I - DT;
    end;
}
