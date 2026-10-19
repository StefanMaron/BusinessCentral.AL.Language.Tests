// @expect AL0118 | The name 'NoSuchProcedure' does not exist in the current context.
// A bare call of an unknown procedure inside a page extension trigger.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50001 "MNC Base Page"
{
    PageType = Card;
    SourceTable = "MNC Table";
}

pageextension 50002 "MNC Base Page Ext" extends "MNC Base Page"
{
    trigger OnOpenPage()
    begin
        NoSuchProcedure();
    end;
}
