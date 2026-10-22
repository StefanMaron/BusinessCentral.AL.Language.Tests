// @expect AL0322 | Procedure calls is not valid for client expressions.
// Corpus issue #668 item 108: a page extension modify() of a base field control may set Editable to a constant or to a Boolean variable,
// not to a procedure call.
table 51503 "MNC BS Edit"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 51503 "MNC BS Edit Card"
{
    PageType = Card;
    SourceTable = "MNC BS Edit";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(A; Rec.A) { }
        }
    }

    procedure IsOk(): Boolean
    begin
        exit(true);
    end;
}

pageextension 51503 "MNC BS Edit Card Ext" extends "MNC BS Edit Card"
{
    layout
    {
        modify(Id) { Editable = Y; }
        modify(A) { Editable = IsOk(); }
    }

    var
        Y: Boolean;
}
