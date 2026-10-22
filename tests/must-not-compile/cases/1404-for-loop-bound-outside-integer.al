// @expect AL0103 | Constant value '100000000000000' is outside the range for an Integer
// `for Count := 1 to 100000000000000` with an Integer control variable: the literal bound is converted to the type of the control variable at
// compile time (Learn: the bounds are converted to the control variable's type). The same check on an assignment is case 0341.
codeunit 51404 "MNC BN C1404"
{
    procedure Run1()
    var
        Count: Integer;
    begin
        for Count := 1 to 100000000000000 do;
    end;
}
