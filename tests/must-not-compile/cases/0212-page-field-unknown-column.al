// @expect AL0132 | 'Record "MNC T212"' does not contain a definition for 'NoSuchColumn'
// A page field is bound to a column the source table does not have.
table 50016 "MNC T212"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; D; Date) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50017 "MNC P212"
{
    PageType = List;
    SourceTable = "MNC T212";
    layout
    {
        area(Content)
        {
            repeater(Rep)
            {
                field(X; Rec.NoSuchColumn) { ApplicationArea = All; }
            }
        }
    }
}
