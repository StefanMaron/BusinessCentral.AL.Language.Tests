codeunit 60968 "ALT IncludeSender Event Sub"
{
    // Subscribes to both "ALT IncludeSender Table Pub" (60966, table publisher) and
    // "ALT IncludeSender Cu Pub" (60967, codeunit publisher — control) — see
    // TestManualTableIncludeSenderEvent.al.
    [EventSubscriber(ObjectType::Table, Database::"ALT IncludeSender Table Pub", 'OnDiscoverEntries', '', false, false)]
    local procedure OnTableDiscover(var Sender: Record "ALT IncludeSender Table Pub")
    begin
        // Only reachable through a working, non-null Sender: Insert()/Get() are table
        // procedures, so a null Sender raises a runtime error here instead of silently
        // doing nothing.
        Sender.AddEntry('FROM-TABLE-SENDER');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALT IncludeSender Cu Pub", 'OnDiscoverFromCodeunit', '', false, false)]
    local procedure OnCodeunitDiscover(var Sender: Codeunit "ALT IncludeSender Cu Pub")
    var
        Pub: Record "ALT IncludeSender Table Pub";
    begin
        Pub.AddEntry(Sender.Ping());
    end;
}
