// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testrequestpage/testrequestpage-saveaspdf-method
// Scope: in-scope (the methods compile in a Target = Cloud app; writing the file is not asserted because a Cloud app has no File to read it back)
// Fixtures used: Probe Observer (codeunit 69160), layout file ./FixtureLayout.rdlc of the app root; self-contained report 69372, test codeunit 69373
// Facts: TestRequestPage.SaveAsExcel, SaveAsPdf and SaveAsWord called from a request page handler with a path in a folder that does not exist: the error text and code, whether the request page stays open
// afterwards, and whether the report triggers ran.
// BC versions: 27.0 and later

codeunit 69375 "LT T RP Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 69372 "LT T RP Rpt"
{
    ProcessingOnly = false;
    DefaultRenderingLayout = TRdlc;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));

            column(Num; Number) { }

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Number));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ThresholdField; Threshold)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    rendering
    {
        layout(TRdlc)
        {
            Type = RDLC;
            LayoutFile = './FixtureLayout.rdlc';
        }
    }

    var
        Threshold: Integer;
        L: Codeunit "LT T RP Log";

    trigger OnPreReport()
    begin
        L.Add('pre');
    end;

    trigger OnPostReport()
    begin
        L.Add('post');
    end;
}

codeunit 69373 "LT T RP SaveAs Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        L: Codeunit "LT T RP Log";
        Kind: Integer;

    [RequestPageHandler]
    procedure SaveHandler(var RP: TestRequestPage "LT T RP Rpt")
    begin
        RP.ThresholdField.SetValue(7);
        case Kind of
            1:
                asserterror RP.SaveAsExcel('/lt-t-no-such-folder/probe.xlsx');
            2:
                asserterror RP.SaveAsPdf('/lt-t-no-such-folder/probe.pdf');
            3:
                asserterror RP.SaveAsWord('/lt-t-no-such-folder/probe.docx');
        end;
        Observer.ObserveError('save');
        Observer.Observe('threshold after', RP.ThresholdField.Value());
        asserterror RP.Cancel().Invoke();
        Observer.ObserveError('cancel after save');
    end;

    [Test]
    [HandlerFunctions('SaveHandler')]
    procedure RequestPage_SaveAsExcel_MissingFolder()
    begin
        Kind := 1;
        L.Take();
        Report.Run(Report::"LT T RP Rpt");
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SaveHandler')]
    procedure RequestPage_SaveAsPdf_MissingFolder()
    begin
        Kind := 2;
        L.Take();
        Report.Run(Report::"LT T RP Rpt");
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SaveHandler')]
    procedure RequestPage_SaveAsWord_MissingFolder()
    begin
        Kind := 3;
        L.Take();
        Report.Run(Report::"LT T RP Rpt");
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;
}
