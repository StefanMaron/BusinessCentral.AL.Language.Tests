// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Y Helper (75500), LT Y Seen (75501), YRequestPage.al (table 75530, reports 75531-75540)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced.
// Facts: see YRequestPage.al.
// BC versions: 27-29

codeunit 75512 "LT Y Request Page Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y Helper";
        Seen: Codeunit "LT Y Seen";

    local procedure Seed()
    var
        Line: Record "LT Y Line";
    begin
        Line.DeleteAll();
        Seen.Reset();
        InsertLine('A', 10000, 'first');
        InsertLine('A', 20000, 'second');
        InsertLine('B', 10000, 'other');
    end;

    local procedure InsertLine(DocNo: Code[10]; LineNo: Integer; Descr: Text[30])
    var
        Line: Record "LT Y Line";
    begin
        Line.Init();
        Line.DocNo := DocNo;
        Line.LineNo := LineNo;
        Line.Descr := Descr;
        Line.Insert();
    end;

    local procedure Rows(): Text
    var
        Line: Record "LT Y Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line.DocNo + '/' + Format(Line.LineNo) + '/' + Line.Descr + ';';
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure ObserveSeen(var Observer: Codeunit "Probe Observer"; Names: Text)
    var
        Name: Text;
    begin
        foreach Name in Names.Split(',') do
            Observer.Observe(Name, Seen.Get(Name));
    end;

    // ---- SourceTableView

    [RequestPageHandler]
    procedure ViewHandler(var RP: TestRequestPage "LT Y RP View")
    begin
        Seen.Put('caption', RP.Caption());
        Seen.Put('docno', RP.DocNoCtl.Value());
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('ViewHandler')]
    procedure SourceTableView_RequestPageRecord_HasTheView()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP View");
        ObserveSeen(Observer, 'view,filters,count,temporary,caption,docno');
        Observer.Finish();
    end;

    // ---- SourceTableTemporary

    [RequestPageHandler]
    procedure TempHandler(var RP: TestRequestPage "LT Y RP Temp")
    begin
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('TempHandler')]
    procedure SourceTableTemporary_RequestPageRecords_AreNotStored()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Temp");
        ObserveSeen(Observer, 'temporary,count_before,count_after');
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    // ---- DeleteAllowed / ModifyAllowed

    [TryFunction]
    local procedure TryModifyLocked(var RP: TestRequestPage "LT Y RP Locked")
    begin
        RP.DescrCtl.SetValue('changed');
    end;

    [TryFunction]
    local procedure TryNewLocked(var RP: TestRequestPage "LT Y RP Locked")
    begin
        RP.New();
    end;

    [RequestPageHandler]
    procedure LockedHandler(var RP: TestRequestPage "LT Y RP Locked")
    begin
        Seen.Put('caption', RP.Caption());
        Seen.Put('docno', RP.DocNoCtl.Value());
        Seen.Put('editable', Format(RP.DescrCtl.Editable()));
        if TryModifyLocked(RP) then
            Seen.Put('modify', 'ok ' + RP.DescrCtl.Value())
        else
            Seen.Put('modify', Helper.Failed());
        if TryNewLocked(RP) then
            Seen.Put('new', 'ok')
        else
            Seen.Put('new', Helper.Failed());
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('LockedHandler')]
    procedure DeleteAllowedModifyAllowed_False_Refuse()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Locked");
        ObserveSeen(Observer, 'caption,docno,editable,modify,new');
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryModifyOpen(var RP: TestRequestPage "LT Y RP Open")
    begin
        RP.DescrCtl.SetValue('changed');
    end;

    [TryFunction]
    local procedure TryNewOpen(var RP: TestRequestPage "LT Y RP Open")
    begin
        RP.New();
    end;

    [RequestPageHandler]
    procedure OpenHandler(var RP: TestRequestPage "LT Y RP Open")
    begin
        Seen.Put('caption', RP.Caption());
        Seen.Put('docno', RP.DocNoCtl.Value());
        Seen.Put('editable', Format(RP.DescrCtl.Editable()));
        if TryModifyOpen(RP) then
            Seen.Put('modify', 'ok ' + RP.DescrCtl.Value())
        else
            Seen.Put('modify', Helper.Failed());
        if TryNewOpen(RP) then
            Seen.Put('new', 'ok')
        else
            Seen.Put('new', Helper.Failed());
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('OpenHandler')]
    procedure DeleteAllowedModifyAllowed_True_Succeed()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Open");
        ObserveSeen(Observer, 'caption,docno,editable,modify,new');
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    // ---- DataCaptionFields / DataCaptionExpression

    [RequestPageHandler]
    procedure CaptionFieldsHandler(var RP: TestRequestPage "LT Y RP Caption Fields")
    begin
        Seen.Put('caption', RP.Caption());
        RP.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure CaptionExprHandler(var RP: TestRequestPage "LT Y RP Caption Expr")
    begin
        Seen.Put('caption', RP.Caption());
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('CaptionFieldsHandler')]
    procedure DataCaptionFields_RequestPage_Caption()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Caption Fields");
        ObserveSeen(Observer, 'caption');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CaptionExprHandler')]
    procedure DataCaptionExpression_RequestPage_Caption()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Caption Expr");
        ObserveSeen(Observer, 'caption');
        Observer.Finish();
    end;

    // ---- AutoSplitKey / MultipleNewLines

    [TryFunction]
    local procedure TryNewLines(var RP: TestRequestPage "LT Y RP Split")
    begin
        RP.GoToKey('A', 10000);
        RP.New();
        RP.DocNoCtl.SetValue('A');
        RP.DescrCtl.SetValue('inserted 1');
        Seen.Put('first_key', RP.LineNoCtl.Value());
        RP.New();
        RP.DocNoCtl.SetValue('A');
        RP.DescrCtl.SetValue('inserted 2');
        Seen.Put('second_key', RP.LineNoCtl.Value());
    end;

    [RequestPageHandler]
    procedure SplitHandler(var RP: TestRequestPage "LT Y RP Split")
    begin
        if TryNewLines(RP) then
            Seen.Put('new', 'ok')
        else
            Seen.Put('new', Helper.Failed());
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SplitHandler')]
    procedure AutoSplitKey_NewLineBetweenLines_GetsSplitKey()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Split");
        ObserveSeen(Observer, 'new,first_key,second_key');
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryNewLinesNoSplit(var RP: TestRequestPage "LT Y RP NoSplit")
    begin
        RP.GoToKey('A', 10000);
        RP.New();
        RP.DocNoCtl.SetValue('A');
        RP.DescrCtl.SetValue('inserted 1');
        Seen.Put('first_key', RP.LineNoCtl.Value());
        RP.New();
        RP.DocNoCtl.SetValue('A');
        RP.DescrCtl.SetValue('inserted 2');
        Seen.Put('second_key', RP.LineNoCtl.Value());
    end;

    [RequestPageHandler]
    procedure NoSplitHandler(var RP: TestRequestPage "LT Y RP NoSplit")
    begin
        if TryNewLinesNoSplit(RP) then
            Seen.Put('new', 'ok')
        else
            Seen.Put('new', Helper.Failed());
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('NoSplitHandler')]
    procedure AutoSplitKey_NotSet_NewLineHasNoSplitKey()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP NoSplit");
        ObserveSeen(Observer, 'new,first_key,second_key');
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    // ---- CardPageId, LinksAllowed, PopulateAllFields, HelpLink

    [RequestPageHandler]
    procedure MiscHandler(var RP: TestRequestPage "LT Y RP Misc")
    begin
        Seen.Put('caption', RP.Caption());
        Seen.Put('docno', RP.DocNoCtl.Value());
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('MiscHandler')]
    procedure CardPageIdLinksAllowedPopulateAllFields_RequestPage_Opens()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Misc");
        ObserveSeen(Observer, 'caption,docno');
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure LinksHandler(var RP: TestRequestPage "LT Y RP Links")
    begin
        Seen.Put('caption', RP.Caption());
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('LinksHandler')]
    procedure LinksAllowed_True_RequestPage_Opens()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Links");
        ObserveSeen(Observer, 'caption');
        Observer.Finish();
    end;

    [Test]
    procedure RequestPageReports_MetadataRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('misc', Helper.RowOf(2000000139, 1, Report::"LT Y RP Misc"));
        Observer.Observe('misc_items', Helper.DataItemRows(Report::"LT Y RP Misc"));
        Observer.Finish();
    end;
}
