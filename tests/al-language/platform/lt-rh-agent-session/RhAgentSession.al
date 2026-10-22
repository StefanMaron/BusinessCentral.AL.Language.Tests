// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/ai/ai-agent-overview
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: al-runner issues 5685 and 5686 (aldevtools/BusinessCentral.AL.Runner). The public System Application agent API called in a test session that is
//   not an agent session, on the corpus CI container: "Agent Session" (4312) GetCurrentSessionAgentTaskId and IsAgentSession, which call the natives of
//   codeunit 2000000022 "Agent Utilities"; "Agent Task Builder" (4315) Initialize and SetExternalId, which first call the native access check of codeunit
//   2000000020 "Feature Access Management" (AgentTaskManagementPreviewEnabled(true) on BC 27, AgentManagementAllowed(true) from BC 28); "Agent Task"
//   (4303) TaskExists, which passes the same check and then reads the virtual table Agent Task. The natives themselves are probed from the OnPrem app
//   (al-language-onprem/platform/lt-rh-agent-natives/RhAgentNatives.al).
// BC versions: 27, 28, 29. Object id 88003.

codeunit 88003 "LT RH Agent Session"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryTaskExists(var Exists: Boolean)
    var
        AgentTask: Codeunit "Agent Task";
    begin
        Exists := AgentTask.TaskExists(CreateGuid(), 'LT RH missing');
    end;

    [TryFunction]
    local procedure TryBuilder()
    var
        Builder: Codeunit "Agent Task Builder";
    begin
        Builder.Initialize(CreateGuid(), 'LT RH task');
        Builder.SetExternalId('LT RH external');
    end;

    // al-runner issue 5685: the task id outside an agent task.
    [Test]
    procedure RH_AgentSession_TaskIdOutsideAgentSession()
    var
        Observer: Codeunit "Probe Observer";
        AgentSession: Codeunit "Agent Session";
        Provider: Enum "Agent Metadata Provider";
        TaskId: BigInteger;
    begin
        TaskId := AgentSession.GetCurrentSessionAgentTaskId();
        Observer.Observe('task id', Format(TaskId));
        Observer.Observe('is agent session', Format(AgentSession.IsAgentSession(Provider)));
        Observer.Observe('provider after', Format(Provider.AsInteger()));
        Observer.Finish();
    end;

    // al-runner issue 5686: Initialize and SetExternalId called directly (an error would end the test) and inside a TryFunction.
    [Test]
    procedure RH_AgentTaskBuilder_InitializeAndSetExternalId()
    var
        Observer: Codeunit "Probe Observer";
        Builder: Codeunit "Agent Task Builder";
    begin
        Builder.Initialize(CreateGuid(), 'LT RH task');
        Builder.SetExternalId('LT RH external');
        Observer.Observe('direct', 'returned');
        ClearLastError();
        Observer.Observe('try', Format(TryBuilder()));
        Observer.ObserveError('try error');
        Observer.Finish();
    end;

    // al-runner issue 5686, second shape: TaskExists for an unknown agent.
    [Test]
    procedure RH_AgentTask_TaskExistsUnknownAgent()
    var
        Observer: Codeunit "Probe Observer";
        Exists: Boolean;
    begin
        ClearLastError();
        Observer.Observe('try', Format(TryTaskExists(Exists)));
        Observer.Observe('exists', Format(Exists));
        Observer.ObserveError('error');
        Observer.Finish();
    end;
}
