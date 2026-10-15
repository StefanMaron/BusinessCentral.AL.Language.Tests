// @expect AL0582 | 'MNC C322' does not implement the interface member 'MNC I322.Calc'.
// An implementation has another return type than the interface.
interface "MNC I322"
{
    procedure Calc(A: Integer): Integer;
}

codeunit 50139 "MNC C322" implements "MNC I322"
{
    procedure Calc(A: Integer): Text
    begin
    end;
}
