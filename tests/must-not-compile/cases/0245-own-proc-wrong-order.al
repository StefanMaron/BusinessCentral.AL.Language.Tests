// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Integer'
// @expect AL0133 | Argument 2: cannot convert from 'Integer' to 'Text'
// An own procedure (Integer, Text) is called with the arguments swapped.
codeunit 50051 "MNC C245"
{
    local procedure Take(A: Integer; B: Text)
    begin
    end;

    procedure Run1()
    begin
        Take('abc', 1);
    end;
}
