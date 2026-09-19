// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/administration-custom-cds-integration
// Scope: in-scope (Cloud-compatible) -- the page is driven from a [Test] through TestPage, with
//   no client and no Dataverse connection. The procedures behind it are Scope('OnPrem') and so
//   cannot be called directly from this Cloud-target app; the page is the Cloud-reachable
//   surface that consumes them, which is what makes this claim expressible here at all.
// Fixtures used: shared Assert (60021)
// BC versions: 27.0+
//
/// <summary>
/// CLAIM: opening the CDS Connection Setup page (7200) on a company that has no
/// "CDS Connection Setup" row succeeds, and the page's "SDK Version" control comes back holding
/// a positive proxy version that the platform chose -- not zero, and not an unset field.
///
/// WHY THIS IS A STATEMENT ABOUT BC, not about any particular host:
///
/// Page 7200's OnOpenPage takes its first-open branch when Rec.Get() is false, and that branch
/// calls InitializeDefaultProxyVersion -> CDSIntegrationImpl.GetLastProxyVersionItem(). That
/// procedure fills a `Record TempStack temporary` from the DotNet CrmHelper.GetProxyIdList()
/// and then calls TempStack.FindLast(). So the page can only open if the platform has proxy
/// versions registered: an empty list makes FindLast raise "The TempStack table is empty" and
/// the page never opens at all.
///
/// The registry those ids come from is populated by the platform at startup, from the CRM proxy
/// assemblies it ships. That is a platform responsibility and invisible from AL, which is
/// exactly why it needs a service tier to adjudicate rather than a host's own opinion.
///
/// WHAT IS PINNED HERE, and what each test would catch if it broke:
///
///   1. THE PAGE OPENS. PageOpens_OnACompanyWithNoSetupRow drives the first-open branch --
///      the one that resolves the default proxy version -- and would fail with BC's own
///      empty-table error if the platform had no proxy version registered.
///   2. THE VALUE IS A REAL ONE. The "SDK Version" control (the page's caption over
///      Rec."Proxy Version") must hold a POSITIVE integer. This is the arm that separates
///      "the page opened" from "the page opened and the default was resolved": a host that
///      let the page open while leaving the field at its 0 default would pass test 1 and
///      fail here.
///   3. IT IS STABLE ACROSS OPENS. Re-opening the page answers the same version. The
///      registry is process state rather than per-open work, so a second open must not
///      produce a different number -- and this is the arm that would catch a host deriving
///      the value from something that changes between opens.
///
/// DELIBERATELY NOT PINNED: the exact integer. It is the major version of the CRM SDK the
/// platform ships, so it moves when Microsoft ships a newer SDK, and pinning it would make
/// this suite fail on a BC update that is working correctly. Positive-and-stable is the
/// strongest claim that stays true across versions.
/// </summary>
codeunit 60584 "ALT CDS Conn Setup Proxy Ver"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure PageOpens_OnACompanyWithNoSetupRow()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
    begin
        // The first-open branch is the one that resolves the default proxy version, so the row
        // must not exist when the page opens. Deleting it is what guarantees Rec.Get() is false.
        if CDSConnectionSetup.Get() then
            CDSConnectionSetup.Delete();

        CDSConnectionSetupPage.OpenEdit();

        // Reaching this line already means OnOpenPage completed: the FindLast over the
        // proxy-version stack did not raise BC's empty-table error.
        Assert.IsTrue(CDSConnectionSetupPage."SDK Version".AsInteger() > 0,
            'The CDS Connection Setup page must open with a positive default proxy version.');

        CDSConnectionSetupPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure DefaultProxyVersion_IsStableAcrossOpens()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupPage: TestPage "CDS Connection Setup";
        FirstVersion: Integer;
        SecondVersion: Integer;
    begin
        if CDSConnectionSetup.Get() then
            CDSConnectionSetup.Delete();

        CDSConnectionSetupPage.OpenEdit();
        FirstVersion := CDSConnectionSetupPage."SDK Version".AsInteger();
        CDSConnectionSetupPage.Close();

        // Same starting state, so the same answer: the registry the value comes from is
        // platform state established once, not work redone per open.
        if CDSConnectionSetup.Get() then
            CDSConnectionSetup.Delete();

        CDSConnectionSetupPage.OpenEdit();
        SecondVersion := CDSConnectionSetupPage."SDK Version".AsInteger();
        CDSConnectionSetupPage.Close();

        Assert.IsTrue(FirstVersion > 0, 'The first open must resolve a positive proxy version.');
        Assert.AreEqual(FirstVersion, SecondVersion,
            'Re-opening the page must resolve the same default proxy version.');
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // The page's OnQueryClosePage confirms on exit while the connection is disabled, which
        // it always is here -- no Dataverse connection is made by any test in this suite.
        Reply := true;
    end;
}
