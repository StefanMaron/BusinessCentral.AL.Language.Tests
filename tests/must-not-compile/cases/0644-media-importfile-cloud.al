// @expect AL0296 | The application object or method 'ImportFile' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// Media.ImportFile from a Cloud app.
table 50644 "MNC Media ImportFile Row"
{
    fields { field(1; Code; Code[20]) { } field(2; Pic; Media) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 50644 "MNC Media ImportFile"
{
    procedure Do()
    var
        Row: Record "MNC Media ImportFile Row";
        Id: Guid;
        N: Integer;
        T: Text;
    begin
        Id := Row.Pic.ImportFile('x.png', 'desc');
    end;
}
