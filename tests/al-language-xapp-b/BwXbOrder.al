// Cross-app subscriber order probe (corpus #664 item 152; al-runtime-rs ADR-046 amendment 1, probe Q2), writer BW: the two subscribers of
// cross-app fixture B. See tests/al-language-xapp-a/BwXaOrder.al.

// Lower id of this app, name sorts first.
codeunit 61115 "LT BW XB A Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BW XA Order Publisher", 'OnBwOrder', '', false, false)]
    local procedure OnBwOrder(var Log: Text)
    begin
        Log += 'B1;';
    end;
}

// Higher id of this app, name sorts last.
codeunit 61145 "LT BW XB Z Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BW XA Order Publisher", 'OnBwOrder', '', false, false)]
    local procedure OnBwOrder(var Log: Text)
    begin
        Log += 'B2;';
    end;
}
