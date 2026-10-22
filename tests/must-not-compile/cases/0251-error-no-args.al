// @expect AL0126 | No overload for method 'Error' takes 0 arguments. Candidates: built-in method 'Error(Text, [Joker])', built-in method 'Error(ErrorInfo)'
// Error is called without arguments.
codeunit 50057 "MNC C251"
{
    procedure Run1()
    begin
        Error();
    end;
}
