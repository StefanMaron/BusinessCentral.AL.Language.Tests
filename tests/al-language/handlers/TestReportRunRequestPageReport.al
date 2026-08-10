// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-runrequestpage-method
// Scope: in-scope
// Fixtures used: Test Rpt RunReqPage Row (60541), Test Rpt RunReqPage Log (60542)
//
// A report with a real request page carrying one editable field. ProcessingOnly so
// nothing about rendering can influence the result — the whole claim is about the
// request page being routed to its handler.

report 60543 "Test Rpt RunReqPage Report"
{
    Caption = 'Test Rpt RunReqPage Report';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Rows; "Test Rpt RunReqPage Row")
        {
            trigger OnAfterGetRecord()
            begin
                RowCount += 1;
            end;
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
                    field(EchoText; EchoText)
                    {
                        ApplicationArea = All;
                        Caption = 'Echo Text';
                        ToolTip = 'Value the handler sets, echoed back to the test.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        var
            LogRec: Record "Test Rpt RunReqPage Log";
        begin
            LogRec.Log('rp-open');
        end;
    }

    var
        RowCount: Integer;
        EchoText: Text[50];

    procedure GetEchoText(): Text[50]
    begin
        exit(EchoText);
    end;

    procedure RowsProcessed(): Integer
    begin
        exit(RowCount);
    end;
}
