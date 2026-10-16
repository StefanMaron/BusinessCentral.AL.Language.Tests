// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74018
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Clear on ErrorInfo and Notification
// BC versions: 29 (27 and 28 by CI)
// Tag: P95

codeunit 74018 "LT P95 Clear ErrorInfo"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        EI: ErrorInfo;
        N: Notification;
    begin
        EI := ErrorInfo.Create('boom');
        EI.Title := 'T';
        EI.Verbosity := Verbosity::Warning;
        Clear(EI);
        Observer.Observe('errorinfo', '[' + EI.Message + '][' + EI.Title + ']' + Format(EI.Verbosity));
        N.Message := 'note';
        N.Scope := NotificationScope::GlobalScope;
        N.SetData('k', 'v');
        Clear(N);
        Observer.Observe('notification', '[' + N.Message + ']' + Format(N.Scope) + '|' + Format(N.HasData('k')));
        Observer.Observe('notification_id_null', Format(IsNullGuid(N.Id)));

        Observer.Finish();
    end;

}
