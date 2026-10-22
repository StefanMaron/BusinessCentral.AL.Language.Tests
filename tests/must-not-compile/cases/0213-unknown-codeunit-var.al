// @expect AL0185 | Codeunit 'MNC No Such Codeunit' is missing
// A codeunit variable names a codeunit that does not exist.
codeunit 50018 "MNC C213"
{
    procedure Run1()
    var
        C: Codeunit "MNC No Such Codeunit";
    begin
    end;
}
