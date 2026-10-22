// Object of cross-app fixture C for writer QY's probes: a subscriber of "LT QY XA Order Publisher" whose id (61127) is lower than app A's only
// subscriber (61138) and than app B's second one (61147). See tests/al-language-xapp-a/QyXaObjects.al.

codeunit 61127 "LT QY XC Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT QY XA Order Publisher", 'OnQyOrder', '', false, false)]
    local procedure OnQyOrder(var Log: Text)
    begin
        Log += 'C;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT QY XA Order Publisher", 'OnQyIndep', '', false, false)]
    local procedure OnQyIndep(var Log: Text)
    begin
        Log += 'C;';
    end;
}
