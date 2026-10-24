// @expect AL0118 | The name 'Rec' does not exist in the current context.
// Rec in the OnPreReport trigger of a report whose request page declares no SourceTable (with SourceTable it compiles: report/lt-y-request-page/RsRequestPageRec.al, report 88562).
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
    }

    trigger OnPreReport()
    begin
        Rec.Id := 1;
    end;
}
