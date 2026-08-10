// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-settableview-method
// Scope: in-scope
// Fixtures used: RRE Row (60866)
//
// A ProcessingOnly report over the shared "RRE Row" table, dedicated to proving
// Report.SetTableView(Record) actually constrains the data item to the view that
// was set — as opposed to running unfiltered, or not running at all.

report 60913 "STV Counting Report"
{
    Caption = 'STV Counting Report';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Rows; "RRE Row")
        {
            trigger OnAfterGetRecord()
            begin
                RowCount += 1;
            end;
        }
    }

    var
        RowCount: Integer;

    procedure GetRowCount(): Integer
    begin
        exit(RowCount);
    end;
}
