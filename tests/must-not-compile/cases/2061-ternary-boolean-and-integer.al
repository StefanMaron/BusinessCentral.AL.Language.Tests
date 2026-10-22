// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Boolean'. Use an explicit conversion or change the type.
// @expect AL0122 | Cannot implicitly convert type 'Boolean' to 'Integer'. Use an explicit conversion or change the type.
// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Boolean'. Use an explicit conversion or change the type.
// Writer QW (corpus issue 685): a conditional expression with a Boolean and an Integer branch does not compile in either order, also when
// the target is a Variant. The true branch sets the type of the expression (tests/al-language/types/TestTernaryContracts.al).
codeunit 52061 "MNC QW Ternary Bool Int"
{
    procedure Run1(Cond: Boolean)
    var
        B: Boolean;
        I: Integer;
        V: Variant;
    begin
        B := Cond ? true : 1;
        I := Cond ? 1 : true;
        V := Cond ? true : 1;
    end;
}
