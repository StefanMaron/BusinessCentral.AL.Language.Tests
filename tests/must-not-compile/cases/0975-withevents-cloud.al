// @expect AL0187 | Attribute 'WithEvents' is valid only for variables.
// @expect AL0296 | The application object or method 'WithEvents' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// WithEvents on a procedure: it is only valid on variables, and it has scope OnPrem.
codeunit 59035 "MNC WithEvents 0975"
{
    [WithEvents]
    procedure Run1()
    begin
    end;
}
