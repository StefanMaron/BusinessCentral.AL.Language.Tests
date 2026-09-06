// Fixture for TestPageMetadataVirtualTable: a page whose PageType is a member the
// "Page Metadata" (2000000138) PageType column does not name.
//
// That column's OptionMembers run Card..HeadlinePart — thirteen members — while AL accepts
// PromptDialog, the page type Copilot dialogs use. So this fixture asks the platform what the
// PageType column reports for a page declaring a type the column has no member for. Every
// other page fixture in this suite declares one of the thirteen, so none of them can ask it.
//
// The page is deliberately minimal: no SourceTable, two text fields over page globals, and the
// three system actions a PromptDialog requires. It is never opened by a test — it exists to be
// READ through Page Metadata.

page 60879 "ALT Prompt Dialog Page"
{
    PageType = PromptDialog;
    Caption = 'ALT Prompt Dialog';
    Extensible = false;

    layout
    {
        area(Prompt)
        {
            field(UserPrompt; UserPromptText)
            {
                ApplicationArea = All;
                Caption = 'Prompt';
                MultiLine = true;
                ToolTip = 'Specifies the text the fixture would generate from.';
            }
        }
        area(Content)
        {
            field(GeneratedResult; ResultText)
            {
                ApplicationArea = All;
                Caption = 'Result';
                Editable = false;
                MultiLine = true;
                ToolTip = 'Specifies the text the fixture generated.';
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                Caption = 'Generate';
                ToolTip = 'Generates the result from the prompt.';

                trigger OnAction()
                begin
                    ResultText := UserPromptText;
                end;
            }
            systemaction(Ok)
            {
                Caption = 'Keep it';
                ToolTip = 'Keeps the generated result.';
            }
            systemaction(Cancel)
            {
                Caption = 'Discard it';
                ToolTip = 'Discards the generated result.';
            }
        }
    }

    var
        UserPromptText: Text;
        ResultText: Text;
}
