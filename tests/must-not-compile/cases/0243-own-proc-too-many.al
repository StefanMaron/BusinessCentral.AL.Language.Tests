// @expect AL0126 | No overload for method 'Take' takes 2 arguments. Candidates: 'Take(Integer)' defined in Codeunit 'MNC C243' by the extension Must Not Compile by AL Language (1.0.0.0)
// An own procedure is called with too many arguments.
codeunit 50049 "MNC C243"
{
    local procedure Take(A: Integer)
    begin
    end;

    procedure Run1()
    begin
        Take(1, 2);
    end;
}
