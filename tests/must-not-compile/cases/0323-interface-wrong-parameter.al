// @expect AL0582 | 'MNC C323' does not implement the interface member 'MNC I323.Calc'.
// An implementation has another parameter type than the interface.
interface "MNC I323"
{
    procedure Calc(A: Integer): Integer;
}

codeunit 50140 "MNC C323" implements "MNC I323"
{
    procedure Calc(A: Text): Integer
    begin
    end;
}
