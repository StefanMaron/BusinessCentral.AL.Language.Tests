// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixture for the QZ_* test in codeunit "Test Page Action Virtual Table" (TestPageActionVirtualTable.al): page 87691.
// Facts: the Caption column (9) and ToolTip1 column (10) of the "Page Action" virtual table for areas, groups with and without a Caption,
//   actions with no Caption, a Caption with a quote, a Caption with Comment and with Locked, a navigation action and an actionref.

page 87691 "LT QZ PA Captions"
{
    PageType = Card;
    Caption = 'LT QZ PA Captions';
    UsageCategory = None;

    actions
    {
        area(Processing)
        {
            action(NoCaption)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                end;
            }
            action(QuoteCaption)
            {
                ApplicationArea = All;
                Caption = 'With ''quote'' caption';
                ToolTip = 'Tip of the quote action';

                trigger OnAction()
                begin
                end;
            }
            action(CommentCaption)
            {
                ApplicationArea = All;
                Caption = 'Commented caption', Comment = 'a note for translators';

                trigger OnAction()
                begin
                end;
            }
            action(LockedCaption)
            {
                ApplicationArea = All;
                Caption = 'Locked caption', Locked = true;

                trigger OnAction()
                begin
                end;
            }
            group(NoCaptionGroup)
            {
                action(InnerAction)
                {
                    ApplicationArea = All;
                    Caption = 'Inner caption';

                    trigger OnAction()
                    begin
                    end;
                }
            }
        }
        area(Navigation)
        {
            action(NavAction)
            {
                ApplicationArea = All;
                Caption = 'Navigate caption';
                RunObject = page "LT QZ PA Captions";
            }
        }
        area(Promoted)
        {
            actionref(QuoteCaption_Promoted; QuoteCaption) { }
        }
    }
}
