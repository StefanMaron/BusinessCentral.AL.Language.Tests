// @expect AL0126 | No overload for method 'CopyStr' takes 4 arguments. Candidates: built-in method 'CopyStr(Text, Integer, [Integer])'
// CopyStr is called with four arguments.
codeunit 50047 "MNC C241"
{
    procedure Run1()
    var
        T: Text;
    begin
        T := CopyStr('abc', 1, 2, 3);
    end;
}
