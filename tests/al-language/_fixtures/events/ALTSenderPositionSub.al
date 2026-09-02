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
}
