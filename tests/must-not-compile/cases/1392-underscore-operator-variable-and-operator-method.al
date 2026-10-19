// @expect AL0757 | The metadata name of Method 'Operator' conflicts with GlobalVariable '_operator' defined in Codeunit 'MNC BN C1392'
// @expect AL0757 | The metadata name of GlobalVariable '_operator' conflicts with Method 'Operator' defined in Codeunit 'MNC BN C1392'
// A global variable _operator and a procedure Operator in one codeunit (microsoft/AL issue 8127): both declarations get AL0757.
codeunit 51392 "MNC BN C1392"
{
    var
        _operator: Integer;

    procedure Operator(): Integer
    begin
        exit(_operator);
    end;
}
