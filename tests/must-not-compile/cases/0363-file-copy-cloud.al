// @expect AL0296 | The application object or method 'Copy' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// File.Copy has scope OnPrem; a Cloud app calls it.
codeunit 50186 "MNC C363"
{
    procedure Run1()
    begin
        File.Copy('a.txt', 'b.txt');
    end;
}
