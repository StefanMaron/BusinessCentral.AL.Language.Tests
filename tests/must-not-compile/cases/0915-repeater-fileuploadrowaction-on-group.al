// @expect AL0591 | The property FileUploadRowAction is only supported on Repeater.
// Page group FileUploadRowAction on a normal group.
table 50922 "MNC AA T922"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T922"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50922 "MNC AA P922"
{
    PageType = Card;
    SourceTable = "MNC AA T922";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            group(G) { FileUploadRowAction = U; }
        }
    }
    actions
    {
        area(Processing)
        {
            fileuploadaction(U) { trigger OnAction(Files: List of [FileUpload]) begin end; }
        }
    }
}
