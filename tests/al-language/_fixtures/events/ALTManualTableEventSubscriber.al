codeunit 60034 "ALT Manual Table Event Sub"
{
    // Manual-binding subscriber to a TABLE event (ALT Universal OnAfterInsertEvent).
    // Sibling of "ALT Manual Event Sub" (60033), which covers the codeunit-event path.
    //
    // Two independent kinds of evidence:
    //   * instance state (FireCount / LastEntryNo) proves the BOUND instance is the one
    //     dispatched to, and is readable by whoever called BindSubscription;
    //   * an "ALT Trigger Log" row proves whether the subscriber fired AT ALL, which is
    //     observable even when no instance is bound (and therefore no instance exists to
    //     interrogate).
    EventSubscriberInstance = Manual;

    var
        FireCount: Integer;
        LastEntryNo: Integer;

    procedure GetFireCount(): Integer
    begin
        exit(FireCount);
    end;

    procedure GetLastEntryNo(): Integer
    begin
        exit(LastEntryNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"ALT Universal", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertALTUniversal(var Rec: Record "ALT Universal"; RunTrigger: Boolean)
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        FireCount += 1;
        LastEntryNo := Rec."Entry No.";

        TrigLog.Init();
        TrigLog.TriggerName := 'ManualTableAfterInsert';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.NewEntryNo := Rec."Entry No.";
        TrigLog.NewIntegerValue := Rec."Integer Field";
        TrigLog.Insert();
    end;
}
