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
        CaseNo: Integer;

    local procedure Record_(Label: Text)
    begin
        Observed := '[' + Label + '] ' + GetLastErrorText();
        ClearLastError();
    end;

    local procedure RunSource(No: Integer)
    begin
        CaseNo := No;
        Observed := 'NOTHING RAN';
        Report.Run(Report::"RPN Report");
        Error('P%1 %2', No, Observed);
    end;

    local procedure RunExport(No: Integer)
    begin
        CaseNo := No;
        Observed := 'NOTHING RAN';
        Report.Run(Report::"Export Consolidation");
        Error('P%1 %2', No, Observed);
    end;

    local procedure RunExt5803(No: Integer)
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        CaseNo := No;
        Observed := 'NOTHING RAN';
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Manufacturing');
        Parameters := Report.RunRequestPage(Report::"Reset Cost Is Adjusted");
        ApplicationArea(PreviousAreas);
        Error('P%1 %2', No, Observed);
    end;

    [Test]
    [HandlerFunctions('SourceHandler')]
    procedure P01_Source_TextWrong()
    begin
        RunSource(1);
    end;

    [Test]
    [HandlerFunctions('SourceHandler')]
    procedure P02_Source_TextMatch()
    begin
        RunSource(2);
    end;

    [Test]
    [HandlerFunctions('SourceHandler')]
    procedure P03_Source_FlagWrong()
    begin
        RunSource(3);
    end;

    [Test]
    [HandlerFunctions('SourceHandler')]
    procedure P04_Source_FlagSetMaybe()
    begin
        RunSource(4);
    end;

    [Test]
    [HandlerFunctions('SourceHandler')]
    procedure P05_Source_ExtWrong()
    begin
        RunSource(5);
    end;

    [Test]
    [HandlerFunctions('ExportHandler')]
    procedure P11_Report91_NameWrong()
    begin
        RunExport(11);
    end;

    [Test]
    [HandlerFunctions('ExportHandler')]
    procedure P12_Report91_FormatWrong()
    begin
        RunExport(12);
    end;

    [Test]
    [HandlerFunctions('ExportHandler')]
    procedure P13_Report91_FormatSetBad()
    begin
        RunExport(13);
    end;

    [Test]
    [HandlerFunctions('ExportHandler')]
    procedure P14_Report91_Match()
    begin
        RunExport(14);
    end;

    [Test]
    [HandlerFunctions('ExportHandler')]
    procedure P15_Report91_SourceExtWrong()
    begin
        RunExport(15);
    end;

    [Test]
    [HandlerFunctions('ExportHandler')]
    procedure P16_Report91_SourceExtMatch()
    begin
        RunExport(16);
    end;

    [Test]
    [HandlerFunctions('Ext5803Handler')]
    procedure P21_Ext5803_FlagWrong()
    begin
        RunExt5803(21);
    end;

    [Test]
    [HandlerFunctions('Ext5803Handler')]
    procedure P22_Ext5803_NoWrong()
    begin
        RunExt5803(22);
    end;

    [Test]
    [HandlerFunctions('Ext5803Handler')]
    procedure P23_Ext5803_FlagSetMaybe()
    begin
        RunExt5803(23);
    end;

    [Test]
    [HandlerFunctions('Ext5803Handler')]
    procedure P24_Ext5803_Match()
    begin
        RunExt5803(24);
    end;

    [RequestPageHandler]
    procedure SourceHandler(var RequestPage: TestRequestPage "RPN Report")
    begin
        case CaseNo of
            1:
                begin
                    asserterror RequestPage.RpnTextCtl.AssertEquals('Wrong');
                    Record_('text-wrong');
                end;
            2:
                begin
                    RequestPage.RpnTextCtl.AssertEquals('Delta');
                    Observed := '[text-match] raised nothing, value ' + RequestPage.RpnTextCtl.Value();
                end;
            3:
                begin
                    asserterror RequestPage.RpnFlagCtl.AssertEquals('Yes');
                    Record_('flag-wrong');
                end;
            4:
                begin
                    asserterror RequestPage.RpnFlagCtl.SetValue('Maybe');
                    Record_('flag-set-maybe');
                end;
            5:
                begin
                    asserterror RequestPage.RpnExtCtl.AssertEquals('Wrong');
                    Record_('ext-wrong');
                end;
        end;
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ExportHandler(var RequestPage: TestRequestPage "Export Consolidation")
    begin
        case CaseNo of
            11:
                begin
                    asserterror RequestPage.ClientFileNameControl.AssertEquals('Wrong');
                    Record_('name-wrong');
                end;
            12:
                begin
                    asserterror RequestPage.FileFormat.AssertEquals('Wrong');
                    Record_('format-wrong');
                end;
            13:
                begin
                    asserterror RequestPage.FileFormat.SetValue('Not A Format');
                    Record_('format-set-bad');
                end;
            14:
                begin
                    RequestPage.ClientFileNameControl.AssertEquals('');
                    RequestPage.FileFormat.AssertEquals(RequestPage.FileFormat.Value());
                    Observed := '[match] raised nothing, format ' + RequestPage.FileFormat.Value();
                end;
            15:
                begin
                    asserterror RequestPage.RpnExportExtCtl.AssertEquals('Wrong');
                    Record_('src-ext-wrong');
                end;
            16:
                begin
                    RequestPage.RpnExportExtCtl.SetValue('Zeta');
                    RequestPage.RpnExportExtCtl.AssertEquals('Zeta');
                    Observed := '[src-ext-match] raised nothing';
                end;
        end;
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure Ext5803Handler(var RequestPage: TestRequestPage "Reset Cost Is Adjusted")
    begin
        case CaseNo of
            21:
                begin
                    asserterror RequestPage."Reset Prod. Order Costing".AssertEquals('Wrong');
                    Record_('flag-wrong');
                end;
            22:
                begin
                    asserterror RequestPage."Prod. Order No.".AssertEquals('Wrong');
                    Record_('no-wrong');
                end;
            23:
                begin
                    asserterror RequestPage."Reset Prod. Order Costing".SetValue('Maybe');
                    Record_('flag-set-maybe');
                end;
            24:
                begin
                    RequestPage."Reset Prod. Order Costing".AssertEquals('No');
                    RequestPage."Prod. Order No.".AssertEquals('');
                    Observed := '[match] raised nothing';
                end;
        end;
        RequestPage.Cancel().Invoke();
    end;
}
