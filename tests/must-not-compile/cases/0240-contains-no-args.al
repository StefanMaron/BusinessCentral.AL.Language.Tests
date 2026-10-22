// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'Value' of 'Contains(Text)'
// Text.Contains is called without arguments.
codeunit 50046 "MNC C240"
{
    procedure Run1()
    var
        T: Text;
        B: Boolean;
    begin
        B := T.Contains();
    end;
}
