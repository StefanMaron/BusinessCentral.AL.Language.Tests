// Cross-app subscriber order probe (corpus #664 item 152; al-runtime-rs ADR-046 amendment 1, probe Q2), writer BW: the two subscribers of
// cross-app fixture C. See tests/al-language-xapp-a/BwXaOrder.al.

// Lower id of this app, name sorts first.
codeunit 61125 "LT BW XC A Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BW XA Order Publisher", 'OnBwOrder', '', false, false)]
    local procedure OnBwOrder(var Log: Text)
    begin
        Log += 'C1;';
    end;
}

// Higher id of this app, name sorts last.
codeunit 61155 "LT BW XC Z Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BW XA Order Publisher", 'OnBwOrder', '', false, false)]
    local procedure OnBwOrder(var Log: Text)
    begin
        Log += 'C2;';
    end;
}
