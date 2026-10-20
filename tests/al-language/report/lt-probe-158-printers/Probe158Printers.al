// Windows reference probe for StefanMaron/MsDyn365Bc.On.Linux#158: does Report.RunRequestPage
// raise Reporting Triggers.SetupPrinters in this session? The test fails on purpose with the
// count, the session's client type and the printer name the request page shows, so the
// failure message is the measurement. On the Linux websocket runner (a Client Service
// session): raised once. On the Linux hub (a Web Client session): not raised.
report 97906 "BCL158 Printers"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Line; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(Quantity; Number) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(PrefixCtl; Prefix) { ApplicationArea = All; }
                }
            }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './report/lt-probe-158-printers/BCL158Printers.rdlc';
        }
    }

    var
        Prefix: Text;
}

codeunit 97907 "BCL158 Printers Log"
{
    SingleInstance = true;

    var
        Calls: Integer;

    procedure Reset()
    begin
        Calls := 0;
    end;

    procedure Count(): Integer
    begin
        exit(Calls);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SetupPrinters', '', false, false)]
    local procedure OnSetupPrinters(var Printers: Dictionary of [Text[250], JsonObject])
    begin
        Calls += 1;
    end;
}

codeunit 97908 "BCL158 Printers Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ShownPrinter: Text;

    [Test]
    [HandlerFunctions('RequestPageOk')]
    procedure P158_RunRequestPage_SetupPrinters()
    var
        PrintersLog: Codeunit "BCL158 Printers Log";
        ActiveSession: Record "Active Session";
        Parameters: Text;
    begin
        PrintersLog.Reset();
        Parameters := Report.RunRequestPage(Report::"BCL158 Printers");
        ActiveSession.SetRange("Session ID", SessionId());
        if ActiveSession.FindFirst() then;
        Error('SetupPrinters=%1 | client=%2/%3 | printer=%4', PrintersLog.Count(), ActiveSession."Client Type", CurrentClientType(), ShownPrinter);
    end;

    [RequestPageHandler]
    procedure RequestPageOk(var Request: TestRequestPage "BCL158 Printers")
    begin
        ShownPrinter := '(not read)';
        Request.OK().Invoke();
    end;
}
