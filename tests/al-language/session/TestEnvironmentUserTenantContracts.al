// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-userid-function
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68311, codeunits 68310 (tests), 68312 (log),
//                68313 (subscriber)
// Probe: written against a real BC 27.5 service tier started by bc-linux (sandbox, W1 localization,
// user BCRUNNER, tenant "default"); every literal below is what that tier produced. Other BC versions
// and other hosts were not measured.
//
// Pins what the System Application wrappers around the server's own classes answer in a test:
// "Environment Information" (environment type, name, application family), "Tenant Information",
// "Azure AD Tenant", "User Permissions", "Azure AD User Management", a few System functions
// (UserId, CompanyName, ProductName, TaskScheduler.CanCreateTask, session identifiers), and what
// Base Application decides when the platform asks which database table events to raise
// (Codeunit "Global Triggers", GetDatabaseTableTriggerSetup and GetGlobalTableTriggerMask).
//
// The members of "Server Setting" and "Environment Information".GetEnvironmentSetting are scoped
// OnPrem and are pinned in the OnPrem app (tests/al-language-onprem/session).
// BC versions: 27.5

table 68311 "Probe GT Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68312 "Probe GT Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

codeunit 68313 "Probe GT Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure Setup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        GtLog: Codeunit "Probe GT Log";
    begin
        if not Watched(TableId) then
            exit;
        GtLog.Add('Setup(' + Format(TableId) + ' ins=' + Format(OnDatabaseInsert) + ' mod=' + Format(OnDatabaseModify) + ' del=' + Format(OnDatabaseDelete) + ' ren=' + Format(OnDatabaseRename) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetGlobalTableTriggerMask', '', false, false)]
    local procedure Mask(TableId: Integer; var TableTriggerMask: Integer)
    var
        GtLog: Codeunit "Probe GT Log";
    begin
        if not Watched(TableId) then
            exit;
        GtLog.Add('Mask(' + Format(TableId) + ' mask=' + Format(TableTriggerMask) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure DatabaseInsert(RecRef: RecordRef)
    var
        GtLog: Codeunit "Probe GT Log";
    begin
        if not Watched(RecRef.Number) then
            exit;
        GtLog.Add('OnDatabaseInsert(' + Format(RecRef.Number) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalInsert', '', false, false)]
    local procedure GlobalInsert(RecRef: RecordRef)
    var
        GtLog: Codeunit "Probe GT Log";
    begin
        if not Watched(RecRef.Number) then
            exit;
        GtLog.Add('OnGlobalInsert(' + Format(RecRef.Number) + ')');
    end;

    local procedure Watched(TableId: Integer): Boolean
    begin
        exit(TableId in [Database::"Probe GT Table"]);
    end;
}

codeunit 68310 "Probe Environment Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure EnvironmentInformation_Answers()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        NoGuid: Guid;
    begin
        Assert.IsTrue(EnvironmentInformation.IsSandbox(), 'IsSandbox');
        Assert.IsFalse(EnvironmentInformation.IsProduction(), 'IsProduction');
        Assert.IsTrue(EnvironmentInformation.IsSaaS(), 'IsSaaS');
        Assert.IsTrue(EnvironmentInformation.IsOnPrem(), 'IsOnPrem is true at the same time as IsSaaS');
        Assert.IsFalse(EnvironmentInformation.IsFinancials(), 'IsFinancials');
        Assert.IsTrue(EnvironmentInformation.IsSaaSInfrastructure(), 'IsSaaSInfrastructure');
        Assert.AreEqual('Sandbox', EnvironmentInformation.GetEnvironmentName(), 'GetEnvironmentName');
        Assert.AreEqual('W1', EnvironmentInformation.GetApplicationFamily(), 'GetApplicationFamily');
        Assert.IsFalse(EnvironmentInformation.CanStartSession(), 'CanStartSession');
        Assert.AreEqual('', EnvironmentInformation.GetLinkedPowerPlatformEnvironmentId(), 'GetLinkedPowerPlatformEnvironmentId');
        Assert.IsTrue(EnvironmentInformation.VersionInstalled(NoGuid) >= 27, 'VersionInstalled of the null app id is the installed application major version');
    end;

    [Test]
    procedure TenantAndAzureAd_Answers()
    var
        TenantInformation: Codeunit "Tenant Information";
        AzureAdTenant: Codeunit "Azure AD Tenant";
    begin
        Assert.AreEqual('default', TenantInformation.GetTenantId(), 'Tenant Information.GetTenantId');
        Assert.AreEqual('default', TenantId(), 'TenantId()');
        Assert.AreEqual('', TenantInformation.GetTenantDisplayName(), 'GetTenantDisplayName');
        Assert.AreEqual('common', AzureAdTenant.GetAadTenantId(), 'GetAadTenantId');
        Assert.AreEqual('', AzureAdTenant.GetAadTenantDomainName(), 'GetAadTenantDomainName');
        Assert.AreEqual('', AzureAdTenant.GetCountryLetterCode(), 'GetCountryLetterCode');
        Assert.AreEqual('', AzureAdTenant.GetPreferredLanguage(), 'GetPreferredLanguage');
    end;

    [Test]
    procedure UserPermissions_And_AzureAdUserManagement_Answers()
    var
        UserPermissions: Codeunit "User Permissions";
        AzureAdUserManagement: Codeunit "Azure AD User Management";
    begin
        Assert.AreEqual('BCRUNNER', UserId(), 'UserId');
        Assert.IsFalse(IsNullGuid(UserSecurityId()), 'UserSecurityId is set');
        Assert.IsTrue(UserPermissions.IsSuper(UserSecurityId()), 'IsSuper');
        Assert.IsTrue(UserPermissions.CanManageUsersOnTenant(UserSecurityId()), 'CanManageUsersOnTenant');
        Assert.IsFalse(AzureAdUserManagement.IsUserTenantAdmin(), 'IsUserTenantAdmin');
        Assert.IsTrue(AzureAdUserManagement.ArePermissionsCustomized(UserSecurityId()), 'ArePermissionsCustomized');
        Assert.IsFalse(AzureAdUserManagement.IsUserDelegated(UserSecurityId()), 'IsUserDelegated');
    end;

    [Test]
    procedure SystemFunctions_Answers()
    var
        ModuleInfo: ModuleInfo;
    begin
        Assert.AreEqual('CRONUS International Ltd.', CompanyName(), 'CompanyName');
        Assert.AreEqual('Dynamics 365 Business Central', ProductName.Full(), 'ProductName.Full');
        Assert.AreEqual('Business Central', ProductName.Short(), 'ProductName.Short');
        Assert.AreEqual('Microsoft Dynamics 365 Business Central', ProductName.Marketing(), 'ProductName.Marketing');
        Assert.AreEqual(1033, GlobalLanguage(), 'GlobalLanguage');
        Assert.IsFalse(TaskScheduler.CanCreateTask(), 'TaskScheduler.CanCreateTask');
        Assert.AreEqual('NAV', Session.ApplicationIdentifier(), 'ApplicationIdentifier');
        Assert.AreEqual('Normal', Format(Session.GetCurrentModuleExecutionContext()), 'GetCurrentModuleExecutionContext');
        Assert.AreEqual('Normal', Format(Session.GetExecutionContext()), 'GetExecutionContext');
        Assert.AreEqual('Standard', Format(CurrentExecutionMode()), 'CurrentExecutionMode');
        Assert.IsTrue(SessionId() > 0, 'SessionId');
        Assert.IsTrue(ServiceInstanceId() > 0, 'ServiceInstanceId');
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        Assert.AreEqual('AL Language Coverage Tests', ModuleInfo.Name(), 'module name');
        Assert.AreEqual('AL Language', ModuleInfo.Publisher(), 'module publisher');
    end;

    [Test]
    procedure GlobalTriggers_BaseApplication_EnablesTheDatabaseEventsForAnyTable_AndNoGlobalEvents()
    // CLAIM: when a subscriber of GetDatabaseTableTriggerSetup runs, the four flags already hold true for a table of this app (Base Application set them); GetGlobalTableTriggerMask holds 0. OnDatabaseInsert is raised for Insert(true) and Insert(false); OnGlobalInsert is not.
    var
        GtLog: Codeunit "Probe GT Log";
        GtTable: Record "Probe GT Table";
    begin
        GtTable.DeleteAll();
        Commit();
        Assert.AreEqual('Mask(68311 mask=0);Setup(68311 ins=Yes mod=Yes del=Yes ren=Yes);', GtLog.Take(), 'the first write to the table asks for the setup once');

        GtTable.Id := 1;
        GtTable.Insert(true);
        Assert.AreEqual('OnDatabaseInsert(68311);', GtLog.Take(), 'Insert(true)');

        GtTable.Id := 2;
        GtTable.Insert(false);
        Assert.AreEqual('OnDatabaseInsert(68311);', GtLog.Take(), 'Insert(false)');
    end;
}
