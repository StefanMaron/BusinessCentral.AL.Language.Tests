// @expect AL0757 | The metadata name of Method 'Operator' conflicts with GlobalVariable '_operator' defined in Codeunit 'MNC BN C1392'
// @expect AL0757 | The metadata name of GlobalVariable '_operator' conflicts with Method 'Operator' defined in Codeunit 'MNC BN C1392'
// @from 28
// A global variable _operator and a procedure Operator in one codeunit (microsoft/AL issue 8127): from BC 28 (runtime 17.1) both declarations
// get AL0757. On BC 27 (runtime 16.1) the procedure gets warning AL0758 and only the variable gets AL0757: case 1408.
codeunit 51392 "MNC BN C1392"
{
    var
        _operator: Integer;

    procedure Operator(): Integer
    begin
        exit(_operator);
    end;
}
