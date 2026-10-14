// @expect AL0440 | The Page 'MNC Base Page' already defines a method called 'Bump' with the same parameter types in 'Must Not Compile by AL Language (1.0.0.0)'.
// A page extension declares a procedure with the name and parameters of a procedure of its base page.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50001 "MNC Base Page"
{
    PageType = Card;
    SourceTable = "MNC Table";

    protected procedure Bump(): Integer
    begin
        exit(1);
    end;
}

pageextension 50002 "MNC Base Page Ext" extends "MNC Base Page"
{
    procedure Bump(): Integer
    begin
        exit(2);
    end;
}
