// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-isolated-storage
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-integer-table-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT CU Row (85300), LT CU Other (85301), LT CU Row List (85302), LT CU Inserter (85303),
//   LT CU TableNo Run (85305), LT CU Report (85306)
// Corpus #670 items 37, 42, 45: what IsolatedStorage.Set leaves behind for Page.RunModal, a guarded Codeunit.Run and Report.RunModal;
// Codeunit.Run of a TableNo codeunit with a record of another table, and by an unknown name; Report.Run with a request page right after a write.
// BC versions: 27.5, 28.5, 29.0

codeunit 85312 "LT CU Write Tx Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerLog: Text;

    local procedure Initialize()
    var
        Row: Record "LT CU Row";
    begin
        Row.DeleteAll();
        Commit();
        ClearLastError();
        HandlerLog := '';
    end;

    local procedure Rows(): Text
    var
        Row: Record "LT CU Row";
        Ids: Text;
    begin
        if Row.FindSet() then
            repeat
                Ids += Format(Row.Id) + ';';
            until Row.Next() = 0;
        exit('[' + Ids + ']');
    end;

    local procedure InsertPending(Id: Integer)
    var
        Row: Record "LT CU Row";
    begin
        Row.Id := Id;
        Row.Insert();
    end;

    [ModalPageHandler]
    procedure RowListHandler(var Page: TestPage "LT CU Row List")
    begin
        HandlerLog += 'modal;';
        Page.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ReportHandler(var RequestPage: TestRequestPage "LT CU Report")
    begin
        HandlerLog += 'requestpage;';
        RequestPage.OK().Invoke();
    end;

    // ---------------------------------------------------------------- item 37
    [Test]
    [HandlerFunctions('RowListHandler')]
    procedure IsolatedStorageSet_ThenPageRunModal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        IsolatedStorage.Set('LTCU_w1', 'v', DataScope::User);
        Page.RunModal(Page::"LT CU Row List");
        Observer.Observe('handler', HandlerLog);
        IsolatedStorage.Delete('LTCU_w1', DataScope::User);
        Observer.Finish();
    end;

    [Test]
    procedure IsolatedStorageSet_ThenGuardedCodeunitRun_User()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize();
        IsolatedStorage.Set('LTCU_w2', 'v', DataScope::User);
        Ok := Codeunit.Run(Codeunit::"LT CU Inserter");
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('rows', Rows());
        IsolatedStorage.Delete('LTCU_w2', DataScope::User);
        Observer.Finish();
    end;

    [Test]
    procedure IsolatedStorageSet_ThenGuardedCodeunitRun_Module()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize();
        IsolatedStorage.Set('LTCU_w3', 'v', DataScope::Module);
        Ok := Codeunit.Run(Codeunit::"LT CU Inserter");
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('rows', Rows());
        IsolatedStorage.Delete('LTCU_w3', DataScope::Module);
        Observer.Finish();
    end;

    [Test]
    procedure IsolatedStorageSet_ThenGuardedCodeunitRun_Company()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize();
        IsolatedStorage.Set('LTCU_w4', 'v', DataScope::Company);
        Ok := Codeunit.Run(Codeunit::"LT CU Inserter");
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('rows', Rows());
        IsolatedStorage.Delete('LTCU_w4', DataScope::Company);
        Observer.Finish();
    end;

    [Test]
    procedure IsolatedStorageSet_ThenGuardedCodeunitRun_CompanyAndUser()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize();
        IsolatedStorage.Set('LTCU_w5', 'v', DataScope::CompanyAndUser);
        Ok := Codeunit.Run(Codeunit::"LT CU Inserter");
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('rows', Rows());
        IsolatedStorage.Delete('LTCU_w5', DataScope::CompanyAndUser);
        Observer.Finish();
    end;

    [Test]
    procedure IsolatedStorageSet_Commit_ThenGuardedCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize();
        IsolatedStorage.Set('LTCU_w6', 'v', DataScope::User);
        Commit();
        Ok := Codeunit.Run(Codeunit::"LT CU Inserter");
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('rows', Rows());
        IsolatedStorage.Delete('LTCU_w6', DataScope::User);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReportHandler')]
    procedure IsolatedStorageSet_ThenReportRunModal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        IsolatedStorage.Set('LTCU_w7', 'v', DataScope::User);
        Report.RunModal(Report::"LT CU Report", true);
        Observer.Observe('handler', HandlerLog);
        Observer.Observe('rows', Rows());
        IsolatedStorage.Delete('LTCU_w7', DataScope::User);
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- item 42
    [Test]
    procedure CodeunitRun_TableNo_RecordOfAnotherTable()
    var
        Observer: Codeunit "Probe Observer";
        Other: Record "LT CU Other";
    begin
        Initialize();
        Other.Id := 1;
        asserterror Codeunit.Run(Codeunit::"LT CU TableNo Run", Other);
        Observer.ObserveError('statement');
        Observer.Finish();
    end;

    [Test]
    procedure CodeunitRun_TableNo_RecordOfAnotherTable_Guarded()
    var
        Observer: Codeunit "Probe Observer";
        Other: Record "LT CU Other";
        Ok: Boolean;
    begin
        Initialize();
        Other.Id := 1;
        Ok := Codeunit.Run(Codeunit::"LT CU TableNo Run", Other);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('guarded');
        Observer.Finish();
    end;

#if BC28PLUS
    [Test]
    procedure CodeunitRun_ByName()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CU Row";
    begin
        Initialize();
        Row.Id := 1;
        Codeunit.Run('LT CU TableNo Run', Row);
        Observer.Observe('known name', Row.Name);
        asserterror Codeunit.Run('LT CU No Such Codeunit', Row);
        Observer.ObserveError('unknown name');
        Observer.Finish();
    end;
#endif

    // ---------------------------------------------------------------- item 45
    [Test]
    [HandlerFunctions('ReportHandler')]
    procedure ReportRun_RequestPage_AfterWrite()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CU Row";
    begin
        Initialize();
        InsertPending(1);
        Row.SetRange(Id, 1);
        Report.Run(Report::"LT CU Report", true, true, Row);
        Observer.Observe('handler', HandlerLog);
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure ReportRun_NoRequestPage_AfterWrite()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CU Row";
    begin
        Initialize();
        InsertPending(1);
        Row.SetRange(Id, 1);
        Report.Run(Report::"LT CU Report", false, false, Row);
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReportHandler')]
    procedure ReportRunModal_RequestPage_AfterWrite()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CU Row";
    begin
        Initialize();
        InsertPending(1);
        Row.SetRange(Id, 1);
        Report.RunModal(Report::"LT CU Report", true, true, Row);
        Observer.Observe('handler', HandlerLog);
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;
}
