// @expect AL0413 | Procedure 'Calc' cannot have a body.
// An interface member has a body.
interface "MNC I325"
{
    procedure Calc(A: Integer): Integer
    begin
    end;
}
