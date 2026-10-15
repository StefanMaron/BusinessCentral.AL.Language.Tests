// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'NewValue' of 'Replace(Text, Text)'
// Text.Replace is called with one argument.
codeunit 50061 "MNC C254"
{
    procedure Run1()
    var
        T: Text;
    begin
        T := T.Replace('a');
    end;
}
