// @expect AL0132 | 'TextBuilder' does not contain a definition for 'Add'
// TextBuilder has no Add method (Append).
codeunit 50042 "MNC C236"
{
    procedure Run1()
    var
        TB: TextBuilder;
    begin
        TB.Add('x');
    end;
}
