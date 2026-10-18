// @expect AL0296 | The application object or method 'Export' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// Blob.Export named from a Cloud app (the method has scope OnPrem).
codeunit 50563 "MNC O 0563"
{
    procedure Probe()
    var Info: Record "Tenant Media";
    begin
        Info.Content.Export('x');
    end;
}
