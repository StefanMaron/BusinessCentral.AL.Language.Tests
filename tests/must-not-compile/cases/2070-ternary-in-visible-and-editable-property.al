// @expect AL0322 | ConditionalOperator is not valid for client expressions. Client expressions can only use simple data types and field references.
// @expect AL0322 | ConditionalOperator is not valid for client expressions. Client expressions can only use simple data types and field references.
// Writer QW (corpus issue 685): a conditional expression in a Visible or Editable property of a page control does not compile. As the source
// expression of a page field it compiles (tests/al-language/types/lt-qw-ternary/QwTernaryHelpers.al).
table 52072 "MNC QW Tern Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Flag; Boolean) { }
        field(3; Name; Text[30]) { }
    }
}

page 52073 "MNC QW Tern Card"
{
    PageType = Card;
    SourceTable = "MNC QW Tern Row";

    layout
    {
        area(Content)
        {
            field(NameCtl; Rec.Name)
            {
                Visible = ShowAll ? true : ShowName;
                Editable = Rec.Flag ? false : true;
            }
        }
    }

    var
        ShowAll: Boolean;
        ShowName: Boolean;
}
