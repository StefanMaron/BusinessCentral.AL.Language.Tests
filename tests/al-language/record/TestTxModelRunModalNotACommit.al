// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: ALT Base (60007); Test Page Modal Handler Row (60702), Test Page Modal (60703);
//   shared Assert (60021)
//
// The modal sibling of TestTxModelPageOpenNotACommit (60900), and the case that one leaves
// open.
//
// 60900 pins that opening a TestPage is not a Commit, and the reason is that a TestPage
// attaches through the test client session without entering a transaction world. RunModal is
// the case where that reasoning stops applying on its face: a page opened modally DOES enter a
// transaction world, and entering one commits the caller's active transaction. So "a page open
// is not a commit" and "a modal page run is not a commit" are two different claims, and the
// second one is not implied by the first.
//
// It is also the claim most likely to be got wrong in the safe-looking direction. Entering a
// transaction world raises if a write transaction is already open, so a reasonable reading of
// the platform is that AL which writes a row and then calls Page.RunModal either commits that
// write or is refused outright. Under a test, neither happens: the test framework answers the
// modal itself, and the client round trip that would have entered the transaction world is
// never reached. TestPageModalHandlerStatic_Tests (60717) already writes a row before calling
// Page.RunModal and is green, which shows the refusal does not happen; what nobody has pinned
// is the other half, that the write is still uncommitted afterwards.
//
// The three tests are declaration-ordered and share a codeunit, following 60899 and 60900.
//   Test01 (AutoRollback): writes a uniquely-keyed row, runs a page modally through a
//     [ModalPageHandler], and confirms both that the modal really opened and that the row is
//     still readable inside the test that wrote it. Reaching its assertions at all is the
//     evidence that the open write transaction did not get the modal run refused.
//   Test02 (no attribute): asks whether Test01's row survived. It must not.
//   Test03 (no attribute): writes a row, runs the modal, then traps an unrelated error and
//     confirms the pre-RunModal write was rolled back with it.
//
// The probe row and the modal page's source table are deliberately different tables, so the
// handler's own writes cannot be mistaken for the write under test.
codeunit 60903 "Test TxModel RunModal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('OkHandler')]
    procedure Test01_WritesARowThenRunsAPageModally()
    var
        Base: Record "ALT Base";
        Row: Record "Test Page Modal Handler Row";
    begin
        Row.DeleteAll();

        if Base.Get(60903001) then
            Base.Delete();

        Base.Init();
        Base."Entry No." := 60903001;
        Base."Name" := 'txmodel-runmodal-probe';
        Base.Insert();

        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();

        // A write transaction is open here — the two Inserts above. Reaching the assertions
        // below at all is the point: under a test the modal run is answered by the handler,
        // not by the client round trip that would enter a transaction world, so the write
        // transaction neither gets committed nor gets the run refused.
        Page.RunModal(Page::"Test Page Modal", Row);

        Assert.IsTrue(
            Row.Get('HANDLER'),
            'the [ModalPageHandler] must have run, so the modal page really was opened rather ' +
            'than skipped — without this the rest of this codeunit would prove nothing.');

        Assert.IsTrue(
            Base.Get(60903001),
            'A row written before a page was run modally must still be readable inside the test ' +
            'that wrote it.');
    end;

    [Test]
    procedure Test02_TheModalRunDidNotCommitThePriorTestsWrite()
    var
        Base: Record "ALT Base";
    begin
        Assert.IsFalse(
            Base.Get(60903001),
            'Running a page modally inside a test is not a Commit. The test framework answers ' +
            'the modal itself, so the transaction world that would have committed the caller''s ' +
            'active transaction is never entered, and TransactionModel::AutoRollback undid the ' +
            'previous test''s write.');
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure Test03_AsserterrorAfterAModalRunStillRollsBackTheWriteMadeBeforeIt()
    var
        Base: Record "ALT Base";
        Row: Record "Test Page Modal Handler Row";
    begin
        Row.DeleteAll();

        if Base.Get(60903002) then
            Base.Delete();

        Base.Init();
        Base."Entry No." := 60903002;
        Base."Name" := 'txmodel-runmodal-asserterror';
        Base.Insert();

        Row.Init();
        Row."No." := 'B';
        Row.Descr := 'Bravo';
        Row.Insert();

        Page.RunModal(Page::"Test Page Modal", Row);
        Assert.IsTrue(Row.Get('HANDLER'), 'the [ModalPageHandler] must have run');

        asserterror Error('txmodel runmodal rollback probe');
        Assert.ExpectedError('txmodel runmodal rollback probe');

        Assert.IsFalse(
            Base.Get(60903002),
            'An AL error unwinds the database to the last commit, and the modal page run in ' +
            'between was not one, so the write made BEFORE it is rolled back too.');
    end;

    [ModalPageHandler]
    procedure OkHandler(var Modal: TestPage "Test Page Modal")
    var
        Stamp: Record "Test Page Modal Handler Row";
    begin
        Stamp.Init();
        Stamp."No." := 'HANDLER';
        Stamp.Descr := 'ran';
        if not Stamp.Insert() then
            Stamp.Modify();
        Modal.OK().Invoke();
    end;
}
