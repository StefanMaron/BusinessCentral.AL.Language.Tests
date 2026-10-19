// @expect AL0296 | The application object or method 'UseWindowsAuthentication' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// HttpClient UseWindowsAuthentication SecretText from a Cloud app.
codeunit 50654 "MNC Http WinAuth SecretText"
{
    procedure Do()
    var
        Client: HttpClient;
        User: SecretText;
        Pwd: SecretText;
        Ok: Boolean;
    begin
        Ok := Client.UseWindowsAuthentication(User, Pwd, User);
    end;
}
