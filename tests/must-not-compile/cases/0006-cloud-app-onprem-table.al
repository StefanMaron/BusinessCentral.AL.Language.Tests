// @expect AL0296 | The application object or method 'Published Application' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// A Target = Cloud app names a table declared Scope = OnPrem.
codeunit 50000 "MNC Codeunit"
{
    procedure Count(): Integer
    var
        Published: Record "Published Application";
    begin
        exit(Published.Count());
    end;
}
