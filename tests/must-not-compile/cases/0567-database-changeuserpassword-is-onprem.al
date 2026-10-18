// @expect AL0296 | The application object or method 'ChangeUserPassword' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// Database.ChangeUserPassword named from a Cloud app (the method has scope OnPrem).
codeunit 50567 "MNC O 0567"
{
    procedure Probe()
    var Done: Boolean;
    begin
        Done := Database.ChangeUserPassword('a', 'b');
    end;
}
