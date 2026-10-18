// @expect AL0666 | 'DataSourceContext' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @from 29
// On BC 29 the DataSourceContext type needs runtime 18.0; the corpus app compiles at runtime 16.0, so tests cannot declare one (cases 0961 gives the BC 27 and 28 verdict).
codeunit 59135 "MNC DsCtx16 0995"
{
    procedure Run1(): Integer
    var
        Ctx: DataSourceContext;
    begin
        exit(Ctx.CodeunitId());
    end;
}
