// @expect AL0296 | The application object or method 'ExportFile' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// MediaSet.ExportFile from a Cloud app.
table 50645 "MNC MediaSet ExportFile Row"
{
    fields { field(1; Code; Code[20]) { } field(2; Pic; MediaSet) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 50645 "MNC MediaSet ExportFile"
{
    procedure Do()
    var
        Row: Record "MNC MediaSet ExportFile Row";
        Id: Guid;
        N: Integer;
        T: Text;
    begin
        N := Row.Pic.ExportFile('prefix');
    end;
}
