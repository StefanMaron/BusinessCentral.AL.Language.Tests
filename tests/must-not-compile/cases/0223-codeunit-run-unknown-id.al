// @expect AL0118 | The name '"MNC No Such Codeunit"' does not exist in the current context.
// Codeunit.Run names a codeunit by a name that does not exist.
codeunit 50028 "MNC C223"
{
    procedure Run1()
    begin
        Codeunit.Run(Codeunit::"MNC No Such Codeunit");
    end;
}
