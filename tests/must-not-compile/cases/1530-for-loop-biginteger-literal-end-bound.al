// @expect AL0369 | Constant value '100000000000000' cannot be converted to a 'Integer'.
// A for loop over an Integer control variable whose end bound is a BigInteger literal above the Integer range
// (corpus issue 672, item 36). With a BigInteger variable as the end bound the loop compiles (see
// tests/al-language/misc/lt-system-functions/ControlFlow.al, LT_BU_ForLoop_BigIntegerEndBoundOnInteger).
codeunit 51530 "MNC BU 1530"
{
    procedure Run1()
    var
        Count: Integer;
    begin
        for Count := 1000 to 100000000000000L do;
    end;
}
