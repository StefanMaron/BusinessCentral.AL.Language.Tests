// @expect AL0666 | 'TestHandlerContext' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @from 29
// On BC 29 the TestHandlerContext type needs runtime 18.0; the corpus app compiles at runtime 16.0 (case 0962 gives the BC 27 and 28 verdict).
codeunit 59140 "MNC ThCtx16 0996"
{
    procedure Run1(): Text
    var
        Ctx: TestHandlerContext;
    begin
        exit(Ctx.TestCaseName());
    end;
}
