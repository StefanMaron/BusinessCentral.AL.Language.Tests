// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-wordmergedataitem-property
// Scope: in-scope
// Fixtures used: Test Rpt Meta Cols Sample (60359)
//
// Fixture report for the Report Metadata (2000000139) / Report Data Items (2000000203)
// column tests. Every property here is declared to a value that is NOT the platform default,
// so a test reading the column back cannot pass against an implementation that answers a
// default or a hardcode:
//
//   ProcessingOnly     = false  (a report that renders, so "always processing-only" is wrong)
//   WordMergeDataItem  = Src    (non-empty, so an empty-string answer is wrong)
//   DataItemTableView  sorted DESCENDING on a named key, so the direction is observable
//   RequestFilterFields names field 2, not field 1, so "the first field" is not the answer

report 60360 "Test Rpt Meta Cols Fixture"
{
    UsageCategory = None;
    ProcessingOnly = false;
    WordMergeDataItem = Src;

    dataset
    {
        dataitem(Src; "Test Rpt Meta Cols Sample")
        {
            DataItemTableView = sorting("Entry No.") order(descending);
            RequestFilterFields = Description;

            column(EntryNo; "Entry No.") { }
            column(SampleDescription; Description) { }

            dataitem(Child; "Test Rpt Meta Cols Sample")
            {
                DataItemLink = "Entry No." = field("Entry No.");
                column(ChildEntryNo; "Entry No.") { }
            }
        }
    }
}
