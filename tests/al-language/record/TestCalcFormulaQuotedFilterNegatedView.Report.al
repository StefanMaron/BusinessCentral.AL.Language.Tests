// Support report for TestCalcFormulaQuotedFilterTests.Codeunit.al.
//
// The DataItemTableView half of the same claim, in the exact shape Base Application's
// Report 321 "Vendor - Balance to Date" writes it:
//     where("Entry Type" = filter(<> "Initial Entry"))
// A quoted AL identifier inside filter(), negated.
report 60306 "CFQ Negated View Report"
{
    Caption = 'CFQ Negated View Report';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Lines; "CFQ Line")
        {
            DataItemTableView = sorting("Entry No.") where("Entry Type" = filter(<> "Initial Entry"));

            trigger OnAfterGetRecord()
            var
                LogRec: Record "CFQ Log";
            begin
                LogRec.Log('negated');
            end;
        }
    }
}
