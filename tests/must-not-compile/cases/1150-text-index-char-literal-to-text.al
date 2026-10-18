// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Text'
// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Text'
// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Text'
// A character taken from a Text by index, plus or minus a one-character literal, is an Integer (issue 655 item 2; the values are in
// tests/al-language/types/lt-at-partner-gaps/AtTextCharLiteral.al). So it does not assign to a Text variable, in either order of the operands.
codeunit 50000 "MNC AT Text Index Char To Text"
{
    procedure Probe(): Text
    var
        S: Text;
        T: Text;
    begin
        S := '7B';
        T := S[2] + 'A';
        T := 'A' + S[1];
        T := S[1] - '0';
        exit(T);
    end;
}
