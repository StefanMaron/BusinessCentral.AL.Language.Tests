codeunit 60967 "ALT IncludeSender Cu Pub"
{
    // Control publisher for TestManualTableIncludeSenderEvent.al: same
    // [IntegrationEvent(true, false)] as "ALT IncludeSender Table Pub" (60966), but declared on
    // a CODEUNIT — the already-well-trodden IncludeSender shape. Isolates whether a failure is
    // specific to the TABLE publisher case or a general IncludeSender problem.
    [IntegrationEvent(true, false)]
    local procedure OnDiscoverFromCodeunit()
    begin
    end;

    procedure RaiseOnDiscoverFromCodeunit()
    begin
        OnDiscoverFromCodeunit();
    end;

    procedure Ping(): Code[20]
    begin
        exit('FROM-CU-SENDER');
    end;
}
