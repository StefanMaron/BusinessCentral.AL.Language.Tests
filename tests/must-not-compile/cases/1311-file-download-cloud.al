// @expect AL0296 | The application object or method 'Download' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// File.Download of a server file named from a Cloud app (scope OnPrem; DownloadFromStream is the Cloud form).
codeunit 51311 "MNC BG 1311"
{
    procedure Probe(): Boolean
    var
        ToFile: Text;
    begin
        exit(File.Download('lt-bg.txt', 'Title', '', '', ToFile));
    end;
}
