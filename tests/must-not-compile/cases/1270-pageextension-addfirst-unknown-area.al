// A page extension adds to an area name that is not a layout area (corpus issue 659 item 3, from al-runtime-rs #252).
// FactBoxes is accepted even when the base page does not declare it (tests/al-language/pageext/lt-bc-implicit-areas); an unknown name is not.
// @expect AL0270 | The control 'NotAnArea' is not found in the target 'MNC Unknown Area Card'
page 51270 "MNC Unknown Area Card"
{
    PageType = Card;
    SourceTable = Integer;

    layout
    {
        area(Content)
        {
            field(Number; Rec.Number) { ApplicationArea = All; }
        }
    }
}

pageextension 51271 "MNC Unknown Area Ext" extends "MNC Unknown Area Card"
{
    layout
    {
        addfirst(NotAnArea)
        {
            field(Again; Rec.Number) { ApplicationArea = All; }
        }
    }
}
