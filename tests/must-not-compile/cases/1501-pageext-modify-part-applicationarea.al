// @expect AL0246 | The property 'ApplicationArea' cannot be customized.
// Corpus issue #668 item 103: a page extension cannot change ApplicationArea of a base part with modify (on a base field control it compiles).
table 51501 "MNC BS Area"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 51502 "MNC BS Area Part"
{
    PageType = ListPart;
    SourceTable = "MNC BS Area";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } } } }
}

page 51501 "MNC BS Area Card"
{
    PageType = Card;
    SourceTable = "MNC BS Area";
    layout
    {
        area(Content)
        {
            field(A; Rec.A) { }
            part(MatrixForm; "MNC BS Area Part") { }
        }
    }
}

pageextension 51501 "MNC BS Area Card Ext" extends "MNC BS Area Card"
{
    layout
    {
        modify(A) { ApplicationArea = All; }
        modify(MatrixForm) { ApplicationArea = All; }
    }
}
