// @expect AL0171 | The property value 'Id = field(Id)' on property 'SubPageLink' is not valid.
// @expect AL0171 | The property value 'Id = field(Id)' on property 'SubPageLink' is not valid.
// SubPageLink on a system part (Notes and Links): the property value is refused (AL0171), so no system part can be linked to a field.
// EntityName and EntitySetName compile on a system part: tests/al-language/pages/lt-bb-page-controls. (2 diagnostics)
table 50000 "MNC BB Row"
{
    fields { field(1; Id; Integer) { } field(2; Lvl; Integer) { } field(3; Txt; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50001 "MNC BB Page"
{
    PageType = List;
    SourceTable = "MNC BB Row";
    layout
    {
        area(Content)
        {
            repeater(R) { field(Id; Rec.Id) { } }
        }
        area(FactBoxes)
        {
            systempart(Notes1; Notes)
            {
                SubPageLink = Id = field(Id);
            }
            systempart(Links1; Links)
            {
                SubPageLink = Id = field(Id);
            }
        }
    }
    actions
    {
        area(Processing)
        {
            fileuploadaction(Upload1)
            {
                trigger OnAction(Files: List of [FileUpload])
                begin
                end;
            }
        }
    }
}
