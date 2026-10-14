// @expect AL0162 | 'OnFindRecord' is not a valid trigger
// A page extension declares OnFindRecord (a page has it, a page extension does not).
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50001 "MNC Base Page"
{
    PageType = List;
    SourceTable = "MNC Table";
}

pageextension 50002 "MNC Base Page Ext" extends "MNC Base Page"
{
    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(true);
    end;
}
