// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
//
// Fixture table for the Report Metadata / Report Data Items column tests below. Two fields,
// because the assertions are about how BC reports a data item's table view and its request
// filter fields, and both of those are stated in terms of FIELD NUMBERS — a one-field table
// could not tell "the first field" from "field number 1".

table 60359 "Test Rpt Meta Cols Sample"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { DataClassification = CustomerContent; }
        field(2; Description; Text[50]) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
