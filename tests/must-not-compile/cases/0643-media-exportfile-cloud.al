// @expect AL0296 | The application object or method 'ExportFile' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// Media.ExportFile from a Cloud app.
table 50643 "MNC Media ExportFile Row"
{
    fields { field(1; Code; Code[20]) { } field(2; Pic; Media) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 50643 "MNC Media ExportFile"
{
    procedure Do()
    var
        Row: Record "MNC Media ExportFile Row";
        Id: Guid;
        N: Integer;
        T: Text;
    begin
        T := Row.Pic.ExportFile('x.png');
    end;
}
