// @expect AL0187 | Attribute 'SecurityFiltering' is valid only for variables.
// SecurityFiltering on a procedure (it belongs on a Record variable: tests/al-language/lt-ac/ACAttributes.al).
codeunit 59040 "MNC SecFilter 0976"
{
    [SecurityFiltering(SecurityFilter::Filtered)]
    procedure Run1()
    begin
    end;
}
