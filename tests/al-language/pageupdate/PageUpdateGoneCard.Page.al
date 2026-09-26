// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: ALT Page Update Gone Row (67300), ALT Page Update Gone Trace (67301)
//
// Two shapes of CurrPage.Update(false) on a current row the table does not hold:
//   - the DeleteAndUpdate action deletes the current row and then calls CurrPage.Update(false);
//   - the name field's OnValidate calls CurrPage.Update(false), which on this DelayedInsert page
//     leaves a new row unsaved.
// UpdateOnly is the control: CurrPage.Update(false) on a row that is still stored.
// OnAfterGetRecord and OnAfterGetCurrRecord record the key they see.

page 67300 "ALT Page Update Gone Card"
{
    PageType = Card;
    SourceTable = "ALT Page Update Gone Row";
    DelayedInsert = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeField; Rec.Code)
            {
                ApplicationArea = All;
            }
            field(NameField; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    Trace.Note('Validate');
                    CurrPage.Update(false);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteAndUpdate)
            {
                ApplicationArea = All;
                Caption = 'Delete And Update';

                trigger OnAction()
                begin
                    Trace.Note('ActionBegin');
                    Rec.Delete();
                    CurrPage.Update(false);
                    Trace.Note('ActionEnd');
                end;
            }
            action(UpdateOnly)
            {
                ApplicationArea = All;
                Caption = 'Update Only';

                trigger OnAction()
                begin
                    Trace.Note('ActionBegin');
                    CurrPage.Update(false);
                    Trace.Note('ActionEnd');
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Trace.Note('AGR:' + Rec.Code);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Trace.Note('AGCR:' + Rec.Code);
    end;

    var
        Trace: Codeunit "ALT Page Update Gone Trace";
}
