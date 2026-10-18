// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcfields-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT F3 Log Mgt (67077); F3ReportFixtures.al
// Probe: (1) data item CalcFields on a nested data item and with a list of fields; (2) a filter on the DataItemLink field set in the item's view or by the caller with SetTableView;
//        (3) ReportHandler functions with UseRequestPage(false) and (true); (4) a ProcessingOnly report with request page fields, UseRequestPage(true), Run and RunModal with no handler and with a RequestPageHandler;
//        (5) SetFilter(Field, '') on a data item of a TestRequestPage.
// Object id 67115.

codeunit 67115 "LT F3 Report Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        HandlerMode: Integer;

    [RequestPageHandler]
    procedure RequestHandler(var RequestPage: TestRequestPage "LT F3 Request Report")
    begin
        Observer.Observe('rp_tag', RequestPage.TagCtl.Value());
        case HandlerMode of
            0:
                RequestPage.OK().Invoke();
            1:
                RequestPage.Cancel().Invoke();
            2:
                begin
                    RequestPage.TagCtl.SetValue('typed');
                    RequestPage.OK().Invoke();
                end;
            3:
                begin
                    RequestPage.Parent.SetFilter("Code", 'H1|H2');
                    Observer.Observe('rp_filter_set', RequestPage.Parent.GetFilter("Code"));
                    RequestPage.Parent.SetFilter("Code", '');
                    Observer.Observe('rp_filter_cleared', RequestPage.Parent.GetFilter("Code"));
                    RequestPage.OK().Invoke();
                end;
            4:
                begin
                    RequestPage.Parent.SetFilter("Code", 'H1|H2');
                    RequestPage.OK().Invoke();
                end;
        end;
    end;

    [ReportHandler]
    procedure ReportHandlerFn(var R: Report "LT F3 Request Report")
    var
        Log: Codeunit "LT F3 Log Mgt";
    begin
        Log.Add('ReportHandler called');
    end;

    local procedure Dump(): Text
    var
        Log: Codeunit "LT F3 Log Mgt";
    begin
        exit(Log.Dump());
    end;

    [Test]
    procedure CalcFields_ListsOnParentAndNestedChild()
    var
        Data: Codeunit "LT F3 Report Data";
        Rep: Report "LT F3 CalcFields Lists";
    begin
        Data.Seed();
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('log', Dump());
        Observer.Expect('log', 'Parent H1 sum=60 count=3 | Child H1/1 descr=First sibs=3 | Child H1/2 descr=First sibs=3 | Child H1/3 descr=First sibs=3 | Parent H2 sum=12 count=2 | Child H2/1 descr=Second sibs=2 | Child H2/2 descr=Second sibs=2 | Parent H3 sum=0 count=0 | ');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFields_NoneSet()
    var
        Data: Codeunit "LT F3 Report Data";
        Rep: Report "LT F3 CalcFields None";
    begin
        Data.Seed();
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('log', Dump());
        Observer.Expect('log', 'Parent H1 sum=0 count=0 | Child H1/1 descr= sibs=0 | Child H1/2 descr= sibs=0 | Child H1/3 descr= sibs=0 | Parent H2 sum=0 count=0 | Child H2/1 descr= sibs=0 | Child H2/2 descr= sibs=0 | Parent H3 sum=0 count=0 | ');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFields_SingleFieldPerLevel()
    var
        Data: Codeunit "LT F3 Report Data";
        Rep: Report "LT F3 CalcFields Single";
    begin
        Data.Seed();
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('log', Dump());
        Observer.Expect('log', 'Parent H1 sum=60 count=0 | Child H1/1 descr= sibs=3 | Child H1/2 descr= sibs=3 | Child H1/3 descr= sibs=3 | Parent H2 sum=12 count=0 | Child H2/1 descr= sibs=2 | Child H2/2 descr= sibs=2 | Parent H3 sum=0 count=0 | ');
        Observer.Verify();
    end;

    [Test]
    procedure LinkFilter_InItemView()
    var
        Data: Codeunit "LT F3 Report Data";
        Rep: Report "LT F3 Link Filter View";
    begin
        Data.Seed();
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('log', Dump());
        Observer.Expect('log', 'Parent H1 | Child H1/1 | Child H1/2 | Child H1/3 | Parent H2 | Parent H3 | ');
        Observer.Verify();
    end;

    [Test]
    procedure LinkFilter_CallerSetTableViewOnLinkField()
    var
        Data: Codeunit "LT F3 Report Data";
        Rep: Report "LT F3 Link Filter Caller";
        Line: Record "LT F3 RLine";
    begin
        Data.Seed();
        Line.SetRange("Head Code", 'H2');
        Rep.SetTableView(Line);
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('log', Dump());
        Observer.Expect('log', 'Child filters at Parent.OnPreDataItem=[Head Code: H2] | Parent H1 child filters=[Head Code: H2] | Parent H2 child filters=[Head Code: H2] | Child H2/1 | Child H2/2 | Parent H3 child filters=[Head Code: H2] | ');
        Observer.Verify();
    end;

    [Test]
    procedure LinkFilter_CallerSetTableViewOnOtherField()
    var
        Data: Codeunit "LT F3 Report Data";
        Rep: Report "LT F3 Link Filter Caller";
        Line: Record "LT F3 RLine";
    begin
        Data.Seed();
        Line.SetFilter("Line No.", '>=2');
        Rep.SetTableView(Line);
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('log', Dump());
        Observer.Expect('log', 'Child filters at Parent.OnPreDataItem=[Line No.: >=2] | Parent H1 child filters=[Line No.: >=2] | Child H1/2 | Child H1/3 | Parent H2 child filters=[Line No.: >=2] | Child H2/2 | Parent H3 child filters=[Line No.: >=2] | ');
        Observer.Verify();
    end;

    [Test]
    procedure LinkFilter_CallerViewOverItemView()
    var
        Data: Codeunit "LT F3 Report Data";
        Rep: Report "LT F3 Link Filter View";
        Line: Record "LT F3 RLine";
    begin
        Data.Seed();
        Line.SetRange("Head Code", 'H2');
        Rep.SetTableView(Line);
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('log', Dump());
        Observer.Expect('log', 'Parent H1 | Parent H2 | Parent H3 | ');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRun(UseRequest: Boolean; Modal: Boolean)
    var
        Rep: Report "LT F3 Request Report";
    begin
        Rep.UseRequestPage(UseRequest);
        if Modal then
            Rep.RunModal()
        else
            Rep.Run();
    end;

    [TryFunction]
    local procedure TryRunStatic()
    begin
        Report.Run(Report::"LT F3 Request Report");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerFn')]
    procedure ReportHandler_NoRequestPage()
    begin
        ObserveTry('run', false, false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReportHandlerFn')]
    procedure ReportHandler_WithRequestPage()
    begin
        ObserveTry('run', true, false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReportHandlerFn')]
    procedure ReportHandler_WithRequestPage_RunModal()
    begin
        ObserveTry('runmodal', true, true);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReportHandlerFn')]
    procedure ReportHandler_ReportRunStatic()
    var
        Data: Codeunit "LT F3 Report Data";
        Ok: Boolean;
    begin
        Data.Seed();
        ClearLastError();
        Ok := TryRunStatic();
        Observer.Observe('ok', Format(Ok));
        if not Ok then begin
            Observer.Observe('error', GetLastErrorText());
            Observer.Observe('code', GetLastErrorCode());
        end;
        Observer.Observe('log', Dump());
        Observer.Finish();
    end;

    local procedure ObserveTry(Name: Text; UseRequest: Boolean; Modal: Boolean)
    var
        Data: Codeunit "LT F3 Report Data";
        Ok: Boolean;
    begin
        Data.Seed();
        ClearLastError();
        Ok := TryRun(UseRequest, Modal);
        Observer.Observe(Name + '_ok', Format(Ok));
        if not Ok then begin
            Observer.Observe(Name + '_error', GetLastErrorText());
            Observer.Observe(Name + '_code', GetLastErrorCode());
        end;
        Observer.Observe(Name + '_log', Dump());
    end;

    [Test]
    procedure RequestPageReport_UseRequestPage_NoHandler_Run()
    begin
        ObserveTry('run', true, false);
        Observer.Finish();
    end;

    [Test]
    procedure RequestPageReport_UseRequestPage_NoHandler_RunModal()
    begin
        ObserveTry('runmodal', true, true);
        Observer.Finish();
    end;

    [Test]
    procedure RequestPageReport_NoRequestPage_NoHandler()
    begin
        ObserveTry('norequest', false, false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestPageReport_Handler_OK()
    begin
        HandlerMode := 0;
        ObserveTry('ok', true, false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestPageReport_Handler_Cancel()
    begin
        HandlerMode := 1;
        ObserveTry('cancel', true, false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestPageReport_Handler_TypedTag()
    begin
        HandlerMode := 2;
        ObserveTry('typed', true, false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestPageReport_Handler_SetFilterThenEmpty()
    begin
        HandlerMode := 3;
        ObserveTry('clear', true, false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestPageReport_Handler_SetFilterKept()
    begin
        HandlerMode := 4;
        ObserveTry('kept', true, false);
        Observer.Finish();
    end;
}
