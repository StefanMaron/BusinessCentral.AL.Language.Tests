// @expect AL0296 | The application object or method 'AlterKey' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// Database.AlterKey named from a Cloud app (the method has scope OnPrem).
codeunit 50566 "MNC O 0566"
{
    procedure Probe()
    var Ref: RecordRef; Idx: KeyRef;
    begin
        Idx := Ref.KeyIndex(1); Database.AlterKey(Idx, true);
    end;
}
