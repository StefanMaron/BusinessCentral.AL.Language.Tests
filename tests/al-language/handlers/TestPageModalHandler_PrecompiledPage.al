// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modal-page-handler
// Scope: in-scope
// Fixtures used: Assert (60021)
//
// TestPageModalHandler_Tests.al already pins [ModalPageHandler] dispatch end-to-end against
// this suite's OWN fixture pages (source-compiled inside this test app, alongside the test
// codeunit that drives them). This file pins the SAME dispatch against pages this app never
// compiles itself: Base Application's own "Error Messages" (700) and "No. Series" (456),
// reached only as declared dependencies. Nothing about ModalPageHandler dispatch should care
// where the page's own code came from — a runner or engine that only wires the handler path
// for pages compiled alongside the test would pass every case in the sibling file and still
// fail every case here.
//
// `Action := Page.RunModal();` on a plain page VARIABLE (no host/wrapper page, unlike the
// sibling suite) is the direct shape: the modal is opened straight from the test procedure,
// matching how AL commonly opens a system page (e.g. `ErrorMessages.RunModal();` after
// `SetRecords`).

codeunit 60902 "TP Modal Handler Precompiled"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // Positive: the handler runs, and its OK reaches the calling AL as Action::OK — not just
    // "did not throw". A runner that routed dispatch but always answered OK regardless of what
    // the handler invoked would still pass this one; the Cancel test below catches that.
    [Test]
    [HandlerFunctions('ErrorMessagesOkHandler')]
    procedure RunModalOnErrorMessages_HandlerInvokesOk_ReturnsActionOk()
    var
        ErrorMessages: Page "Error Messages";
        Result: Action;
    begin
        Result := ErrorMessages.RunModal();

        Assert.AreEqual(Action::OK, Result,
            'RunModal on a precompiled Base Application page must return the ACTION the ' +
            '[ModalPageHandler] actually invoked (OK)');
    end;

    // Negative pairing: the same page, a handler that cancels instead. Proves the handler's
    // OWN choice reaches the caller, not a constant.
    [Test]
    [HandlerFunctions('ErrorMessagesCancelHandler')]
    procedure RunModalOnErrorMessages_HandlerInvokesCancel_ReturnsActionCancel()
    var
        ErrorMessages: Page "Error Messages";
        Result: Action;
    begin
        Result := ErrorMessages.RunModal();

        Assert.AreEqual(Action::Cancel, Result,
            'RunModal on a precompiled Base Application page must return the ACTION the ' +
            '[ModalPageHandler] actually invoked (Cancel)');
    end;

    // Positive, a different precompiled page (different PageType/SourceTable shape: "No.
    // Series" is a List page over table "No. Series", "Error Messages" is a List page over a
    // TEMPORARY table) — the claim is not specific to one page's particular declaration.
    [Test]
    [HandlerFunctions('NoSeriesOkHandler')]
    procedure RunModalOnNoSeries_HandlerInvokesOk_ReturnsActionOk()
    var
        NoSeriesPage: Page "No. Series";
        Result: Action;
    begin
        Result := NoSeriesPage.RunModal();

        Assert.AreEqual(Action::OK, Result,
            'RunModal on a second precompiled Base Application page must also return the ' +
            'ACTION the [ModalPageHandler] actually invoked (OK)');
    end;

    // Negative: no [HandlerFunctions] at all for a precompiled page. Must be refused with
    // BC's own missing-handler error — a silently-answered dialog is not distinguishable from
    // an approved one, exactly the risk TestPageModalHandler_Tests.al's own negative pins for
    // the source-compiled case.
    [Test]
    procedure RunModalOnErrorMessages_WithoutAHandler_IsRefused()
    var
        ErrorMessages: Page "Error Messages";
    begin
        asserterror ErrorMessages.RunModal();
        Assert.ExpectedError('Unhandled UI');
    end;

    [ModalPageHandler]
    procedure ErrorMessagesOkHandler(var TP: TestPage "Error Messages")
    begin
        TP.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ErrorMessagesCancelHandler(var TP: TestPage "Error Messages")
    begin
        TP.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure NoSeriesOkHandler(var TP: TestPage "No. Series")
    begin
        TP.OK().Invoke();
    end;
}
