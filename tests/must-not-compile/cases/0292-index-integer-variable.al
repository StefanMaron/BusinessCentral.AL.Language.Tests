// @expect AL0143 | Cannot apply indexing with [] to an expression of type 'Integer'
// An Integer variable is indexed.
codeunit 50105 "MNC C292"
{
    procedure Run1()
    var
        I: Integer;
    begin
        I[1] := 2;
    end;
}
