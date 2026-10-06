// PROBE (record-only). Every test ends in Error(<observations>) so the log of a real service tier
// carries what BC answered. Replaced by final assertions once measured.
// Written by agent stma-auto-8 (Claude agent), an automated implementation agent acting on the
// account holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4919.

report 68660 "RPN Report"
{
    Caption = 'RPN Report';
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(RpnTextCtl; RpnText)
                {
                    ApplicationArea = All;
                    Caption = 'Rpn Text Caption';
                }
                field(RpnFlagCtl; RpnFlag)
                {
                    ApplicationArea = All;
                    Caption = 'Rpn Flag Caption';
                }
            }
        }
    }

    trigger OnInitReport()
    begin
        RpnText := 'Delta';
        RpnFlag := false;
    end;

    var
        RpnText: Text[30];
        RpnFlag: Boolean;
}

reportextension 68660 "RPN Report Ext" extends "RPN Report"
{
    requestpage
    {
        layout
        {
            addlast(Content)
            {
                field(RpnExtCtl; RpnExtVar)
                {
                    ApplicationArea = All;
                    Caption = 'Rpn Ext Caption';
                }
            }
        }
    }

    var
        RpnExtVar: Text[30];
}

reportextension 68661 "RPN Export Ext" extends "Export Consolidation"
{
    requestpage
    {
        layout
        {
            addlast(Content)
            {
                field(RpnExportExtCtl; RpnExportExtVar)
                {
                    ApplicationArea = All;
                    Caption = 'Rpn Export Ext Caption';
                }
            }
        }
    }

    var
        RpnExportExtVar: Text[30];
}

codeunit 68660 "RPN Request Page Control Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observed: Text;

    local procedure Capture(Label: Text)
    begin
        Observed += '[' + Label + '] ' + GetLastErrorText() + ' || ';
    end;

    [Test]
    [HandlerFunctions('SourceHandler')]
    procedure Probe_SourceReport()
    begin
        Observed := '';
        Report.Run(Report::"RPN Report");
        Error('PROBE source: ' + Observed);
    end;

    [Test]
    [HandlerFunctions('ExportHandler')]
    procedure Probe_PrecompiledReport91()
    begin
        Observed := '';
        Report.Run(Report::"Export Consolidation");
        Error('PROBE report91: ' + Observed);
    end;

    [Test]
    [HandlerFunctions('ExtHandler')]
    procedure Probe_PrecompiledReportExtension5803()
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        Observed := '';
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Manufacturing');
        Parameters := Report.RunRequestPage(Report::"Reset Cost Is Adjusted");
        ApplicationArea(PreviousAreas);
        Error('PROBE ext5803: ' + Observed);
    end;

    [RequestPageHandler]
    procedure SourceHandler(var RequestPage: TestRequestPage "RPN Report")
    begin
        asserterror RequestPage.RpnTextCtl.AssertEquals('Wrong');
        Capture('text-wrong');
        Observed += '[text-value] ' + RequestPage.RpnTextCtl.Value() + ' || ';
        ClearLastError();
        RequestPage.RpnTextCtl.AssertEquals('Delta');
        Observed += '[text-match] raised nothing || ';
        asserterror RequestPage.RpnFlagCtl.AssertEquals('Yes');
        Capture('flag-wrong');
        asserterror RequestPage.RpnFlagCtl.SetValue('Maybe');
        Capture('flag-setvalue-maybe');
        asserterror RequestPage.RpnExtCtl.AssertEquals('Wrong');
        Capture('ext-wrong');
        RequestPage.RpnExtCtl.SetValue('Eps');
        RequestPage.RpnExtCtl.AssertEquals('Eps');
        Observed += '[ext-match] raised nothing || ';
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ExportHandler(var RequestPage: TestRequestPage "Export Consolidation")
    begin
        Observed += '[name-value] ' + RequestPage.ClientFileNameControl.Value() + ' || ';
        Observed += '[format-value] ' + RequestPage.FileFormat.Value() + ' || ';
        asserterror RequestPage.ClientFileNameControl.AssertEquals('Wrong');
        Capture('name-wrong');
        asserterror RequestPage.FileFormat.AssertEquals('Wrong');
        Capture('format-wrong');
        asserterror RequestPage.FileFormat.SetValue('Not A Format');
        Capture('format-setvalue-bad');
        ClearLastError();
        RequestPage.ClientFileNameControl.AssertEquals(RequestPage.ClientFileNameControl.Value());
        RequestPage.FileFormat.AssertEquals(RequestPage.FileFormat.Value());
        Observed += '[match] raised nothing || ';
        asserterror RequestPage.RpnExportExtCtl.AssertEquals('Wrong');
        Capture('src-ext-wrong');
        RequestPage.RpnExportExtCtl.SetValue('Zeta');
        RequestPage.RpnExportExtCtl.AssertEquals('Zeta');
        Observed += '[src-ext-match] raised nothing || ';
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ExtHandler(var RequestPage: TestRequestPage "Reset Cost Is Adjusted")
    begin
        Observed += '[flag-value] ' + RequestPage."Reset Prod. Order Costing".Value() + ' || ';
        Observed += '[no-value] ' + RequestPage."Prod. Order No.".Value() + ' || ';
        asserterror RequestPage."Reset Prod. Order Costing".AssertEquals('Wrong');
        Capture('flag-wrong');
        asserterror RequestPage."Prod. Order No.".AssertEquals('Wrong');
        Capture('no-wrong');
        asserterror RequestPage."Reset Prod. Order Costing".SetValue('Maybe');
        Capture('flag-setvalue-maybe');
        ClearLastError();
        RequestPage."Reset Prod. Order Costing".AssertEquals(RequestPage."Reset Prod. Order Costing".Value());
        RequestPage."Prod. Order No.".AssertEquals(RequestPage."Prod. Order No.".Value());
        Observed += '[match] raised nothing || ';
        RequestPage.Cancel().Invoke();
    end;
}
