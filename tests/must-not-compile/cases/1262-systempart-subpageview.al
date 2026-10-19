// @expect AL0171 | The property value 'sorting(Id)' on property 'SubPageView' is not valid.
// @expect AL0171 | The property value 'where(Nope = const(1))' on property 'SubPageView' is not valid.
// SubPageView on a system part: a valid view of the source table (Notes) and a view naming an unknown field (Links) are both refused with
// AL0171. (2 diagnostics)
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
                SubPageView = sorting(Id);
            }
            systempart(Links1; Links)
            {
                SubPageView = where(Nope = const(1));
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
