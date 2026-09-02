// Support report for TestCalcFormulaQuotedFilterTests.Codeunit.al.
//
// The positive counterpart to "CFQ Negated View Report": a DataItemTableView whose
// filter() names a member containing parentheses, which must stay a literal rather
// than becoming grouping in the view grammar.
report 60307 "CFQ Paren View Report"
{
    Caption = 'CFQ Paren View Report';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Lines; "CFQ Line")
        {
            DataItemTableView = sorting("Entry No.") where("Entry Type" = filter("Payment Discount (VAT Excl.)"));

            trigger OnAfterGetRecord()
            var
                LogRec: Record "CFQ Log";
            begin
                LogRec.Log('paren');
            end;
        }
    }
}
