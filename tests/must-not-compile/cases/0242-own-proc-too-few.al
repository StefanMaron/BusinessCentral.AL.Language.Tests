// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'B' of 'Take(Integer, Integer)'
// An own procedure is called with too few arguments.
codeunit 50048 "MNC C242"
{
    local procedure Take(A: Integer; B: Integer)
    begin
    end;

    procedure Run1()
    begin
        Take(1);
    end;
}
