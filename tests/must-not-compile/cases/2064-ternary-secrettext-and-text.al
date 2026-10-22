// @expect AL0122 | Cannot implicitly convert type 'Text' to 'SecretText'. Use an explicit conversion or change the type.
// @expect AL0122 | Cannot implicitly convert type 'SecretText' to 'Text'. Use an explicit conversion or change the type.
// @expect AL0122 | Cannot implicitly convert type 'Text' to 'SecretText'. Use an explicit conversion or change the type.
// Writer QW (corpus issue 685): a SecretText and a Text branch do not compile in either order, also when the target is a Text.
// SecretText with SecretText compiles (QW_Ternary_SecretTextPair in tests/al-language/types/TestTernaryContracts.al).
codeunit 52064 "MNC QW Ternary Secret Text"
{
    procedure Run1(Cond: Boolean)
    var
        S: SecretText;
        R: SecretText;
        T: Text;
    begin
        R := Cond ? S : 'abc';
        R := Cond ? 'abc' : S;
        T := Cond ? S : 'abc';
    end;
}
