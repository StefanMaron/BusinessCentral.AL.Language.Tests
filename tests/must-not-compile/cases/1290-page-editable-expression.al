// @expect AL0220 | Syntax error, boolean literal expected. Use 'true' or 'false'.
// A page's own Editable property set to a page variable. Part, repeater and field controls accept an expression (pages/lt-be-part-editable-expr); the page property takes only a literal.
table 51290 "MNC BE T1290"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51290 "MNC BE P1290"
{
    PageType = ListPart;
    SourceTable = "MNC BE T1290";
    Editable = PageFlag;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
            }
        }
    }

    var
        PageFlag: Boolean;
}
