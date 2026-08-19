table 60966 "ALT IncludeSender Table Pub"
{
    // Sibling of "ALT Manual TableEvent Pub" (60976), which only covers
    // [IntegrationEvent(false, false)] — no parameters, no sender. This fixture covers
    // [IntegrationEvent(true, false)] declared on a TABLE: IncludeSender=true means the event
    // takes no explicit arguments, and the publishing table instance itself is what subscribers
    // receive as "Sender". Used by TestManualTableIncludeSenderEvent.al.
    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    [IntegrationEvent(true, false)]
    local procedure OnDiscoverEntries()
    begin
    end;

    procedure RaiseOnDiscoverEntries()
    begin
        OnDiscoverEntries();
    end;

    procedure AddEntry(NewCode: Code[20])
    begin
        // Callable ONLY through a working Sender — proves the subscriber received a live,
        // usable record handle bound to this table, not null and not some unrelated object.
        if Get(NewCode) then
            exit;
        Init();
        "Code" := NewCode;
        Insert(true);
    end;
}
