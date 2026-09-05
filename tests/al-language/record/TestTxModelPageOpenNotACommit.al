// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-openview-method
// Scope: in-scope
// Fixtures used: ALT Base (60007); ALT Universal (60001) via ALT List Page (60016); shared Assert (60021)
//
// Pins that OPENING A TESTPAGE IS NOT A COMMIT.
//
// TestIsolationRollbackScope (60897) pins where the platform rolls back under
// TestIsolation = Codeunit, and TestTransactionModelAutoRollback (60899) pins that
// [TransactionModel(TransactionModel::AutoRollback)] overrides it per test method.
// Neither of them opens a page. This codeunit adds the one thing between the write and
// the end of the test that a consumer might reasonably believe commits it, and asks
// whether it does.
//
// Why the question is worth a test. A page CAN reach a commit in BC: opening one
// modally enters a transaction world, and entering a transaction world commits the
// active transaction. But that path belongs to Page.RunModal and Report.Run, not to
// TestPage.OpenView / OpenEdit — a TestPage attaches through the test client session
// instead, with no transaction world involved. So a write made before a TestPage opens
// is still uncommitted afterwards, and both the per-test AutoRollback and a later
// asserterror still undo it.
//
// Reading this wrong is expensive in exactly one direction: treat the page open as a
// commit and every write a test makes before opening a page silently outlives the test,
// which is how one test's setup ends up failing an unrelated later test in the same
// codeunit with something like "already exists".
//
// The three tests are declaration-ordered and share a codeunit, following
// TestTransactionModelAutoRollback's own convention.
//   Test01 (AutoRollback): writes a uniquely-keyed row, opens and closes a TestPage,
//     confirms the row is still readable inside the test that wrote it.
//   Test02 (no attribute): asks whether Test01's row survived. It must not — the page
//     open did not commit it, so AutoRollback still rolled it back.
//   Test03 (no attribute): writes a row, opens and closes a TestPage, then traps an
//     unrelated error and confirms the pre-page-open write was rolled back too, since
//     an AL error unwinds to the last commit and the page open was not one.
//
// The page deliberately has a different source table from the row being written. The
// claim is about the transaction, not about what the page displays.
codeunit 60900 "Test TxModel Page Open"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure Test01_WritesARowThenOpensAndClosesATestPage()
    var
        Base: Record "ALT Base";
        ListPage: TestPage "ALT List Page";
    begin
        if Base.Get(60900001) then
            Base.Delete();

        Base.Init();
        Base."Entry No." := 60900001;
        Base."Name" := 'txmodel-pageopen-probe';
        Base.Insert();

        ListPage.OpenView();
        ListPage.Close();

        Assert.IsTrue(
            Base.Get(60900001),
            'A row written before a TestPage opened must still be readable inside the test that ' +
            'wrote it, after the page has been opened and closed.');
    end;

    [Test]
    procedure Test02_ThePageOpenDidNotCommitThePriorTestsWrite()
    var
        Base: Record "ALT Base";
    begin
        Assert.IsFalse(
            Base.Get(60900001),
            'Opening a TestPage is not a Commit. TestPage.OpenView attaches through the test ' +
            'client session and enters no transaction world, so the previous test''s write was ' +
            'still uncommitted when that test ended and TransactionModel::AutoRollback undid it.');
    end;

    [Test]
    procedure Test03_AsserterrorAfterAPageOpenStillRollsBackTheWriteMadeBeforeIt()
    var
        Base: Record "ALT Base";
        ListPage: TestPage "ALT List Page";
    begin
        if Base.Get(60900002) then
            Base.Delete();

        Base.Init();
        Base."Entry No." := 60900002;
        Base."Name" := 'txmodel-pageopen-asserterror';
        Base.Insert();

        ListPage.OpenView();
        ListPage.Close();

        asserterror Error('txmodel page open rollback probe');
        Assert.ExpectedError('txmodel page open rollback probe');

        Assert.IsFalse(
            Base.Get(60900002),
            'An AL error unwinds the database to the last commit, and the TestPage open in ' +
            'between was not one, so the write made BEFORE the page opened is rolled back too.');
    end;
}
