// @expect AL0185 | Table 'MNC Missing Table' is missing
// A Record variable names a table that does not exist.
codeunit 50003 "MNC C202"
{
    procedure Run1()
    var
        R: Record "MNC Missing Table";
    begin
    end;
}
