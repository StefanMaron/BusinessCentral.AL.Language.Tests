// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: fixture report used by "Test Write Tx Test Boundary" (60878)
// Fixture table: ALT Universal (60000)
//
// The report arm's target, and the sibling of "ALT Run Tx None Dirty Inserter" (60880) one
// object kind over. Writes one marker row into "ALT Universal" without committing it, from
// OnPreDataItem — a report trigger, not a codeunit's OnRun — so the question the test asks is
// whether Report.Run begins a transaction of its own the way Codeunit.Run does.
//
// ProcessingOnly, so nothing is rendered and no layout is involved: the only observable is
// whether the marker row landed.
report 60412 "ALT Run Tx None Rep Inserter"
{
    Caption = 'ALT Run Tx None Rep Inserter';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Loop; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                ALTUniversal: Record "ALT Universal";
            begin
                ALTUniversal.Init();
                ALTUniversal."Entry No." := 9412;
                ALTUniversal."Text Field" := 'DIRTY-NONE-REPORT';
                ALTUniversal.Insert();
            end;
        }
    }
}
