// @expect AL0169 | The option value 'Everywhere' is not valid. Check the enum definition for valid values.
// Scope of a file upload action takes Page or Repeater only.
table 59691 "MNC U 691"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Dec; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 59691 "MNC U Upload 691"
{
    PageType = Card;
    SourceTable = "MNC U 691";
    layout { area(Content) { field(Txt; Rec.Txt) { } } }
    actions { area(Processing) { fileuploadaction(Up1) { Scope = Everywhere; trigger OnAction(Files: List of [FileUpload]) begin end; } } }
}
