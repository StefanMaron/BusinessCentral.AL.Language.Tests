// @expect AL0296 | The application object or method 'Erase' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// File.Erase has scope OnPrem; a Cloud app calls it.
codeunit 50185 "MNC C362"
{
    procedure Run1()
    begin
        File.Erase('x.txt');
    end;
}
