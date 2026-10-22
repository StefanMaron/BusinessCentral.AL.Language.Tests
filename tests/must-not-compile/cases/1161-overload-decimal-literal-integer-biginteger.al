// @expect AL0196 | The call is ambiguous between the method 'Pick(Integer)' defined in Codeunit 'MNC AU C1161'
// A Decimal literal (1.5) passed to a procedure whose only overloads take Integer and BigInteger (corpus issue 645 item 16).
codeunit 51161 "MNC AU C1161"
{
    local procedure Pick(I: Integer): Text
    begin
        exit('Integer');
    end;

    local procedure Pick(B: BigInteger): Text
    begin
        exit('BigInteger');
    end;

    procedure Probe(): Text
    begin
        exit(Pick(1.5));
    end;
}
