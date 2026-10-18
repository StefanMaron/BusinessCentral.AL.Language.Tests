// @expect AL0169 | The option value 'Huge' is not valid
// CuegroupLayout has one value, Wide: any other name is refused.
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
            cuegroup(Ct)
            {
                CuegroupLayout = Huge;
                field(Fld; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}
