// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-settableview-method
// Scope: in-scope
// Fixtures used: RRE Row (60866), STV Counting Report (60913)
//
// Report.SetTableView(Record) must constrain the report's matching data item to the
// filtered view before Run() executes it — not run every row in the table, and not
// silently skip execution either.
//
// Both directions, over the SAME report and SAME seeded rows, so the ONLY variable
// between the two outcomes is whether SetTableView was called:
//   * with a filtered Record  -> the data item iterates ONLY the rows within that view;
//   * with no filter at all   -> the data item iterates every row in the table.
// Without the negative case, a runner that filtered NOTHING and a runner that filtered
// correctly-but-happened-to-match-2 would be indistinguishable.

codeunit 60914 "STV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "RRE Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row.Name := 'first';
        Row.Insert();
        Row.Init();
        Row."Entry No." := 2;
        Row.Name := 'second';
        Row.Insert();
        Row.Init();
        Row."Entry No." := 3;
        Row.Name := 'third';
        Row.Insert();
    end;

    [Test]
    procedure Report_SetTableView_FiltersDataItemToTheAppliedView()
    var
        Row: Record "RRE Row";
        CountingReport: Report "STV Counting Report";
    begin
        Initialize();

        Row.SetRange("Entry No.", 1, 2);
        CountingReport.SetTableView(Row);
        CountingReport.UseRequestPage(false);
        CountingReport.Run();

        if CountingReport.GetRowCount() <> 2 then
            Error('SetTableView(1..2): expected the data item to iterate exactly 2 rows within the view, got %1', CountingReport.GetRowCount());
    end;

    [Test]
    procedure Report_Run_WithoutSetTableView_IteratesEveryRowInTheTable()
    var
        CountingReport: Report "STV Counting Report";
    begin
        // The control: same report, same 3 seeded rows, no SetTableView call at all —
        // so the data item must iterate all 3, proving the 2-row result above came
        // from the applied view rather than an implementation that always returns 2
        // (or that never applies any view and coincidentally matched).
        Initialize();

        CountingReport.UseRequestPage(false);
        CountingReport.Run();

        if CountingReport.GetRowCount() <> 3 then
            Error('No SetTableView call: expected the data item to iterate all 3 seeded rows, got %1', CountingReport.GetRowCount());
    end;
}
