// @expect AL0591 | The property FileUploadRowAction is only supported on Repeater.
// FileUploadRowAction is a repeater property: a grid refuses it even when the action exists.
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
                FileUploadRowAction = Up;
                field(Fld; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            fileuploadaction(Up) { ApplicationArea = All; trigger OnAction(Files: List of [FileUpload]) begin end; }
        }
    }
}
