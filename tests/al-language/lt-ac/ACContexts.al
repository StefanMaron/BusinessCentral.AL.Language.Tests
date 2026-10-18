// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-overview
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: DataSourceContext (AppId, CodeunitId) and TestHandlerContext (CodeunitId, CodeunitName, ProcedureName, TestCaseName, Success, Skip) used on a variable outside any handler (BC 29 and later; BC 27 and 28 reject the types, see must-not-compile cases 0961 and 0962). The types are only handed to a handler by the test framework (the symbols that declare the handler enum and ITestContext are not public); this pins the result of every member on a variable of the type that is not inside a handler.
//   Settles #626 items 9, 10, 17 and #627 items 14 to 19 as far as they are reachable from AL.
// BC versions: 29

#if BC29PLUS
codeunit 77505 "LT AC Contexts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_DataSourceContext_Outside()
    var
        Observer: Codeunit "Probe Observer";
        Ctx: DataSourceContext;
    begin
        if not TryAppId(Ctx, Observer) then
            Observer.ObserveError('appid_err');
        if not TryCodeunitId(Ctx, Observer) then
            Observer.ObserveError('codeunitid_err');
        Observer.Finish();
    end;

    [Test]
    procedure AC_TestHandlerContext_Outside()
    var
        Observer: Codeunit "Probe Observer";
        Ctx: TestHandlerContext;
    begin
        if not TryHandlerCodeunitId(Ctx, Observer) then
            Observer.ObserveError('codeunitid_err');
        if not TryHandlerCodeunitName(Ctx, Observer) then
            Observer.ObserveError('codeunitname_err');
        if not TryHandlerProcedureName(Ctx, Observer) then
            Observer.ObserveError('procedurename_err');
        if not TryHandlerTestCaseName(Ctx, Observer) then
            Observer.ObserveError('testcasename_err');
        if not TryHandlerSuccess(Ctx, Observer) then
            Observer.ObserveError('success_err');
        Observer.Finish();
    end;

    [Test]
    procedure AC_TestHandlerContext_Skip_Outside()
    var
        Observer: Codeunit "Probe Observer";
        Ctx: TestHandlerContext;
    begin
        if not TryHandlerSkip(Ctx) then
            Observer.ObserveError('skip_err')
        else
            Observer.Observe('skip_returned', 'yes');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryAppId(var Ctx: DataSourceContext; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('appid', Format(Ctx.AppId()));
    end;

    [TryFunction]
    local procedure TryCodeunitId(var Ctx: DataSourceContext; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('codeunitid', Format(Ctx.CodeunitId()));
    end;

    [TryFunction]
    local procedure TryHandlerCodeunitId(var Ctx: TestHandlerContext; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('codeunitid', Format(Ctx.CodeunitId()));
    end;

    [TryFunction]
    local procedure TryHandlerCodeunitName(var Ctx: TestHandlerContext; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('codeunitname', Ctx.CodeunitName());
    end;

    [TryFunction]
    local procedure TryHandlerProcedureName(var Ctx: TestHandlerContext; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('procedurename', Ctx.ProcedureName());
    end;

    [TryFunction]
    local procedure TryHandlerTestCaseName(var Ctx: TestHandlerContext; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('testcasename', Ctx.TestCaseName());
    end;

    [TryFunction]
    local procedure TryHandlerSuccess(var Ctx: TestHandlerContext; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('success', Format(Ctx.Success()));
    end;

    [TryFunction]
    local procedure TryHandlerSkip(var Ctx: TestHandlerContext)
    begin
        Ctx.Skip('probe');
    end;
}
#endif
