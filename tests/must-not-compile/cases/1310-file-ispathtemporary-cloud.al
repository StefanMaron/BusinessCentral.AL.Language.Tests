// @expect AL0296 | The application object or method 'IsPathTemporary' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// File.IsPathTemporary named from a Cloud app (the File type and its methods have scope OnPrem).
codeunit 51310 "MNC BG 1310"
{
    procedure Probe(): Boolean
    begin
        exit(File.IsPathTemporary('lt-bg.tmp'));
    end;
}
