// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-run-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: ALT Base (60007); TxRpt ReqPage Marker (60026), TxRpt Update Marker (60027),
//   TxRpt Plain Marker (60028), TxRpt ReqPage Error Marker (60029); shared Assert (60021)
//
// The report sibling of "Test TxModel RunModal" (60903), and the case that one cannot cover.
//
// A modal page run under a test never enters a transaction world, because the test framework
// answers the modal before the client round trip that would. A report run is different: the
// platform decides whether to enter a transaction world BEFORE the request page is shown, from
// two properties of the report — whether it uses a request page, and whether its
// TransactionType differs from the session's current one (UpdateNoLocks excepted) — and it
// exempts only a test running under TransactionModel::AutoRollback. Entering a transaction world
// has two consequences, and each test below pins one of them in a default-model test:
//
//   * it is refused while the caller holds an uncommitted write (Test04, Test05, Test08), with
//     the same generic "the transaction is stopped" text a guarded Codeunit.Run is refused with
//     ("Test Codeunit Run Write Tx", 60254);
//   * otherwise the report's own writes are committed when it returns, so a later trapped error
//     in the caller does not roll them back — while a write the caller makes AFTER the report
//     still is (Test06, Test07).
//
// Test03 is the control for both: a report with no request page and the default TransactionType
// enters no transaction world, so it neither is refused nor commits. Test02 is the control for
// the control: with no report at all, a trapped error rolls back a default-model test's write.
// Test09/Test10 pin the AutoRollback exemption. Test12 pins the failure branch: a report that
// raises inside its transaction world does not commit the write it made before raising.
//
// The tests are declaration-ordered and share a codeunit. Test01 clears every key this codeunit
// writes and Test11 clears them again, both without an attribute so the platform commits the
// deletes at the test boundary — Test06 and Test07 commit rows on purpose, and nothing else
// would remove them.
//
// Handler proof is carried on codeunit globals: a [RequestPageHandler] body may not write.
codeunit 60040 "Test TxModel Report Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        RequestPageHandled: Boolean;

    local procedure InsertBase(EntryNo: Integer)
    var
        ALTBase: Record "ALT Base";
    begin
        ALTBase.Init();
        ALTBase."Entry No." := EntryNo;
        ALTBase.Name := 'txrpt-probe';
        ALTBase.Insert();
    end;

    local procedure BaseExists(EntryNo: Integer): Boolean
    var
        ALTBase: Record "ALT Base";
    begin
        exit(ALTBase.Get(EntryNo));
    end;

    local procedure ClearKeys()
    var
        ALTBase: Record "ALT Base";
    begin
        ALTBase.SetRange("Entry No.", 60040000, 60040999);
        ALTBase.DeleteAll();
    end;

    [Test]
    procedure TxReportRun_Test01_ClearsTheKeys()
    var
        ALTBase: Record "ALT Base";
    begin
        ClearKeys();
        ALTBase.SetRange("Entry No.", 60040000, 60040999);
        Assert.AreEqual(0, ALTBase.Count(), 'No probe row may exist before the tests below write them.');
    end;

    [Test]
    procedure TxReportRun_Test02_WithoutAReportATrappedErrorRollsBackThePriorWrite()
    begin
        InsertBase(60040021);
        Assert.IsTrue(BaseExists(60040021), 'The probe row must be readable inside the test that wrote it.');

        asserterror Error('txrpt control probe');
        Assert.ExpectedError('txrpt control probe');

        Assert.IsFalse(BaseExists(60040021),
            'A trapped error must roll back a default-model test''s uncommitted write when nothing in between committed.');
    end;

    [Test]
    procedure TxReportRun_Test03_PlainReportWithPendingWriteRunsAndIsNotACommit()
    var
        Plain: Report "TxRpt Plain Marker";
    begin
        InsertBase(60040031);

        // No request page and the default TransactionType: no transaction world, so the pending
        // write above neither refuses the run nor gets committed by it.
        Plain.SetMarker(60040032);
        Plain.Run();

        Assert.IsTrue(BaseExists(60040032), 'The report body must have run and written its marker row.');

        asserterror Error('txrpt plain probe');
        Assert.ExpectedError('txrpt plain probe');

        Assert.IsFalse(BaseExists(60040031),
            'A report with no request page and the default TransactionType is not a commit point: the write made before it must be rolled back.');
        Assert.IsFalse(BaseExists(60040032),
            'The same report''s own write joined the caller''s transaction and must be rolled back with it.');
    end;

    [Test]
    procedure TxReportRun_Test04_RequestPageReportWithPendingWriteIsRefused()
    var
        ReqPage: Report "TxRpt ReqPage Marker";
    begin
        InsertBase(60040041);

        // No [HandlerFunctions]: the refusal comes before the request page is shown, and a
        // declared handler that never runs fails the test. Without the refusal the request
        // page would be unhandled, and ExpectedError below would report that text instead.
        ReqPage.SetMarker(60040042);
        asserterror ReqPage.Run();
        Assert.ExpectedError('the transaction is stopped');

        Assert.IsFalse(BaseExists(60040042), 'A refused report must not have run its body.');
        Assert.IsFalse(BaseExists(60040041), 'The trapped refusal must roll back the pending write that caused it.');
    end;

    [Test]
    procedure TxReportRun_Test05_RequestPageReportRunModalWithPendingWriteIsRefused()
    var
        ReqPage: Report "TxRpt ReqPage Marker";
    begin
        InsertBase(60040051);

        // No [HandlerFunctions], for the same reason as Test04.
        ReqPage.SetMarker(60040052);
        asserterror ReqPage.RunModal();
        Assert.ExpectedError('the transaction is stopped');

        Assert.IsFalse(BaseExists(60040052), 'A refused report must not have run its body.');
        Assert.IsFalse(BaseExists(60040051), 'The trapped refusal must roll back the pending write that caused it.');
    end;

    [Test]
    [HandlerFunctions('ConfirmRequestPageHandler')]
    procedure TxReportRun_Test06_RequestPageReportCommitsItsOwnWrites()
    var
        ReqPage: Report "TxRpt ReqPage Marker";
    begin
        RequestPageHandled := false;

        // No pending write here, so the transaction world is entered rather than refused.
        ReqPage.SetMarker(60040061);
        ReqPage.Run();

        Assert.IsTrue(RequestPageHandled, 'The [RequestPageHandler] must have run, so the request page really was shown.');
        Assert.IsTrue(BaseExists(60040061), 'The report body must have run and written its marker row.');

        InsertBase(60040062);

        asserterror Error('txrpt reqpage probe');
        Assert.ExpectedError('txrpt reqpage probe');

        Assert.IsTrue(BaseExists(60040061),
            'A report that enters a transaction world commits its own writes when it returns, so a later trapped error must not roll them back.');
        Assert.IsFalse(BaseExists(60040062),
            'A write the caller makes AFTER the report returns is uncommitted again and must be rolled back.');
    end;

    [Test]
    procedure TxReportRun_Test07_TransactionTypeUpdateReportCommitsItsOwnWrites()
    var
        UpdateRpt: Report "TxRpt Update Marker";
    begin
        // No request page, but TransactionType = Update differs from the session's current type.
        UpdateRpt.SetMarker(60040071);
        UpdateRpt.Run();

        Assert.IsTrue(BaseExists(60040071), 'The report body must have run and written its marker row.');

        InsertBase(60040072);

        asserterror Error('txrpt update probe');
        Assert.ExpectedError('txrpt update probe');

        Assert.IsTrue(BaseExists(60040071),
            'A report whose TransactionType differs from the session''s enters a transaction world and commits its own writes, so a later trapped error must not roll them back.');
        Assert.IsFalse(BaseExists(60040072),
            'A write the caller makes AFTER the report returns is uncommitted again and must be rolled back.');
    end;

    [Test]
    procedure TxReportRun_Test08_TransactionTypeUpdateReportWithPendingWriteIsRefused()
    var
        UpdateRpt: Report "TxRpt Update Marker";
    begin
        InsertBase(60040081);

        UpdateRpt.SetMarker(60040082);
        asserterror UpdateRpt.Run();
        Assert.ExpectedError('the transaction is stopped');

        Assert.IsFalse(BaseExists(60040082), 'A refused report must not have run its body.');
        Assert.IsFalse(BaseExists(60040081), 'The trapped refusal must roll back the pending write that caused it.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmRequestPageHandler')]
    procedure TxReportRun_Test09_AutoRollbackRequestPageReportWithPendingWriteRuns()
    var
        ReqPage: Report "TxRpt ReqPage Marker";
    begin
        RequestPageHandled := false;
        InsertBase(60040091);

        // AutoRollback is the one model the platform exempts: no transaction world, so no refusal.
        ReqPage.SetMarker(60040092);
        ReqPage.Run();

        Assert.IsTrue(RequestPageHandled, 'The [RequestPageHandler] must have run.');
        Assert.IsTrue(BaseExists(60040092), 'The report body must have run and written its marker row.');
        Assert.IsTrue(BaseExists(60040091), 'The write made before the report must still be readable.');
    end;

    [Test]
    procedure TxReportRun_Test10_AutoRollbackReportRunCommittedNothing()
    begin
        Assert.IsFalse(BaseExists(60040091),
            'Under AutoRollback the report run is not a commit, so the previous test''s prior write must have been rolled back.');
        Assert.IsFalse(BaseExists(60040092),
            'Under AutoRollback the report run is not a commit, so the previous test''s report write must have been rolled back.');
    end;

    [Test]
    procedure TxReportRun_Test11_ClearsTheKeysAgain()
    var
        ALTBase: Record "ALT Base";
    begin
        ClearKeys();
        ALTBase.SetRange("Entry No.", 60040000, 60040999);
        Assert.AreEqual(0, ALTBase.Count(), 'The rows Test06 and Test07 committed must be removable.');
    end;

    [Test]
    [HandlerFunctions('ConfirmErrorRequestPageHandler')]
    procedure TxReportRun_Test12_RequestPageReportThatFailsCommitsNothing()
    var
        ErrorRpt: Report "TxRpt ReqPage Error Marker";
    begin
        RequestPageHandled := false;

        // No pending write, so the transaction world is entered; the body writes its marker
        // and then raises. The report's own transaction ends without committing, so the marker
        // must not survive — unlike Test06, where the same write is committed on return.
        ErrorRpt.SetMarker(60040121);
        asserterror ErrorRpt.Run();
        Assert.ExpectedError('txrpt report body error');

        Assert.IsTrue(RequestPageHandled, 'The [RequestPageHandler] must have run, so the transaction world was entered.');
        Assert.IsFalse(BaseExists(60040121),
            'A report that raises inside its transaction world must not commit the write it made before raising.');
    end;

    [RequestPageHandler]
    procedure ConfirmErrorRequestPageHandler(var RequestPage: TestRequestPage "TxRpt ReqPage Error Marker")
    begin
        RequestPageHandled := true;
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ConfirmRequestPageHandler(var RequestPage: TestRequestPage "TxRpt ReqPage Marker")
    begin
        RequestPageHandled := true;
        RequestPage.OK().Invoke();
    end;
}
