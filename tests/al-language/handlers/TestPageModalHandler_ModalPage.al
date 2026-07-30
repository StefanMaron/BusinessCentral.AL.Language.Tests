// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modal-page-handler
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702), Test Page Modal (60703)
//
// The modal page under test — what a [ModalPageHandler] is handed.

page 60703 "Test Page Modal"
{
    PageType = Card;
    SourceTable = "Test Page Modal Handler Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Descr; Rec.Descr)
            {
                ApplicationArea = All;
            }
        }
    }
}
