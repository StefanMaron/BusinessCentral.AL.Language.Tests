// @expect AL0186 | Reference 'NoSuchAction' in application object 'MNC AB Page' does not exist
// FileUploadAction names an action of the page; an action that does not exist is refused.
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
                FileUploadAction = NoSuchAction;
                field(Fld; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}
