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

    actions
    {
        area(Processing)
        {
            // TestPage.OK()/.Cancel() invoke an action tree lookup by SystemAction —
            // they do NOT reach the client's implicit modal chrome buttons. Without
            // these, real BC raises "The built-in action = Cancel is not found on
            // the page." for both OK and Cancel.
            action(OK)
            {
                ApplicationArea = All;
                SystemAction = OK;
            }
            action(Cancel)
            {
                ApplicationArea = All;
                SystemAction = Cancel;
            }
        }
    }
}
