// @expect AL0296 | The application object or method 'AITokensUsed' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// SessionInformation.AITokensUsed named from a Cloud app (the method has scope OnPrem).
codeunit 50565 "MNC O 0565"
{
    procedure Probe()
    var Used: Integer;
    begin
        Used := SessionInformation.AITokensUsed();
    end;
}
