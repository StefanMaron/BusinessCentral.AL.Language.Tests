// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunits 61497-61499
// RISKY (runtime): the event recorder and permission logger receivers (the shapes of Microsoft's codeunits 9804 and 9802); what they deliver to a test session is observed, not assumed.
//
// Triggers EventReceiver::OnEventCheckEvent, EventReceiver::OnPermissionCheckEvent and EventReceiver::OnRecordingErrorOccurred of the platform event receivers: whether they fire for events this session raises, and what a receiver without handler does.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.EventArgs"; LtPEventArgs2) { }
    }

    assembly("Microsoft.Dynamics.Nav.EtwListener")
    {
        type("Microsoft.Dynamics.Nav.EtwListener.EventCheckEventArgs"; LtPEventCheckEventArgs) { }
        type("Microsoft.Dynamics.Nav.EtwListener.NavEventEventReceiver"; LtPNavEventEventReceiver) { }
        type("Microsoft.Dynamics.Nav.EtwListener.NavPermissionEventReceiver"; LtPNavPermissionEventReceiver) { }
        type("Microsoft.Dynamics.Nav.EtwListener.PermissionCheckEventArgs"; LtPPermissionCheckEventArgs) { }
    }
}

codeunit 61497 "LT P Event Recorder Host"
{
    SingleInstance = true;

    var
        [WithEvents]
        EventReceiver: DotNet LtPNavEventEventReceiver;
        Hits: Integer;
        ForeignSession: Integer;
        ObjectTypeText: Text;
        ObjectIdText: Text;
        EventTypeText: Text;
        CallingMethodText: Text;
        SessionMatches: Text;
        ErrorCount: Integer;

    procedure StartRecording()
    begin
        Hits := 0;
        ForeignSession := 0;
        ErrorCount := 0;
        ObjectTypeText := '';
        ObjectIdText := '';
        EventTypeText := '';
        CallingMethodText := '';
        SessionMatches := '';
        if IsNull(EventReceiver) then
            EventReceiver := EventReceiver.NavEventEventReceiver();
        EventReceiver.RegisterForEvents();
    end;

    procedure StopRecording()
    begin
        EventReceiver.UnregisterEvents();
    end;

    procedure RaiseOwnEvent()
    begin
        OnLtPRecorded();
    end;

    procedure Report(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('own_event_hits', Format(Hits));
        Observer.Observe('own_event_object_type', ObjectTypeText);
        Observer.Observe('own_event_object_id', ObjectIdText);
        Observer.Observe('own_event_event_type', EventTypeText);
        Observer.Observe('own_event_calling_method', CallingMethodText);
        Observer.Observe('own_event_session_matches', SessionMatches);
        Observer.Observe('recording_errors', Format(ErrorCount));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLtPRecorded()
    begin
    end;

    trigger EventReceiver::OnEventCheckEvent(sender: Variant; e: DotNet LtPEventCheckEventArgs)
    begin
        if e.EventName <> 'OnLtPRecorded' then
            exit;
        Hits += 1;
        ObjectTypeText := Format(e.ObjectType);
        ObjectIdText := Format(e.ObjectId);
        EventTypeText := Format(e.EventType);
        CallingMethodText := e.CallingMethodName;
        SessionMatches := Format(e.SessionId = SessionId());
    end;

    trigger EventReceiver::OnRecordingErrorOccurred(sender: Variant; e: DotNet LtPEventArgs2)
    begin
        ErrorCount += 1;
    end;
}

codeunit 61498 "LT P Permission Logger Host"
{
    SingleInstance = true;

    var
        [WithEvents]
        EventReceiver: DotNet LtPNavPermissionEventReceiver;
        Hits: Integer;
        TableHits: Integer;

    procedure StartLogging()
    begin
        Hits := 0;
        TableHits := 0;
        if IsNull(EventReceiver) then
            EventReceiver := EventReceiver.NavPermissionEventReceiver(SessionId());
        EventReceiver.RegisterForEvents();
    end;

    procedure StopLogging()
    begin
        EventReceiver.UnregisterEvents();
    end;

    procedure Report(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('any_permission_event', Format(Hits > 0));
        Observer.Observe('own_table_permission_event', Format(TableHits > 0));
    end;

    trigger EventReceiver::OnPermissionCheckEvent(sender: Variant; e: DotNet LtPPermissionCheckEventArgs)
    begin
        Hits += 1;
        if e.ObjectId = Database::"Probe Observer Entry" then
            TableHits += 1;
    end;
}

codeunit 61499 "LT P Event Receiver Triggers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PEventReceiver_OnEventCheckEvent()
    var
        Observer: Codeunit "Probe Observer";
        Host: Codeunit "LT P Event Recorder Host";
    begin
        Host.StartRecording();
        Host.RaiseOwnEvent();
        Host.StopRecording();
        Host.Report(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure PEventReceiver_OnPermissionCheckEvent()
    var
        Observer: Codeunit "Probe Observer";
        Host: Codeunit "LT P Permission Logger Host";
        Entry: Record "Probe Observer Entry";
    begin
        Host.StartLogging();
        if Entry.FindFirst() then;
        Host.StopLogging();
        Host.Report(Observer);
        Observer.Finish();
    end;
}
