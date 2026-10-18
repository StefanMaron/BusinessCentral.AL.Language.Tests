// @expect AL0161 | 'Rec' is inaccessible due to its protection level
// The Rec variable of the base request page is not accessible from a trigger of a request page extension (the base page's own triggers use it: report/lt-ab-request-page-triggers/ABRequestPageFixtures.al).
table 50900 "MNC AB Table"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

report 50901 "MNC AB Report"
{
    dataset { dataitem(T; "MNC AB Table") { column(Id; Id) { } } }
    requestpage
    {
        SourceTable = "MNC AB Table";
        layout { area(Content) { field(Fld; Rec.Name) { ApplicationArea = All; } } }
    }
}

reportextension 50902 "MNC AB Report Ext" extends "MNC AB Report"
{
    requestpage
    {
        trigger OnAfterGetRecord()
        var
            Nm: Text;
        begin
            Nm := Rec.Name;
        end;
    }
}
