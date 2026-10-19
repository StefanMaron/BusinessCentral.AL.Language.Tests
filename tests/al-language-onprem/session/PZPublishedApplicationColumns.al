// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope (OnPrem app: Published Application is Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61262
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816). Other BC versions are checked by the CI matrix.
//
// Published Application FlowFields and the Description Blob of well-known apps: the app of this test run, Base Application, System Application and Application all read "Tenant Visible" Yes,
// Installed Yes, "PerTenant Or Installed" Yes and a Description with a value. The Description of this app is the description text of its app.json (it starts "Ground-up test suite covering the in-sco").
// Not measured: an app that is published but not installed (the test container has none), and the platform System app (no row under the id 8874ed3a-0643-4247-9ced-7a7002f7135d).
// BC versions: 29.0
codeunit 61262 "PZ Published App Columns"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(AppId: Text): Text
    var
        App: Record "Published Application";
        Id: Guid;
        Size: Integer;
    begin
        Evaluate(Id, AppId);
        App.SetRange(ID, Id);
        if not App.FindFirst() then
            exit('no row');
        App.CalcFields("Tenant Visible", Installed, "PerTenant Or Installed", Description);
        exit('tenant visible=' + Format(App."Tenant Visible") + ' installed=' + Format(App.Installed) + ' per tenant or installed=' + Format(App."PerTenant Or Installed") + ' description has value=' + Format(App.Description.HasValue()));
    end;

    local procedure DescriptionStart(AppId: Text): Text
    var
        App: Record "Published Application";
        Id: Guid;
        InS: InStream;
        Text: Text;
    begin
        Evaluate(Id, AppId);
        App.SetRange(ID, Id);
        App.FindFirst();
        App.CalcFields(Description);
        App.Description.CreateInStream(InS, TextEncoding::UTF8);
        InS.ReadText(Text, 40);
        exit('[' + Text + ']');
    end;

    [Test]
    procedure TenantVisible_Installed_AndDescription_OfWellKnownApps()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('this app', Describe('a1b2c3d4-e5f6-7890-abcd-ef1234567890'));
        Observer.Observe('base application', Describe('437dbf0e-84ff-417a-965d-ed2bb9650972'));
        Observer.Observe('system application', Describe('63ca2fa4-4f03-4f2b-a480-172fef340d3f'));
        Observer.Observe('application', Describe('c1335042-3002-4257-bf8a-75c898ccb1b8'));
        Observer.Observe('this app description text', DescriptionStart('a1b2c3d4-e5f6-7890-abcd-ef1234567890'));
        Observer.Expect('this app', 'tenant visible=Yes installed=Yes per tenant or installed=Yes description has value=Yes');
        Observer.Expect('base application', 'tenant visible=Yes installed=Yes per tenant or installed=Yes description has value=Yes');
        Observer.Expect('system application', 'tenant visible=Yes installed=Yes per tenant or installed=Yes description has value=Yes');
        Observer.Expect('application', 'tenant visible=Yes installed=Yes per tenant or installed=Yes description has value=Yes');
        Observer.Expect('this app description text', '[Ground-up test suite covering the in-sco]');
        Observer.Verify();
    end;

    // Probe (writer BX, 2026-10-19): the exact "Tenant ID" (field 12) of the corpus apps and of Microsoft's apps. Microsoft code only
    // filters it with '' | TenantId(), which a blank also passes.
    local procedure TenantIdOf(AppId: Guid): Text
    var
        App: Record "Published Application";
    begin
        App.SetRange(ID, AppId);
        if not App.FindFirst() then
            exit('no row');
        exit('[' + App."Tenant ID" + '] rows=' + Format(App.Count()));
    end;

    [Test]
    procedure TenantId_OfCorpusAndMicrosoftApps()
    var
        App: Record "Published Application";
        Observer: Codeunit "Probe Observer";
        ThisModule: ModuleInfo;
        Id: Guid;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        Observer.Observe('TenantId()', TenantId());
        Observer.Observe('this onprem app', TenantIdOf(ThisModule.Id()));
        Evaluate(Id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
        Observer.Observe('cloud coverage app', TenantIdOf(Id));
        Evaluate(Id, '437dbf0e-84ff-417a-965d-ed2bb9650972');
        Observer.Observe('base application', TenantIdOf(Id));
        Evaluate(Id, '63ca2fa4-4f03-4f2b-a480-172fef340d3f');
        Observer.Observe('system application', TenantIdOf(Id));
        App.SetFilter("Tenant ID", '<>%1', '');
        Observer.Observe('rows with a non-blank tenant id', Format(App.Count()));
        App.SetRange("Tenant ID", TenantId());
        Observer.Observe('rows with tenant id = TenantId()', Format(App.Count()));
        App.SetFilter("Tenant ID", '%1|%2', '', TenantId());
        Observer.Observe('rows passing blank or TenantId() equals all rows', Format(App.Count() = AllRows()));
        Observer.Finish();
    end;

    local procedure AllRows(): Integer
    var
        App: Record "Published Application";
    begin
        exit(App.Count());
    end;
}
