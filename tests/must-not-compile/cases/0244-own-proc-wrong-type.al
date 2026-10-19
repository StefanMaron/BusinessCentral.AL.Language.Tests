// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Integer'
// An own procedure expecting an Integer is called with a Text literal.
codeunit 50050 "MNC C244"
{
    local procedure Take(A: Integer)
    begin
    end;

    procedure Run1()
    begin
        Take('abc');
    end;
}
