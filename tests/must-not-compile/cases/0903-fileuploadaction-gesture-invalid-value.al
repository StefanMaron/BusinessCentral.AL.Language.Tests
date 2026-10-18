// @expect AL0169 | The option value 'UpSwipe' is not valid. Check the enum definition for valid values.
// Page file upload action Gesture with an unknown value.
table 50910 "MNC AA T910"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T910"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50910 "MNC AA P910"
{
    PageType = Card;
    SourceTable = "MNC AA T910";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }
    actions
    {
        area(Processing)
        {
            fileuploadaction(U) { Gesture = UpSwipe; trigger OnAction(Files: List of [FileUpload]) begin end; }
        }
    }
}
