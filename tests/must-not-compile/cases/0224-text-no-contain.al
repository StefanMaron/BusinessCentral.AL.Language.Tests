// @expect AL0132 | 'Text' does not contain a definition for 'Contain'
// Text has no method named Contain (Contains is the method).
codeunit 50029 "MNC C224"
{
    procedure Run1()
    var
        T: Text;
        B: Boolean;
    begin
        B := T.Contain('x');
    end;
}
