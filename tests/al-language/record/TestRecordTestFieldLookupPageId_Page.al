// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-joker-method
// Scope: in-scope
// Fixtures used: Test TestField LookupPage Row (60037), Test TestField LookupPage Card (60038)
//
// The page "Test TestField LookupPage Row".LookupPageId names — present purely so that
// table's LookupPageId property resolves to a real, compiled page.

page 60038 "Test TestField LookupPage Card"
{
    PageType = Card;
    SourceTable = "Test TestField LookupPage Row";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Test TestField LookupPage Card';

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code")
            {
                ApplicationArea = All;
            }
            field("Mandatory Field"; Rec."Mandatory Field")
            {
                ApplicationArea = All;
            }
        }
    }
}
