// @expect AL0666 | 'RequiredPending' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @from 29
// On BC 29 the RequiredPending attribute needs runtime 18.0; the corpus app compiles at runtime 16.0 (case 0971 gives the BC 27 and 28 verdict).
codeunit 59145 "MNC ReqPending16 0997"
{
    [RequiredPending('Use the new procedure', '29.0')]
    procedure Run1()
    begin
    end;
}
