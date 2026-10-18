// @expect AL0296 | The application object or method 'ImportStreamWithUrlAccess' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// System.ImportStreamWithUrlAccess named from a Cloud app (the method has scope OnPrem).
codeunit 50574 "MNC O 0574"
{
    procedure Probe()
    var Data: InStream; Url: Text;
    begin
        Url := ImportStreamWithUrlAccess(Data, 'f', 5);
    end;
}
