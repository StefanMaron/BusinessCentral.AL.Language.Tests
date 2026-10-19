// @expect AL0118 | The name 'CurrPage' does not exist in the current context.
// CurrPage in a codeunit.
codeunit 50169 "MNC C351"
{
    procedure Run1()
    begin
        CurrPage.Update();
    end;
}
