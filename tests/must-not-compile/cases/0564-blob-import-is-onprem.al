// @expect AL0296 | The application object or method 'Import' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// Blob.Import named from a Cloud app (the method has scope OnPrem).
codeunit 50564 "MNC O 0564"
{
    procedure Probe()
    var Info: Record "Tenant Media";
    begin
        Info.Content.Import('x');
    end;
}
