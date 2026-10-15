// @expect AL0185 | Enum 'MNC No Such Enum' is missing
// An enum variable names an enum that does not exist.
codeunit 50019 "MNC C214"
{
    procedure Run1()
    var
        E: Enum "MNC No Such Enum";
    begin
    end;
}
