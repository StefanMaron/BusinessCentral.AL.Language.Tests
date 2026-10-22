// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'String' of 'StrLen(Text)'
// StrLen is called without arguments.
codeunit 50044 "MNC C238"
{
    procedure Run1()
    var
        N: Integer;
    begin
        N := StrLen();
    end;
}
