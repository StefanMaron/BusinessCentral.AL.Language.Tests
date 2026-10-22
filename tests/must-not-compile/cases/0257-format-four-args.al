// @expect AL0126 | No overload for method 'Format' takes 4 arguments. Candidates: built-in method 'Format(Joker, [Integer], [Integer])', built-in method 'Format(Joker, Integer, Text)'
// Format is called with four arguments.
codeunit 50065 "MNC C257"
{
    procedure Run1()
    var
        T: Text;
    begin
        T := Format(1, 2, 3, 4);
    end;
}
