// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-report-handlers
// Scope: in-scope
// Fixtures used: report 73841 and log codeunit 73840 of lt-report-requestpage; Probe Observer (69160)
// Probe: what a [ReportHandler] function can do with the report variable it receives (Run, RunModal, UseRequestPage, SetTableView, SaveAs, RunRequestPage), each in a test of its own.
// Object id 78201.

codeunit 78201 "LT AE Report Handler Calls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        L: Codeunit "LT RpT Request Log";
        Mode: Integer;

    local procedure Seed()
    var
        Row: Record "LT RpT Row";
        I: Integer;
    begin
        Row.DeleteAll();
        L.Take();
        for I := 1 to 4 do begin
            Row.Id := I;
            Row.Grp := 1;
            Row.Insert();
        end;
        Commit();
    end;

    [ReportHandler]
    procedure CallHandler(var R: Report "LT RpT Request")
    var
        Row: Record "LT RpT Row";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Params: Text;
    begin
        L.Add('handler mode=' + Format(Mode));
        case Mode of
            1:
                begin
                    R.UseRequestPage(false);
                    R.Run();
                end;
            2:
                begin
                    R.UseRequestPage(false);
                    R.RunModal();
                end;
            3:
                begin
                    Row.SetFilter(Id, '2..3');
                    R.SetTableView(Row);
                    R.UseRequestPage(false);
                    R.Run();
                end;
            4:
                begin
                    TempBlob.CreateOutStream(OutS);
                    R.SaveAs('', ReportFormat::Xml, OutS);
                    L.Add('saved length>0=' + Format(TempBlob.Length() > 0));
                end;
            5:
                begin
                    Params := R.RunRequestPage();
                    L.Add('params=[' + Params + ']');
                end;
            6:
                L.Add('use request page=' + Format(R.UseRequestPage()));
            7:
                Error('LT AE handler error');
        end;
    end;

    [Test]
    [HandlerFunctions('CallHandler')]
    procedure Handler_RunsReport()
    begin
        Seed();
        Mode := 1;
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CallHandler')]
    procedure Handler_RunsReportModal()
    begin
        Seed();
        Mode := 2;
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CallHandler')]
    procedure Handler_SetTableViewAndRun()
    begin
        Seed();
        Mode := 3;
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CallHandler')]
    procedure Handler_SaveAs()
    begin
        Seed();
        Mode := 4;
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CallHandler')]
    procedure Handler_RunRequestPage()
    begin
        Seed();
        Mode := 5;
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CallHandler')]
    procedure Handler_UseRequestPageGetter()
    begin
        Seed();
        Mode := 6;
        Report.Run(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CallHandler')]
    procedure Handler_RaisesError()
    begin
        Seed();
        Mode := 7;
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;
}
