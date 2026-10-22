// @until 27
// @expect AL0757 | The metadata name of GlobalVariable '_operator' conflicts with Method 'Operator' defined in Codeunit 'MNC BN C1408'
// A global variable _operator and a procedure Operator in one codeunit (microsoft/AL issue 8127) on BC 27 (runtime 16.1): the variable gets
// error AL0757 and the procedure only warning AL0758 ("The metadata name of Method 'Operator' conflicts with GlobalVariable '_operator' ...").
// From BC 28 both declarations get AL0757: case 1392.
codeunit 51408 "MNC BN C1408"
{
    var
        _operator: Integer;

    procedure Operator(): Integer
    begin
        exit(_operator);
    end;
}
