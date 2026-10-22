// @expect AL0132 | 'Boolean' does not contain a definition for 'Invert'
// Boolean has no Invert method.
codeunit 50039 "MNC C233"
{
    procedure Run1()
    var
        B: Boolean;
    begin
        B.Invert();
    end;
}
