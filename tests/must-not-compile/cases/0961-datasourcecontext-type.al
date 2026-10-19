// @expect AL0134 | 'DataSourceContext' is not recognized as a valid type
// @until 28
// @max-al 17
// The DataSourceContext type exists from BC 29. Runtime test for BC 29: tests/al-language/lt-ac/ACContexts.al.
codeunit 58965 "MNC DsCtx 0961"
{
    procedure Run1(): Integer
    var
        Ctx: DataSourceContext;
    begin
        exit(Ctx.CodeunitId());
    end;
}
