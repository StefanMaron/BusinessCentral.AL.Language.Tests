// @expect AL0134 | 'DataSourceContext' is not recognized as a valid type
// @until 28
// The DataSourceContext type exists from BC 29. The corpus app compiles at runtime 16.0, so a runtime test is not possible (case 0995 / 0996 give the verdict on BC 29).
codeunit 58965 "MNC DsCtx 0961"
{
    procedure Run1(): Integer
    var
        Ctx: DataSourceContext;
    begin
        exit(Ctx.CodeunitId());
    end;
}
