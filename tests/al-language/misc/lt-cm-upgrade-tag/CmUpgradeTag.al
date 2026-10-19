// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-upgrading-extensions
// Scope: in-scope
// Fixtures used: Upgrade Tag (codeunit 9999, System Application), Probe Observer (69160); own codeunit 84836 (manual subscriber).
// Facts: corpus issue 669 (odd AL behavior leads, part D), item 44. Upgrade Tag called from a test session: HasUpgradeTag before and after
//   SetUpgradeTag, SetUpgradeTag twice, HasUpgradeTag for another company, SetAllUpgradeTags with a bound OnGetPerCompanyUpgradeTags
//   subscriber, and a company inserted while that subscriber is bound.
// BC versions: 27, 28, 29

codeunit 84835 "LT CM Upgrade Tag"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Item44_HasAndSetUpgradeTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('has before set', Format(UpgradeTag.HasUpgradeTag('LT-CM-TAG-1')));
        UpgradeTag.SetUpgradeTag('LT-CM-TAG-1');
        Observer.Observe('has after set', Format(UpgradeTag.HasUpgradeTag('LT-CM-TAG-1')));
        Observer.Observe('has for own company', Format(UpgradeTag.HasUpgradeTag('LT-CM-TAG-1', CopyStr(CompanyName(), 1, 30))));
        Observer.Observe('has for other company', Format(UpgradeTag.HasUpgradeTag('LT-CM-TAG-1', 'LT CM NO SUCH CO')));
        Observer.Observe('has for database', Format(UpgradeTag.HasUpgradeTag('LT-CM-TAG-1', '')));
        // A second SetUpgradeTag with the same tag raises no error (BC 29 local run: asserterror failed with "An error was expected").
        UpgradeTag.SetUpgradeTag('LT-CM-TAG-1');
        Observer.Observe('has after second set', Format(UpgradeTag.HasUpgradeTag('LT-CM-TAG-1')));
        Observer.Expect('has before set', 'No');
        Observer.Expect('has after set', 'Yes');
        Observer.Expect('has for own company', 'Yes');
        Observer.Expect('has for other company', 'No');
        Observer.Expect('has for database', 'No');
        Observer.Expect('has after second set', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Item44_SetAllUpgradeTags_WithSubscriber()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Subs: Codeunit "LT CM Upgrade Tag Subs";
        Observer: Codeunit "Probe Observer";
    begin
        UpgradeTag.SetAllUpgradeTags();
        Observer.Observe('unbound: has after SetAllUpgradeTags', Format(UpgradeTag.HasUpgradeTag('LT-CM-TAG-2')));
        BindSubscription(Subs);
        UpgradeTag.SetAllUpgradeTags();
        Observer.Observe('bound: has after SetAllUpgradeTags', Format(UpgradeTag.HasUpgradeTag('LT-CM-TAG-2')));
        UpgradeTag.SetAllUpgradeTags();
        Observer.Observe('bound: SetAllUpgradeTags again', Format(UpgradeTag.HasUpgradeTag('LT-CM-TAG-2')));
        UnbindSubscription(Subs);
        Observer.Expect('unbound: has after SetAllUpgradeTags', 'No');
        Observer.Expect('bound: has after SetAllUpgradeTags', 'Yes');
        Observer.Expect('bound: SetAllUpgradeTags again', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Item44_NewCompany_GetsTheSubscriberTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Subs: Codeunit "LT CM Upgrade Tag Subs";
        Company: Record Company;
        Observer: Codeunit "Probe Observer";
    begin
        BindSubscription(Subs);
        Company.Init();
        Company.Name := 'LT CM NEW CO';
        Company.Insert();
        UnbindSubscription(Subs);
        Observer.Observe('new company has the tag', Format(UpgradeTag.HasUpgradeTag('LT-CM-TAG-2', 'LT CM NEW CO')));
        Observer.Observe('own company has the tag', Format(UpgradeTag.HasUpgradeTag('LT-CM-TAG-2')));
        Observer.Expect('new company has the tag', 'Yes');
        Observer.Expect('own company has the tag', 'No');
        Observer.Verify();
    end;
}

codeunit 84836 "LT CM Upgrade Tag Subs"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure AddTag(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add('LT-CM-TAG-2');
    end;
}
