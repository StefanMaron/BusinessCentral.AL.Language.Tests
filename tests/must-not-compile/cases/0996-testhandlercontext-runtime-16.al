// @expect AL0666 | 'TestHandlerContext' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @min-al 18
// @appjson {"runtime": "16.0"}
// The TestHandlerContext type needs runtime 18.0 (BC 29 and later). An app below that runtime gets AL0666 on every BC major (the AL 16 and 17 compilers' verdict for BC 27 and 28 is in cases 0961, 0962, 0971).
codeunit 59140 "MNC ThCtx16 0996"
{
    procedure Run1(): Text
    var
        Ctx: TestHandlerContext;
    begin
        exit(Ctx.TestCaseName());
    end;
}
