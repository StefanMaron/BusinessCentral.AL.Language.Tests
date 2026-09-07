codeunit 60633 "ALT Page Evt Sub"
{
    // STATICALLY bound subscriber to the platform trigger events BC publishes on a page —
    // the page counterpart of the table trigger events ALTTableEventSubscriber.al covers.
    // Only page 60632 "ALT Page Evt Rows" is subscribed, and that page is private to
    // TestPageTriggerEvents.al, so these rows cannot leak into another suite's
    // "ALT Trigger Log" assertions.

    [EventSubscriber(ObjectType::Page, Page::"ALT Page Evt Rows", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvent(var Rec: Record "ALT Page Evt Row")
    begin
        Log('PageOpenEvt', '', '');
    end;

    [EventSubscriber(ObjectType::Page, Page::"ALT Page Evt Rows", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnQueryClosePageEvent(var Rec: Record "ALT Page Evt Row"; var AllowClose: Boolean)
    begin
        Log('PageQueryCloseEvt', '', '');
    end;

    [EventSubscriber(ObjectType::Page, Page::"ALT Page Evt Rows", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePageEvent(var Rec: Record "ALT Page Evt Row")
    begin
        Log('PageCloseEvt', '', '');
    end;

    [EventSubscriber(ObjectType::Page, Page::"ALT Page Evt Rows", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordEvent(var Rec: Record "ALT Page Evt Row")
    begin
        Log('PageAfterGetCurrEvt', '', Rec."Code");
    end;

    [EventSubscriber(ObjectType::Page, Page::"ALT Page Evt Rows", 'OnNewRecordEvent', '', false, false)]
    local procedure OnNewRecordEvent(var Rec: Record "ALT Page Evt Row"; BelowxRec: Boolean; var xRec: Record "ALT Page Evt Row")
    begin
        Log('PageNewEvt', '', '');
    end;

    [EventSubscriber(ObjectType::Page, Page::"ALT Page Evt Rows", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEvent(var Rec: Record "ALT Page Evt Row"; BelowxRec: Boolean; var xRec: Record "ALT Page Evt Row"; var AllowInsert: Boolean)
    begin
        Log('PageInsertEvt', Rec."Code", Rec."Value");
    end;

    [EventSubscriber(ObjectType::Page, Page::"ALT Page Evt Rows", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEvent(var Rec: Record "ALT Page Evt Row"; var xRec: Record "ALT Page Evt Row"; var AllowModify: Boolean)
    begin
        Log('PageModifyEvt', xRec."Value", Rec."Value");
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
