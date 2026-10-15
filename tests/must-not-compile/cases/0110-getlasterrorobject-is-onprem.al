// @expect AL0296 | The application object or method 'GetLastErrorObject' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// GetLastErrorObject has scope OnPrem; a Cloud app names it.
codeunit 50116 "MNC Last Error Object"
{
    procedure Describe(): Text
    var
        Info: ErrorInfo;
    begin
        Info := GetLastErrorObject();
        exit(Info.Message);
    end;
}
