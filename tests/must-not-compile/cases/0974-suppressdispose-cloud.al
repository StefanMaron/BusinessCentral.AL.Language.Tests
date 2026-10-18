// @expect AL0187 | Attribute 'SuppressDispose' is valid only for variables.
// @expect AL0296 | The application object or method 'SuppressDispose' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// SuppressDispose on a procedure: it is only valid on variables, and it has scope OnPrem.
codeunit 59030 "MNC SuppressDispose 0974"
{
    [SuppressDispose]
    procedure Run1()
    begin
    end;
}
