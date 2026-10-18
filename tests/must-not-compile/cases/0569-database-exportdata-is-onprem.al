// @expect AL0296 | The application object or method 'ExportData' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// Database.ExportData named from a Cloud app (the method has scope OnPrem).
codeunit 50569 "MNC O 0569"
{
    procedure Probe()
    var FileName: Text;
    begin
        Database.ExportData(false, FileName);
    end;
}
