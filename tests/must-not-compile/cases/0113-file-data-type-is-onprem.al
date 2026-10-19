// @expect AL0296 | The application object or method 'Open' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// A variable of the File data type in a Cloud app.
codeunit 50120 "MNC File Variable"
{
    procedure Describe(): Boolean
    var
        F: File;
    begin
        exit(F.Open('x.txt'));
    end;
}
