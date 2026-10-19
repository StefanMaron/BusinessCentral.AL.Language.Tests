// @expect AL0196 | The call is ambiguous between the method 'Pick(Integer)' defined in Codeunit 'MNC AU C1160'
// A Decimal variable passed to a procedure whose only overloads take Integer and BigInteger (corpus issue 645 item 16).
codeunit 51160 "MNC AU C1160"
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
    var
        D: Decimal;
    begin
        D := 2;
        exit(Pick(D));
    end;
}
