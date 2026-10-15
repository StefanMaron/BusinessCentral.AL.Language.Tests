// @expect AL0132 | 'List of [Text]' does not contain a definition for 'Length'
// List has no Length method (Count is the method).
codeunit 50030 "MNC C225"
{
    procedure Run1()
    var
        L: List of [Text];
        N: Integer;
    begin
        N := L.Length();
    end;
}
