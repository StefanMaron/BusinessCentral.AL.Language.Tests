// @expect AL0162 | 'OnFindRecord' is not a valid trigger for this object type. Check the object documentation for supported triggers.
// A request page extension refuses the trigger OnFindRecord (every other page trigger compiles there: report/lt-ab-request-page-triggers/ABRequestPageExt.al); a page extension refuses the same two (0017, 0018).
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
        trigger OnFindRecord(Which: Text): Boolean begin end;
    }
}
