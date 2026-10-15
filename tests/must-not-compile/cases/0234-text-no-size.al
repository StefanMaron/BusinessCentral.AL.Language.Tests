// @expect AL0132 | 'Text' does not contain a definition for 'Size'
// Text has no Size method.
codeunit 50040 "MNC C234"
{
    procedure Run1()
    var
        T: Text;
        N: Integer;
    begin
        N := T.Size();
    end;
}
