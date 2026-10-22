// Objects of cross-app fixture A for writer QY's probes (al-runtime-rs multi-app runtime, backlog "PROBES from multiapp-runtime").
//   61106 "LT QY XA Order Publisher": two integration events. OnQyOrder: subscribers whose app order by dependency differs from their app
//         order by lowest subscriber codeunit id (A 61138, B 61117 and 61147, C 61127, main app 87620). OnQyIndep: the same subscribers plus
//         cross-app fixture D (61160), which depends on A only, so D and B, C and the main app do not depend on each other.
//   61138 "LT QY XA Subs": the only subscriber of this app; its id is higher than the lowest subscriber ids of B and C.
//   61104 "LT QY XA Rename Blobs": a table with a Blob field of its own; cross-app fixture B and the main app each add one more Blob field.
// Tests: tests/al-language/events/lt-bw-subscriber-order/BwSubscriberOrderTests.al, tests/al-language/tableextension/lt-bw-cross-app/BwCrossAppTests.al.

codeunit 61106 "LT QY XA Order Publisher"
{
    [IntegrationEvent(false, false)]
    procedure OnQyOrder(var Log: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnQyIndep(var Log: Text)
    begin
    end;

    procedure RaiseOrder(): Text
    var
        Log: Text;
    begin
        OnQyOrder(Log);
        exit(Log);
    end;

    procedure RaiseIndep(): Text
    var
        Log: Text;
    begin
        OnQyIndep(Log);
        exit(Log);
    end;
}

codeunit 61138 "LT QY XA Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT QY XA Order Publisher", 'OnQyOrder', '', false, false)]
    local procedure OnQyOrder(var Log: Text)
    begin
        Log += 'A;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT QY XA Order Publisher", 'OnQyIndep', '', false, false)]
    local procedure OnQyIndep(var Log: Text)
    begin
        Log += 'A;';
    end;
}

table 61104 "LT QY XA Rename Blobs"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50]) { }
        field(3; "XA Blob"; Blob) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}
