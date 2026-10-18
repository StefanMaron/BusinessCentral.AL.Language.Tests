// @expect AL0296 | The application object or method 'SetUserPassword' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// Database.SetUserPassword named from a Cloud app (the method has scope OnPrem).
codeunit 50568 "MNC O 0568"
{
    procedure Probe()
    
    begin
        Database.SetUserPassword(CreateGuid(), 'x');
    end;
}
