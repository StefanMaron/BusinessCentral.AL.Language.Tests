// @expect AL0134 | 'TestHandlerContext' is not recognized as a valid type
// @until 28
// @max-al 17
// The TestHandlerContext type exists from BC 29. Runtime test for BC 29: tests/al-language/lt-ac/ACContexts.al.
codeunit 58970 "MNC ThCtx 0962"
{
    procedure Run1(): Text
    var
        Ctx: TestHandlerContext;
    begin
        exit(Ctx.TestCaseName());
    end;
}
