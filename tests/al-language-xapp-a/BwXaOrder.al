// Cross-app subscriber order probe (corpus #664 item 152; al-runtime-rs ADR-046 amendment 1, probe Q2), writer BW.
// One integration event, published here. Subscribers in this app (2), cross-app fixture B (2), cross-app fixture C (2) and the
// AL Language Coverage Tests app (5) each append a tag to the Log text. The tests are in
// tests/al-language/events/lt-bw-subscriber-order/BwSubscriberOrderTests.al.
// The subscriber codeunit ids interleave across the apps (A 61105 < B 61115 < C 61125 < A 61135 < B 61145 < C 61155 < main 83960..83964),
// so an order by codeunit id alone (ignoring the app) is told apart from every order that keeps one app's subscribers together.

codeunit 61100 "LT BW XA Order Publisher"
{
    [IntegrationEvent(false, false)]
    procedure OnBwOrder(var Log: Text)
    begin
    end;

    procedure Raise(): Text
    var
        Log: Text;
    begin
        OnBwOrder(Log);
        exit(Log);
    end;
}

// Lower id of this app, name sorts first.
codeunit 61105 "LT BW XA A Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BW XA Order Publisher", 'OnBwOrder', '', false, false)]
    local procedure OnBwOrder(var Log: Text)
    begin
        Log += 'A1;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure InstallPerCompany()
    var
        Writer: Codeunit "LT BW XA Install Writer";
    begin
        Writer.WriteRow('A1');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure InstallPerDatabase()
    var
        Writer: Codeunit "LT BW XA Install Writer";
    begin
        Writer.WriteRow('A1');
    end;
}

// Higher id of this app, name sorts last.
codeunit 61135 "LT BW XA Z Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BW XA Order Publisher", 'OnBwOrder', '', false, false)]
    local procedure OnBwOrder(var Log: Text)
    begin
        Log += 'A2;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure InstallPerCompany()
    var
        Writer: Codeunit "LT BW XA Install Writer";
    begin
        Writer.WriteRow('A2');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure InstallPerDatabase()
    var
        Writer: Codeunit "LT BW XA Install Writer";
    begin
        Writer.WriteRow('A2');
    end;
}
