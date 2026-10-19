// @expect AL0296 | The application object or method 'UseWindowsAuthentication' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// HttpClient UseWindowsAuthentication Text from a Cloud app.
codeunit 50653 "MNC Http WinAuth Text"
{
    procedure Do()
    var
        Client: HttpClient;
        User: SecretText;
        Pwd: SecretText;
        Ok: Boolean;
    begin
        Ok := Client.UseWindowsAuthentication('user', 'password', 'DOMAIN');
    end;
}
