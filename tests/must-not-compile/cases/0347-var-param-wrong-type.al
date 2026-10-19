// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'var Integer'
// A Text variable is passed for an Integer var parameter.
codeunit 50165 "MNC C347"
{
    local procedure Take(var A: Integer)
    begin
    end;

    procedure Run1()
    var
        T: Text;
    begin
        Take(T);
    end;
}
