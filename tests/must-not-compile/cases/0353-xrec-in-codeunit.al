// @expect AL0118 | The name 'xRec' does not exist in the current context.
// xRec in a codeunit without TableNo.
codeunit 50171 "MNC C353"
{
    procedure Run1()
    begin
        xRec.Init();
    end;
}
