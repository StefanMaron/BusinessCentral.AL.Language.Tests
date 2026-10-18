// @expect AL0169 | The option value 'Diagonal' is not valid
// GridLayout has the values Rows and Columns (pages/lt-ab-group-properties/ABLayouts.al): any other name is refused.
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
    layout
    {
        area(Content)
        {
            grid(Ct)
            {
                GridLayout = Diagonal;
                field(Fld; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}
