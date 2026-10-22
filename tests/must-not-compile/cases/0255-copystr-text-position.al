// @expect AL0133 | Argument 2: cannot convert from 'Text' to 'Integer'
// CopyStr is called with a Text as the position.
codeunit 50062 "MNC C255"
{
    procedure Run1()
    var
        T: Text;
    begin
        T := CopyStr('abc', 'x', 2);
    end;
}
