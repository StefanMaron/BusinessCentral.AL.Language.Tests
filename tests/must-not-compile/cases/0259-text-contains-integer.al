// @expect AL0133 | Argument 1: cannot convert from 'Integer' to 'Text'
// Text.Contains is called with an Integer.
codeunit 50067 "MNC C259"
{
    procedure Run1()
    var
        T: Text;
        B: Boolean;
    begin
        B := T.Contains(5);
    end;
}
