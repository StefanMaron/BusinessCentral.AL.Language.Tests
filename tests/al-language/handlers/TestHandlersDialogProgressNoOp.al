// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-data-type
// Scope: in-scope
// Fixtures used: none (self-contained)
// Note: proves a BC progress (status) Dialog is a faithful headless no-op —
// code after Dialog.Open/Update/Close must run to completion identically
// whether or not a window appeared, and must not swallow a subsequent error.
// BC versions: 24+

codeunit 60218 "Test Handlers Dialog NoOp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Window: Dialog;

    [Test]
    procedure ProgressDialog_OpenUpdateClose_IsNoOp_CodeAfterRuns()
    var
        Counter: Integer;
        Total: Integer;
    begin
        Initialize();
        // [GIVEN] a progress dialog with an integer parameter token (#1#####).
        //         The token forces NavDialog.ALOpenAsync<T> to build a
        //         NavFormSourceExpressionGetterAsync[] — the exact path that NREd.
        Window.Open('Processing record #1######');

        // [WHEN] the dialog is updated and closed, and real work runs in between
        Total := 0;
        for Counter := 1 to 5 do begin
            Window.Update(1, Counter);
            Total += Counter;
        end;
        Window.Close();

        // [THEN] the code after Dialog.Open/Update/Close ran to completion and
        //        produced a concrete value (1+2+3+4+5 = 15). If the dialog had
        //        thrown (the old NRE) or swallowed control flow, Total would be 0.
        Assert.AreEqual(15, Total, 'Code after a progress Dialog must run and accumulate.');
    end;

    [Test]
    procedure ProgressDialog_DoesNotSwallowSubsequentError()
    begin
        Initialize();
        // [GIVEN] a progress dialog is opened (headless no-op) ...
        Window.Open('Working #1######');
        Window.Update(1, 1);

        // [WHEN] AL code after the dialog raises an error
        // [THEN] that error must still propagate — the dialog no-op must not
        //        disturb normal control flow or swallow the exception.
        asserterror Error('BOOM-AFTER-DIALOG');
        Assert.ExpectedError('BOOM-AFTER-DIALOG');

        Window.Close();
    end;

    local procedure Initialize()
    begin
    end;
}
