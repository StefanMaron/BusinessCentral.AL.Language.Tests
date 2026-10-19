// @expect AL0296 | The application object or method 'UseDefaultNetworkWindowsAuthentication' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// HttpClient UseDefaultNetworkWindowsAuthentication from a Cloud app.
codeunit 50651 "MNC Http DefaultNetworkWinAuth"
{
    procedure Do()
    var
        Client: HttpClient;
        User: SecretText;
        Pwd: SecretText;
        Ok: Boolean;
    begin
        Ok := Client.UseDefaultNetworkWindowsAuthentication();
    end;
}
