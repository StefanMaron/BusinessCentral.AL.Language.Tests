// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Fixtures used: CmInstallObjects.al in this folder (84837-84839, 84841, 84842), Probe Observer (69160).
// Facts: corpus issue 669 (odd AL behavior leads, part D), items 41, 42, 43: what the install codeunit 84838 recorded.
// BC versions: 27, 28, 29

codeunit 84840 "LT CM Install Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Code: Code[30]): Text
    var
        S: Record "LT CM Install Seed";
    begin
        if not S.Get(Code) then
            exit('<missing>');
        exit(S.Txt);
    end;

    local procedure SeedDb(Code: Code[30]): Text
    var
        S: Record "LT CM Install Seed Db";
    begin
        if not S.Get(Code) then
            exit('<missing>');
        exit(S.Txt);
    end;

    local procedure CountOwnObjects(): Integer
    var
        AllObj: Record AllObjWithCaption;
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        AllObj.SetRange("App Package ID", Info.PackageId);
        exit(AllObj.Count());
    end;

    [Test]
    procedure Item41_InstallCode_CallsInATryFunction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('GuiAllowed', Seed('GUIALLOWED'));
        Observer.Observe('if Codeunit.Run', Seed('IF CODEUNIT.RUN'));
        Observer.Observe('Codeunit.Run statement', Seed('CODEUNIT.RUN STATEMENT'));
        Observer.Observe('Confirm', Seed('CONFIRM'));
        Observer.Observe('Page.RunModal', Seed('PAGE.RUNMODAL'));
        Observer.Observe('Message', Seed('MESSAGE'));
        Observer.Observe('Commit', Seed('COMMIT'));
        Observer.Observe('after Commit', Seed('AFTER COMMIT'));
        Observer.Finish();
    end;

    [Test]
    procedure Item42_AllObjWithCaption_DuringInstall()
    var
        Observer: Codeunit "Probe Observer";
        AtTest: Integer;
    begin
        AtTest := CountOwnObjects();
        Observer.Observe('per company equals test time', Format(Seed('ALLOBJ OWN') = Format(AtTest)));
        Observer.Observe('per company', Seed('ALLOBJ OWN'));
        Observer.Observe('per database', SeedDb('ALLOBJ OWN'));
        Observer.Observe('test time above 1000', Format(AtTest > 1000));
        Observer.Finish();
    end;

    [Test]
    procedure Item43_ModuleInfoVersions_DuringInstall()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        Observer.Observe('per company DataVersion', Seed('DATAVERSION'));
        Observer.Observe('per company AppVersion is the test-time AppVersion', Format(Seed('APPVERSION') = Format(Info.AppVersion)));
        Observer.Observe('per database DataVersion', SeedDb('DATAVERSION'));
        Observer.Observe('per database AppVersion is the test-time AppVersion', Format(SeedDb('APPVERSION') = Format(Info.AppVersion)));
        Observer.Observe('test-time DataVersion is the AppVersion', Format(Format(Info.DataVersion) = Format(Info.AppVersion)));
        Observer.Finish();
    end;
}
