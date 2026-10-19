// @expect AL0187 | Attribute 'RunOnClient' is valid only for variables.
// @expect AL0296 | The application object or method 'RunOnClient' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// RunOnClient on a procedure: it is only valid on variables, and it has scope OnPrem.
codeunit 59025 "MNC RunOnClient 0973"
{
    [RunOnClient]
    procedure Run1()
    begin
    end;
}
