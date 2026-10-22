// Cross-app fixture D (writer QY; al-runtime-rs backlog "PROBES from multiapp-runtime", item 2): one subscriber of
// "LT QY XA Order Publisher".OnQyIndep (cross-app fixture A, tests/al-language-xapp-a/QyXaObjects.al). This app depends on A only: it and
// cross-app fixtures B and C and the main test app do not depend on each other, so only the publish order or a static rule can place it.
// Its subscriber id (61160) is higher than the subscribers of A, B and C on that event and lower than the main app's (87620).

codeunit 61160 "LT QY XD Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT QY XA Order Publisher", 'OnQyIndep', '', false, false)]
    local procedure OnQyIndep(var Log: Text)
    begin
        Log += 'D;';
    end;
}
