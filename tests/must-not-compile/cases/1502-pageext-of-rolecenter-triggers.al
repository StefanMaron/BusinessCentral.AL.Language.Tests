// @expect AL0378 | A page of type Role Center cannot have triggers.
// @expect AL0378 | A page of type Role Center cannot have triggers.
// @expect AL0378 | A page of type Role Center cannot have triggers.
// @expect AL0378 | A page of type Role Center cannot have triggers.
// Corpus issue #668 item 106: triggers in a page extension of a Role Center page (one diagnostic per trigger).
table 51502 "MNC BS RC Row"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 51503 "MNC BS RC Part"
{
    PageType = ListPart;
    SourceTable = "MNC BS RC Row";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } } } }
}

page 51502 "MNC BS RC"
{
    PageType = RoleCenter;
    layout { area(RoleCenter) { part(P; "MNC BS RC Part") { } } }
}

pageextension 51502 "MNC BS RC Ext" extends "MNC BS RC"
{
    trigger OnOpenPage()
    begin
    end;

    trigger OnAfterGetRecord()
    begin
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;

    trigger OnClosePage()
    begin
    end;
}
