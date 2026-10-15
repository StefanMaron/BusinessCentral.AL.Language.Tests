// @expect AL0118 | The name 'CurrReport' does not exist in the current context.
// CurrReport in a codeunit.
codeunit 50170 "MNC C352"
{
    procedure Run1()
    begin
        CurrReport.Skip();
    end;
}
