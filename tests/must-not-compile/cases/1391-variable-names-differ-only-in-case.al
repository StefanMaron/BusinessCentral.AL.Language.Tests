// @expect AL0121 | The variable name 'SMITH' is already defined.
// Two local variables whose names differ only in letter case (Smith and SMITH): names are case-insensitive.
codeunit 51391 "MNC BN C1391"
{
    procedure Run1()
    var
        Smith: Integer;
        SMITH: Integer;
    begin
    end;
}
