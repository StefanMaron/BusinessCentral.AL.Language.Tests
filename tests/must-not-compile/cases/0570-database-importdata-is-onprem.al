// @expect AL0296 | The application object or method 'ImportData' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// Database.ImportData named from a Cloud app (the method has scope OnPrem).
codeunit 50570 "MNC O 0570"
{
    procedure Probe()
    var FileName: Text;
    begin
        Database.ImportData(false, FileName);
    end;
}
