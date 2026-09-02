codeunit 60970 "ALT Sender Position Pub"
{
    // Sibling of "ALT IncludeSender Cu Pub" (60967): also a CODEUNIT publisher raising
    // [IntegrationEvent(true, false)] — IncludeSender=true — but this fixture exercises where
    // the sender parameter sits in the SUBSCRIBER's declared parameter list, not just whether
    // it arrives at all. Three parallel events differ only in where "ALT Sender Position Sub"
    // (60971) declares its sender: first, middle, or last.

    var
        Marker: Code[20];

    procedure ComputeSenderFirst(Tag: Code[20]) Value: Integer
    begin
        Value := 10;
        OnAfterComputeSenderFirst(Value, Tag);
    end;

    procedure ComputeSenderMiddle(Tag: Code[20]) Value: Integer
    begin
        Value := 10;
        OnAfterComputeSenderMiddle(Value, Tag);
    end;

    procedure ComputeSenderLast(Tag: Code[20]) Value: Integer
    begin
        Value := 10;
        OnAfterComputeSenderLast(Value, Tag);
    end;

    procedure GetSeed(): Integer
    begin
        exit(100);
    end;

    procedure SetMarker(NewMarker: Code[20])
    begin
        Marker := NewMarker;
    end;

    procedure GetMarker(): Code[20]
    begin
        exit(Marker);
    end;

    procedure FailWith(Tag: Code[20])
    begin
        Error('ALT sender position fail %1', Tag);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterComputeSenderFirst(var Value: Integer; Tag: Code[20])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterComputeSenderMiddle(var Value: Integer; Tag: Code[20])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterComputeSenderLast(var Value: Integer; Tag: Code[20])
    begin
    end;
}
