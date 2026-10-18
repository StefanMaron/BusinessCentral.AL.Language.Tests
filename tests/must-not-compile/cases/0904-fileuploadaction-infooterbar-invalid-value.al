// @expect AL0220 | Syntax error, boolean literal expected. Use 'true' or 'false'.
// Page file upload action InFooterBar given text instead of a Boolean.
table 50911 "MNC AA T911"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T911"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50911 "MNC AA P911"
{
    PageType = Card;
    SourceTable = "MNC AA T911";
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
            fileuploadaction(U) { InFooterBar = 'yes'; trigger OnAction(Files: List of [FileUpload]) begin end; }
        }
    }
}
