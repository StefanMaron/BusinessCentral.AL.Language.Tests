// @expect AL0126 | No overload for method 'StrLen' takes 2 arguments. Candidates: built-in method 'StrLen(Text)'
// StrLen is called with two arguments.
codeunit 50045 "MNC C239"
{
    procedure Run1()
    var
        N: Integer;
    begin
        N := StrLen('a', 'b');
    end;
}
