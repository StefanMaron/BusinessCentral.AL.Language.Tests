// @expect AL0777 | The implicit conversion will overflow when converting from a 'Guid' to a 'Text' which is shorter than the converted textual representation of a 'Guid'.
// Writer QW (corpus issue 685): `Cond ? 'abc' : G` with a Guid false branch. The literal true branch sets the type (a Text as long as the
// literal), and a Guid does not fit. The reverse order `Cond ? G : 'abc'` compiles (QW_Ternary_BooleanGuidTimePairs in
// tests/al-language/types/TestTernaryContracts.al).
codeunit 52062 "MNC QW Ternary Text Guid"
{
    procedure Run1(Cond: Boolean): Text
    var
        G: Guid;
        R: Text;
    begin
        R := Cond ? 'abc' : G;
        exit(R);
    end;
}
