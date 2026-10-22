// @expect AL0296 | The application object or method 'DataFileInformation' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// Database.DataFileInformation named from a Cloud app (the method has scope OnPrem).
codeunit 51312 "MNC BG 1312"
{
    procedure Probe()
    var
        Company: Record Company;
        FileName: Text;
        Description: Text;
        HasApp: Boolean;
        HasAppData: Boolean;
        HasGlobal: Boolean;
        TenantId: Text;
        ExportDate: DateTime;
    begin
        Database.DataFileInformation(false, FileName, Description, HasApp, HasAppData, HasGlobal, TenantId, ExportDate, Company);
    end;
}
