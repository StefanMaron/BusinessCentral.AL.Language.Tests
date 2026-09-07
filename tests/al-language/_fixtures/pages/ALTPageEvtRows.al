page 60632 "ALT Page Evt Rows"
{
    // Fixture for TestPageTriggerEvents.al. Every one of the page's OWN triggers writes an
    // "ALT Trigger Log" row, so a test can assert both that a trigger ran and — through the
    // AutoIncrement "Entry No." — that it ran BEFORE the matching platform trigger event
    // (ALT Page Evt Sub, codeunit 60633).
    PageType = List;
    SourceTable = "ALT Page Evt Row";
    ApplicationArea = All;
    UsageCategory = Lists;
    DelayedInsert = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field("Value"; Rec."Value") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DirectSave)
            {
                ApplicationArea = All;
                Caption = 'Direct Save';

                trigger OnAction()
                begin
                    Rec.Validate("Value", 'DIRECT');
                    CurrPage.SaveRecord();
                end;
            }
            action(UpdateSave)
            {
                ApplicationArea = All;
                Caption = 'Update Save';

                trigger OnAction()
                begin
                    Rec.Validate("Value", 'UPDATED');
                    CurrPage.Update(true);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log('PageOnOpenTrig', '', '');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log('PageOnQueryCloseTrig', '', '');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log('PageOnCloseTrig', '', '');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log('PageOnNewTrig', '', '');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log('PageOnInsertTrig', Rec."Code", Rec."Value");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log('PageOnModifyTrig', xRec."Value", Rec."Value");
        exit(true);
    end;

    local procedure Log(Name: Code[30]; OldValue: Text[100]; NewValue: Text[100])
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := Name;
        TrigLog.OldValue := OldValue;
        TrigLog.NewValue := NewValue;
        TrigLog.Insert(true);
    end;
}
