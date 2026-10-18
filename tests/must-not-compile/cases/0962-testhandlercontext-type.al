// @expect AL0134 | 'TestHandlerContext' is not recognized as a valid type
// @until 28
// The TestHandlerContext type exists from BC 29. The corpus app compiles at runtime 16.0, so a runtime test is not possible (case 0995 / 0996 give the verdict on BC 29).
codeunit 58970 "MNC ThCtx 0962"
{
    procedure Run1(): Text
    var
        Ctx: TestHandlerContext;
    begin
        exit(Ctx.TestCaseName());
    end;
}
