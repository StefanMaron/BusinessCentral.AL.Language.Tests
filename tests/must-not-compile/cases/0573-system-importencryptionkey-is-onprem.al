// @expect AL0296 | The application object or method 'ImportEncryptionKey' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// System.ImportEncryptionKey named from a Cloud app (the method has scope OnPrem).
codeunit 50573 "MNC O 0573"
{
    procedure Probe()
    
    begin
        ImportEncryptionKey('f', 'p');
    end;
}
