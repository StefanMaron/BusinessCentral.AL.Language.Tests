// @expect AL0161 | 'SecretLocal()' is inaccessible due to its protection level
// A page extension calls a local procedure of its base page. ADR-023 probe 8.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50001 "MNC Base Page"
{
    PageType = Card;
    SourceTable = "MNC Table";

    local procedure SecretLocal(): Integer
    begin
        exit(1);
    end;
}

pageextension 50002 "MNC Base Page Ext" extends "MNC Base Page"
{
    trigger OnOpenPage()
    var
        Value: Integer;
    begin
        Value := SecretLocal();
    end;
}
