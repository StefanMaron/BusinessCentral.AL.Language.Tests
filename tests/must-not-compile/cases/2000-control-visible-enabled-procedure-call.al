// @expect AL0322 | Procedure calls is not valid for client expressions.
// @expect AL0322 | Procedure calls is not valid for client expressions.
// @expect AL0322 | Procedure calls is not valid for client expressions.
// AL Runner issue 3762: a field control of a page may not bind Visible, Enabled or Editable to a procedure call (on an action the same
// binding compiles with warning AL0573: tests/al-language/pages/lt-qq-procedure-bound-action).
table 52000 "MNC QQ Bound"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 52000 "MNC QQ Bound Card"
{
    PageType = Card;
    SourceTable = "MNC QQ Bound";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { Visible = IsOk(); }
            field(A; Rec.A) { Enabled = IsOk(); Editable = IsOk(); }
        }
    }

    procedure IsOk(): Boolean
    begin
        exit(true);
    end;
}
