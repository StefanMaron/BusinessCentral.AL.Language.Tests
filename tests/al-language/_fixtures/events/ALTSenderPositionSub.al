codeunit 60971 "ALT Sender Position Sub"
{
    EventSubscriberInstance = StaticAutomatic;

    // Sender declared FIRST — the already-well-trodden IncludeSender shape (control).
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALT Sender Position Pub", 'OnAfterComputeSenderFirst', '', false, false)]
    local procedure HandleSenderFirst(var Sender: Codeunit "ALT Sender Position Pub"; var Value: Integer; Tag: Code[20])
    begin
        Value := Sender.GetSeed() + Value;
        Sender.SetMarker(Tag);
    end;

    // Sender declared in the MIDDLE of the parameter list.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALT Sender Position Pub", 'OnAfterComputeSenderMiddle', '', false, false)]
    local procedure HandleSenderMiddle(var Value: Integer; var Sender: Codeunit "ALT Sender Position Pub"; Tag: Code[20])
    begin
        Value := Sender.GetSeed() + Value;
        Sender.SetMarker(Tag);
    end;

    // Sender declared LAST — the shape Base Application's MfgItemJnlPostLine.OnPostOutput
    // uses. Also proves an error raised THROUGH the sender still propagates.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALT Sender Position Pub", 'OnAfterComputeSenderLast', '', false, false)]
    local procedure HandleSenderLast(var Value: Integer; Tag: Code[20]; var Sender: Codeunit "ALT Sender Position Pub")
    begin
        if Tag = 'FAIL' then
            Sender.FailWith(Tag);
        Value := Sender.GetSeed() + Value;
        Sender.SetMarker(Tag);
    end;

    // Sender FIRST, trailing "Tag" OMITTED entirely — AL allows a subscriber to declare only
    // a prefix of the publisher's parameters. Proves the sender still binds when it is the
    // subscriber's LAST declared parameter because everything after it was dropped, not
    // because of its declared position among the publisher's own parameters.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALT Sender Position Pub", 'OnAfterComputeSenderFirstOmit', '', false, false)]
    local procedure HandleSenderFirstOmit(var Sender: Codeunit "ALT Sender Position Pub"; var Value: Integer)
    begin
        Value := Sender.GetSeed() + Value;
    end;

    // Sender LAST, trailing "Tag" OMITTED entirely. The subscriber's own parameter list is
    // (Value, Sender) — two parameters total, one short of the publisher's own arity (2) plus
    // the sender (3) — proving arity-based reasoning must not require an exact parameter-count
    // match against the publisher's declared arity.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALT Sender Position Pub", 'OnAfterComputeSenderLastOmit', '', false, false)]
    local procedure HandleSenderLastOmit(var Value: Integer; var Sender: Codeunit "ALT Sender Position Pub")
    begin
        Value := Sender.GetSeed() + Value;
    end;
}
