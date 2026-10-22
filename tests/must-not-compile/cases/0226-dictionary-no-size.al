// @expect AL0132 | 'Dictionary of [Text, Integer]' does not contain a definition for 'Size'
// Dictionary has no Size method (Count is the method).
codeunit 50031 "MNC C226"
{
    procedure Run1()
    var
        D: Dictionary of [Text, Integer];
        N: Integer;
    begin
        N := D.Size();
    end;
}
