// @expect AL0118 | The name 'Undeclared' does not exist in the current context.
// A report trigger uses an undeclared variable.
report 50011 "MNC R208"
{
    trigger OnPreReport()
    begin
        Undeclared := 5;
    end;
}
