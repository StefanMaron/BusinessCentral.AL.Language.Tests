codeunit 60033 "ALT Manual Event Sub"
{
    // Manual-binding subscriber fixture: receives ALT Event Publisher events ONLY while an
    // instance is bound via BindSubscription. Instance state (fire count, last EntryNo)
    // proves the BOUND instance is the one dispatched to.
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALT Event Publisher", 'OnBeforeAction', '', false, false)]
    local procedure OnBeforeActionManualHandler(EntryNo: Integer; var Handled: Boolean)
    begin
        FireCount += 1;
        LastEntryNo := EntryNo;
        Handled := true;
    end;
}
