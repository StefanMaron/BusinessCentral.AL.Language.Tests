// @expect AL0296 | The application object or method 'ImportFile' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// MediaSet.ImportFile from a Cloud app.
table 50646 "MNC MediaSet ImportFile Row"
{
    fields { field(1; Code; Code[20]) { } field(2; Pic; MediaSet) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 50646 "MNC MediaSet ImportFile"
{
    procedure Do()
    var
        Row: Record "MNC MediaSet ImportFile Row";
        Id: Guid;
        N: Integer;
        T: Text;
    begin
        Id := Row.Pic.ImportFile('x.png', 'desc');
    end;
}
