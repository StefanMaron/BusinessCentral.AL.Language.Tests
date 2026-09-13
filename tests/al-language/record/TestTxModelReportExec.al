// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-execute-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-print-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-runrequestpage-method
// Scope: in-scope
// Fixtures used: ALT Base (60007); TxExec ReqPage Marker (60029), TxExec Update Marker (60030),
//   TxExec Plain Marker (60031); shared Assert (60021)
//
// Report.Run and Report.RunModal are not the only report calls that can enter a transaction
// world. Report.RunRequestPage, Report.Execute and Report.Print reach the same platform decision,
// made before the report body runs: enter one when the run uses a request page, or when the
// report's TransactionType differs from the session's current one (UpdateNoLocks excepted); a
// test running under TransactionModel::AutoRollback is exempt. What differs is the request-page
// term:
//
//   * RunRequestPage always shows the request page, so it always enters a transaction world, and
//     is refused while the caller holds an uncommitted write (Test02 instance, Test03 static).
//     Test04 is the control: with no pending write it shows the page and returns parameters.
//     Test05 pins the AutoRollback exemption.
//   * Execute and Print never show the request page, so only the TransactionType term applies.
//     A TransactionType = Update report is refused with a pending write (Test06 instance, Test10
//     static, Test11 Print), and otherwise commits its own writes (Test07). A plain report
//     (Test08) and, above all, a report that HAS a request page (Test09) are neither refused nor
//     a commit: the request page a report declares is irrelevant to Execute. Test12/Test13 pin
//     the AutoRollback exemption for Execute.
//
// The refusal text is the generic "the transaction is stopped" a guarded Codeunit.Run is refused
// with. The tests are declaration-ordered and share a codeunit. Test01 clears every key this
// codeunit writes and Test14 clears them again, both without an attribute so the platform commits
// the deletes at the test boundary — Test07 commits a row on purpose.
//
// Handler proof is carried on codeunit globals: a [RequestPageHandler] body may not write.
codeunit 60029 "Test TxModel Report Exec"
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
        ALTBase.Name := 'txexec-probe';
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
        ALTBase.SetRange("Entry No.", 60029000, 60029999);
        ALTBase.DeleteAll();
    end;

    [Test]
    procedure TxReportExec_Test01_ClearsTheKeys()
    var
        ALTBase: Record "ALT Base";
    begin
        ClearKeys();
        ALTBase.SetRange("Entry No.", 60029000, 60029999);
        Assert.AreEqual(0, ALTBase.Count(), 'No probe row may exist before the tests below write them.');
    end;

    [Test]
    procedure TxReportExec_Test02_RunRequestPageWithPendingWriteIsRefused()
    var
        ReqPage: Report "TxExec ReqPage Marker";
        Parameters: Text;
    begin
        InsertBase(60029021);

        // No [HandlerFunctions]: the refusal comes before the request page is shown.
        asserterror Parameters := ReqPage.RunRequestPage();
        Assert.ExpectedError('the transaction is stopped');

        Assert.IsFalse(BaseExists(60029021), 'The trapped refusal must roll back the pending write that caused it.');
    end;

    [Test]
    procedure TxReportExec_Test03_StaticRunRequestPageWithPendingWriteIsRefused()
    var
        Parameters: Text;
    begin
        InsertBase(60029031);

        asserterror Parameters := Report.RunRequestPage(Report::"TxExec ReqPage Marker");
        Assert.ExpectedError('the transaction is stopped');

        Assert.IsFalse(BaseExists(60029031), 'The trapped refusal must roll back the pending write that caused it.');
    end;

    [Test]
    [HandlerFunctions('ConfirmRequestPageHandler')]
    procedure TxReportExec_Test04_RunRequestPageWithoutPendingWriteShowsTheRequestPage()
    var
        ReqPage: Report "TxExec ReqPage Marker";
        Parameters: Text;
    begin
        RequestPageHandled := false;

        Parameters := ReqPage.RunRequestPage();

        Assert.IsTrue(RequestPageHandled, 'The [RequestPageHandler] must have run.');
        Assert.AreNotEqual('', Parameters, 'An OK-ed request page must return its parameters.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmRequestPageHandler')]
    procedure TxReportExec_Test05_AutoRollbackRunRequestPageWithPendingWriteRuns()
    var
        ReqPage: Report "TxExec ReqPage Marker";
        Parameters: Text;
    begin
        RequestPageHandled := false;
        InsertBase(60029051);

        Parameters := ReqPage.RunRequestPage();

        Assert.IsTrue(RequestPageHandled, 'The [RequestPageHandler] must have run.');
        Assert.AreNotEqual('', Parameters, 'An OK-ed request page must return its parameters.');
        Assert.IsTrue(BaseExists(60029051), 'The write made before the request page must still be readable.');
    end;

    [Test]
    procedure TxReportExec_Test06_ExecuteUpdateReportWithPendingWriteIsRefused()
    var
        UpdateRpt: Report "TxExec Update Marker";
    begin
        InsertBase(60029061);

        UpdateRpt.SetMarker(60029062);
        asserterror UpdateRpt.Execute('');
        Assert.ExpectedError('the transaction is stopped');

        Assert.IsFalse(BaseExists(60029062), 'A refused report must not have run its body.');
        Assert.IsFalse(BaseExists(60029061), 'The trapped refusal must roll back the pending write that caused it.');
    end;

    [Test]
    procedure TxReportExec_Test07_ExecuteUpdateReportCommitsItsOwnWrites()
    var
        UpdateRpt: Report "TxExec Update Marker";
    begin
        UpdateRpt.SetMarker(60029071);
        UpdateRpt.Execute('');

        Assert.IsTrue(BaseExists(60029071), 'The report body must have run and written its marker row.');

        InsertBase(60029072);

        asserterror Error('txexec update probe');
        Assert.ExpectedError('txexec update probe');

        Assert.IsTrue(BaseExists(60029071),
            'Execute on a report whose TransactionType differs from the session''s commits its own writes, so a later trapped error must not roll them back.');
        Assert.IsFalse(BaseExists(60029072),
            'A write the caller makes AFTER the report returns is uncommitted again and must be rolled back.');
    end;

    [Test]
    procedure TxReportExec_Test08_ExecutePlainReportWithPendingWriteRunsAndIsNotACommit()
    var
        Plain: Report "TxExec Plain Marker";
    begin
        InsertBase(60029081);

        Plain.SetMarker(60029082);
        Plain.Execute('');

        Assert.IsTrue(BaseExists(60029082), 'The report body must have run and written its marker row.');

        asserterror Error('txexec plain probe');
        Assert.ExpectedError('txexec plain probe');

        Assert.IsFalse(BaseExists(60029081), 'Execute on a plain report is not a commit point: the prior write must be rolled back.');
        Assert.IsFalse(BaseExists(60029082), 'The report''s own write joined the caller''s transaction and must be rolled back with it.');
    end;

    [Test]
    procedure TxReportExec_Test09_ExecuteRequestPageReportWithPendingWriteRunsAndIsNotACommit()
    var
        ReqPage: Report "TxExec ReqPage Marker";
    begin
        InsertBase(60029091);

        // Execute never shows the request page, so a report that has one does not enter a
        // transaction world through it. No [HandlerFunctions] for the same reason.
        ReqPage.SetMarker(60029092);
        ReqPage.Execute('');

        Assert.IsTrue(BaseExists(60029092), 'The report body must have run and written its marker row.');

        asserterror Error('txexec reqpage probe');
        Assert.ExpectedError('txexec reqpage probe');

        Assert.IsFalse(BaseExists(60029091), 'Execute is not a commit point here: the prior write must be rolled back.');
        Assert.IsFalse(BaseExists(60029092), 'The report''s own write must be rolled back with the caller''s transaction.');
    end;

    [Test]
    procedure TxReportExec_Test10_StaticExecuteUpdateReportWithPendingWriteIsRefused()
    begin
        InsertBase(60029101);

        // A static Execute builds its own instance, so the report writes its default key 60029991.
        asserterror Report.Execute(Report::"TxExec Update Marker", '');
        Assert.ExpectedError('the transaction is stopped');

        Assert.IsFalse(BaseExists(60029991), 'A refused report must not have run its body.');
        Assert.IsFalse(BaseExists(60029101), 'The trapped refusal must roll back the pending write that caused it.');
    end;

    [Test]
    procedure TxReportExec_Test11_PrintUpdateReportWithPendingWriteIsRefused()
    var
        UpdateRpt: Report "TxExec Update Marker";
    begin
        InsertBase(60029111);

        UpdateRpt.SetMarker(60029112);
        asserterror UpdateRpt.Print('');
        Assert.ExpectedError('the transaction is stopped');

        Assert.IsFalse(BaseExists(60029112), 'A refused report must not have run its body.');
        Assert.IsFalse(BaseExists(60029111), 'The trapped refusal must roll back the pending write that caused it.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TxReportExec_Test12_AutoRollbackExecuteUpdateReportWithPendingWriteRuns()
    var
        UpdateRpt: Report "TxExec Update Marker";
    begin
        InsertBase(60029121);

        UpdateRpt.SetMarker(60029122);
        UpdateRpt.Execute('');

        Assert.IsTrue(BaseExists(60029122), 'The report body must have run and written its marker row.');
        Assert.IsTrue(BaseExists(60029121), 'The write made before the report must still be readable.');
    end;

    [Test]
    procedure TxReportExec_Test13_AutoRollbackExecuteCommittedNothing()
    begin
        Assert.IsFalse(BaseExists(60029121), 'Under AutoRollback Execute is not a commit: the previous test''s prior write must be rolled back.');
        Assert.IsFalse(BaseExists(60029122), 'Under AutoRollback Execute is not a commit: the previous test''s report write must be rolled back.');
    end;

    [Test]
    procedure TxReportExec_Test14_ClearsTheKeysAgain()
    var
        ALTBase: Record "ALT Base";
    begin
        ClearKeys();
        ALTBase.SetRange("Entry No.", 60029000, 60029999);
        Assert.AreEqual(0, ALTBase.Count(), 'The rows Test07 committed must be removable.');
    end;

    [RequestPageHandler]
    procedure ConfirmRequestPageHandler(var RequestPage: TestRequestPage "TxExec ReqPage Marker")
    begin
        RequestPageHandled := true;
        RequestPage.OK().Invoke();
    end;
}
