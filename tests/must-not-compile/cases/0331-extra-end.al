// @expect AL0519 | 'end' is not valid value in this context.
// A procedure body with one end too many.
codeunit 50149 "MNC C331"
{
    procedure Run1()
    begin
    end;
    end;
}
