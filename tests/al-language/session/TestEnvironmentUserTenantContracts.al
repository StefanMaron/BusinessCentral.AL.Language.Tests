// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-userid-function
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained tables 68311, 68314, 68315, codeunits 68310 (tests), 68312 (log),
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
// Global Triggers: what the flags hold depends on the apps installed. Where the Microsoft app Tests-TestLibraries
// is installed (a full local bc-linux container), its codeunit "Backup Management" sets all four flags for the tables
// of this app; where it is not (CI), only Base Application's own rules apply (Change Log setup, Dataverse
// mapping, API webhook subscription, data synchronization). The tests below read that app's presence and expect
// either answer, and pin the Change Log rule and the platform's reaction to a flag.
// BC versions: 27.5, 28.5

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

table 68314 "Probe GT Changelog Table"
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

table 68315 "Probe GT Own Table"
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
        if TableId = Database::"Probe GT Own Table" then
            OnDatabaseInsert := true;
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
        exit(TableId in [Database::"Probe GT Table", Database::"Probe GT Changelog Table", Database::"Probe GT Own Table"]);
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

    local procedure TestLibrariesInstalled(): Boolean
    var
        InstalledApp: Record "NAV App Installed App";
    begin
        // "Tests-TestLibraries" (Microsoft, app id below) holds the codeunit "Backup Management" (130011).
        // It is subscribed to GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup and sets all
        // four flags to true for every table with an id in 1..99999 and 150000..1999999999 (so for the
        // tables of this app) whenever a company is open. A full local bc-linux container has the app; a
        // container with a selective app set (the CI one) does not.
        exit(InstalledApp.Get('{5D86850B-0D76-4ECA-BD7B-951AD998E997}'));
    end;

    local procedure YesNo(Value: Boolean): Text
    begin
        if Value then
            exit('Yes');
        exit('No');
    end;

    [Test]
    procedure GlobalTriggers_PlainTable_FlagsAreSetOnlyBySubscribersOfTheOnAfterEvent()
    // CLAIM: Base Application's own subscribers set no flag for a table that nothing configures (no change log, no Dataverse mapping, no API webhook subscription, no data synchronization). The only subscriber that does is Backup Management of the Tests-TestLibraries app, where that app is installed. GetGlobalTableTriggerMask holds 0. OnDatabaseInsert is raised only when a flag is set, and OnGlobalInsert never.
    var
        GtLog: Codeunit "Probe GT Log";
        GtTable: Record "Probe GT Table";
        Flag: Text;
        InsertEvent: Text;
    begin
        Flag := YesNo(TestLibrariesInstalled());
        InsertEvent := '';
        if TestLibrariesInstalled() then
            InsertEvent := 'OnDatabaseInsert(68311);';

        GtTable.DeleteAll();
        Commit();
        Assert.AreEqual('Mask(68311 mask=0);Setup(68311 ins=' + Flag + ' mod=' + Flag + ' del=' + Flag + ' ren=' + Flag + ');', GtLog.Take(), 'the first write to the table asks for the setup once');

        GtTable.Id := 1;
        GtTable.Insert(true);
        Assert.AreEqual(InsertEvent, GtLog.Take(), 'Insert(true)');

        GtTable.Id := 2;
        GtTable.Insert(false);
        Assert.AreEqual(InsertEvent, GtLog.Take(), 'Insert(false)');
    end;

    [Test]
    procedure GlobalTriggers_ChangeLogSetup_DecidesInsertDeleteAndRenameFlagsOfAConfiguredTable()
    // CLAIM: the deciding subscriber is GlobalTriggerManagement.GetDatabaseTableTriggerSetup, which calls "Change Log Management".GetDatabaseTableTriggerSetup after the OnAfter event, in the Normal execution context. With "Change Log Setup"."Change Log Activated" and a "Change Log Setup (Table)" row, a flag is true when its log column is not blank: Log Insertion gives the insert flag, Log Modification the modify AND the rename flag, Log Deletion the delete flag. Without the setup the same table gets no flag (see the plain table test).
    var
        GtLog: Codeunit "Probe GT Log";
        GtTable: Record "Probe GT Changelog Table";
        ChangeLogSetup: Record "Change Log Setup";
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        ChangeLogEntry: Record "Change Log Entry";
        Other: Text;
    begin
        // Setup and the first write happen with the original change log setup restored at the end.
        Other := YesNo(TestLibrariesInstalled());
        if not ChangeLogSetup.Get() then begin
            ChangeLogSetup.Init();
            ChangeLogSetup.Insert();
        end;
        ChangeLogSetup."Change Log Activated" := true;
        ChangeLogSetup.Modify();
        ChangeLogSetupTable.Init();
        ChangeLogSetupTable."Table No." := Database::"Probe GT Changelog Table";
        ChangeLogSetupTable."Log Insertion" := ChangeLogSetupTable."Log Insertion"::"All Fields";
        ChangeLogSetupTable."Log Deletion" := ChangeLogSetupTable."Log Deletion"::"All Fields";
        ChangeLogSetupTable.Insert();
        Commit();
        GtLog.Take();

        GtTable.DeleteAll();
        Commit();
        Assert.AreEqual('Mask(68314 mask=0);Setup(68314 ins=Yes mod=' + Other + ' del=Yes ren=' + Other + ');', GtLog.Take(), 'flags with a change log setup for insert and delete');

        GtTable.Id := 1;
        GtTable.Insert(true);
        Assert.AreEqual('OnDatabaseInsert(68314);', GtLog.Take(), 'Insert raises OnDatabaseInsert');

        // Put the change log back the way it was.
        GtTable.DeleteAll();
        ChangeLogEntry.SetRange("Table No.", Database::"Probe GT Changelog Table");
        ChangeLogEntry.DeleteAll();
        ChangeLogSetupTable.Get(Database::"Probe GT Changelog Table");
        ChangeLogSetupTable.Delete();
        ChangeLogSetup.Get();
        ChangeLogSetup."Change Log Activated" := false;
        ChangeLogSetup.Modify();
        Commit();
    end;

    [Test]
    procedure GlobalTriggers_SubscriberSetsInsertFlag_RaisesOnDatabaseInsertForBothInsertForms()
    // CLAIM: a subscriber of Codeunit "Global Triggers".GetDatabaseTableTriggerSetup that sets OnDatabaseInsert makes the platform raise OnDatabaseInsert for Insert(true) and Insert(false). The flags it was handed are the ones the other subscribers left (see the plain table test).
    var
        GtLog: Codeunit "Probe GT Log";
        GtTable: Record "Probe GT Own Table";
        Flag: Text;
    begin
        Flag := YesNo(TestLibrariesInstalled());

        GtTable.DeleteAll();
        Commit();
        Assert.AreEqual('Mask(68315 mask=0);Setup(68315 ins=' + Flag + ' mod=' + Flag + ' del=' + Flag + ' ren=' + Flag + ');', GtLog.Take(), 'flags handed to the subscriber');

        GtTable.Id := 1;
        GtTable.Insert(true);
        Assert.AreEqual('OnDatabaseInsert(68315);', GtLog.Take(), 'Insert(true)');

        GtTable.Id := 2;
        GtTable.Insert(false);
        Assert.AreEqual('OnDatabaseInsert(68315);', GtLog.Take(), 'Insert(false)');
    end;
}
