// @expect AL0296 | The application object or method 'Exists' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// File.Exists has scope OnPrem; a Cloud app calls it.
codeunit 50184 "MNC C361"
{
    procedure Run1()
    var
        B: Boolean;
    begin
        B := File.Exists('x.txt');
    end;
}
