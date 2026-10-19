// @expect AL0161 | 'Hidden' is inaccessible due to its protection level
// A page extension names a variable of its base page that is not protected (the default). ADR-023 probe 8.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50001 "MNC Base Page"
{
    PageType = Card;
    SourceTable = "MNC Table";

    var
        Hidden: Integer;
}

pageextension 50002 "MNC Base Page Ext" extends "MNC Base Page"
{
    trigger OnOpenPage()
    begin
        Hidden := 1;
    end;
}
