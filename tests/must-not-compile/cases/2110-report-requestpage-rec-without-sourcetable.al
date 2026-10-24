// @expect AL0118 | The name 'Rec' does not exist in the current context.
// Rec in the OnOpenPage trigger of a report request page that declares no SourceTable (with SourceTable it compiles: report/lt-y-request-page/RsRequestPageRec.al).
table 50000 "MNC RS Table"
{
    fields { field(1; Id; Integer) { } field(2; Name; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

report 50001 "MNC RS Report"
{
    ProcessingOnly = true;

    requestpage
    {
        trigger OnOpenPage()
        begin
            Rec.Modify();
        end;
    }
}
