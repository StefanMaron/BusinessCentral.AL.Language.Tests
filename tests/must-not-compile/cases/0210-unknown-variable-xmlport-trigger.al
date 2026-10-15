// @expect AL0118 | The name 'Undeclared' does not exist in the current context.
// An xmlport trigger uses an undeclared variable.
xmlport 50014 "MNC X210"
{
    trigger OnPreXmlPort()
    begin
        Undeclared := 5;
    end;
}
