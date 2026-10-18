// @expect AL0296 | The application object or method 'ExportEncryptionKey' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// System.ExportEncryptionKey named from a Cloud app (the method has scope OnPrem).
codeunit 50572 "MNC O 0572"
{
    procedure Probe()
    
    begin
        ExportEncryptionKey('x');
    end;
}
