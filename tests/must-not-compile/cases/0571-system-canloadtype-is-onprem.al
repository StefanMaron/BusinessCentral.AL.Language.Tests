// @expect AL0296 | The application object or method 'CanLoadType' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// System.CanLoadType named from a Cloud app (the method has scope OnPrem).
codeunit 50571 "MNC O 0571"
{
    procedure Probe()
    var Ok: Boolean;
    begin
        Ok := CanLoadType(1);
    end;
}
