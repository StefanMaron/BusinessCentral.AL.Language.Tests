// @expect AL0132 | 'RecordRef' does not contain a definition for 'Fieldd'
// RecordRef has no Fieldd method.
codeunit 50036 "MNC C230"
{
    procedure Run1()
    var
        RR: RecordRef;
        F: FieldRef;
    begin
        F := RR.Fieldd(1);
    end;
}
