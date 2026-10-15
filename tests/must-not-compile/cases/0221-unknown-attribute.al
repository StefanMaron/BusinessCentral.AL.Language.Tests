// @expect AL0112 | NoSuchAttribute is not a valid attribute. Check the attribute name and supported attributes for this context.
// An attribute that does not exist decorates a procedure.
codeunit 50026 "MNC C221"
{
    [NoSuchAttribute]
    procedure Run1()
    begin
    end;
}
