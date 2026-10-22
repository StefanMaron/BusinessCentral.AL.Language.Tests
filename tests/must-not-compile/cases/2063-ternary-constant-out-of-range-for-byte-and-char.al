// @expect AL0369 | Constant value '300' cannot be converted to a 'Byte'.
// @expect AL0369 | Constant value '70000' cannot be converted to a 'Char'.
// Writer QW (corpus issue 685): a Byte or Char true branch sets the type, so an Integer constant out of its range in the false branch does
// not compile, even when the target is an Integer. `Cond ? 300 : B` (Integer true branch) compiles (QW_Ternary_DurationBytePairs in
// tests/al-language/types/TestTernaryContracts.al).
codeunit 52063 "MNC QW Ternary Byte Const"
{
    procedure Run1(Cond: Boolean)
    var
        B: Byte;
        C: Char;
        I: Integer;
    begin
        I := Cond ? B : 300;
        I := Cond ? C : 70000;
    end;
}
