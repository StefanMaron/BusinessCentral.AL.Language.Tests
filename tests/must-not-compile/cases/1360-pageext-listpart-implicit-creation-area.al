// @expect AL0271 | The action 'Creation' is not found in the target 'MNC BL P1360'
// A page extension adds to area Creation of a ListPart page that declares no actions (a List page has this implicit area; a ListPart does not).
page 51360 "MNC BL P1360"
{
    PageType = ListPart;
    SourceTable = Integer;
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Number; Rec.Number) { }
            }
        }
    }
}
pageextension 51360 "MNC BL E1360" extends "MNC BL P1360"
{
    actions
    {
        addlast(Creation)
        {
            action(PartCreLast)
            {
                Caption = 'PartCreLast';
            }
        }
    }
}
