// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Char'. Use an explicit conversion or change the type.
// `Txt := Cond ? '1' : ''`: the one-character literal makes the true branch a Char, and the empty literal (Text) cannot convert to Char
// (microsoft/AL issues 7937, 7926). `Cond ? '' : '1'`, `Cond ? '1' : ' '` and `Cond ? '1' : '0'` compile (tests/al-language/types/TestTernaryContracts.al).
codeunit 51405 "MNC BN C1405"
{
    procedure Run1(Cond: Boolean): Text
    var
        Txt: Text;
    begin
        Txt := Cond ? '1' : '';
        exit(Txt);
    end;
}
