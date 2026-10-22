// @expect AL0458 | 'RunOnClient' is not a valid attribute on variables of type 'Boolean'
// @target OnPrem
// RunOnClient on a Boolean variable (OnPrem app): the attribute is valid only on DotNet variables. Runtime test: tests/al-language-onprem-dotnet/lt-ac/AcDnAttributes.al.
codeunit 59125 "MNC RunOnClientBool 0993"
{
    var
        [RunOnClient]
        Flag: Boolean;

    procedure Run1()
    begin
    end;
}
