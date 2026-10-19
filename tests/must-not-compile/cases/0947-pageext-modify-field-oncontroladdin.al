// @expect AL0162 | 'OnControlAddIn' is not a valid trigger
// A control add-in trigger of a page field cannot be added to a field through a page extension modify block: OnControlAddIn is not a valid trigger there.
table 50900 "MNC AB Table"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50901 "MNC AB Page"
{
    PageType = Card;
    SourceTable = "MNC AB Table";
    layout { area(Content) { field(Fld; Rec.Name) { ApplicationArea = All; } } }
}

pageextension 50902 "MNC AB Page Ext" extends "MNC AB Page"
{
    layout
    {
        modify(Fld)
        {
            trigger OnControlAddIn(Index: Integer; Data: Text)
            begin
            end;
        }
    }
}
