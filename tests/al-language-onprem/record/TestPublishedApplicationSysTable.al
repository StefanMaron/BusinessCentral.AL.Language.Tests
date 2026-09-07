// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-example
// Scope: in-scope, but ONLY for a Target = OnPrem app - see the header note below
// Fixtures used: Assert (60021) and ALT Universal (60000), from the AL Language Coverage Tests app
// BC versions: 27.0+
//
// WHY THIS FILE IS IN THE ONPREM APP AND NOT THE CLOUD ONE
//   Microsoft declares "Published Application" (2000000206) Scope = OnPrem in System.app, so
//   a Target = Cloud app cannot name the record type at all - the compiler rejects it with
//
//     error AL0296: The application object or method 'Published Application' has scope
//                   'OnPrem' and cannot be used for 'Cloud' development
//
//   Half of what is asserted below - the AllObj columns - would compile in the Cloud app.
//   The other half cannot, and the point of every test here is the JOIN between the two, so
//   the file belongs where the join can be written.
//
// WHAT THIS TABLE IS, AND WHY IT IS WORTH PINNING
//   Published Application is the platform's own list of what has been published: one row per
//   published app, keyed on "Runtime Package ID", carrying the app's manifest identity and a
//   pair of package GUIDs. It is the table the System Application consults to answer "which
//   app owns this object", and AllObj (2000000038) carries the other side of that answer in
//   its "App Package ID" / "App Runtime Package ID" columns.
//
//   TestModuleOwnsOwnTable (60405, Cloud app) already pins the CONSEQUENCE: an app may put
//   its own table on the retention-policy allowed list and may not put another app's there.
//   That test cannot say why, because the table that decides it is unnameable from Cloud.
//   These tests pin the layer underneath it, so a platform that answered ownership questions
//   by some other means - or by saying yes to everything - fails here rather than only in the
//   consequence.
//
//   Every assertion is about two apps that this repository itself publishes, so nothing here
//   depends on which Microsoft apps a particular tier happens to carry.
//
// THE THREE FLOWFIELDS, AND WHY "READS FALSE" IS NOT AN ANSWER
//   Published Application carries three FlowFields - Installed, "Tenant Visible" and
//   "PerTenant Or Installed". All three are Boolean, so an implementation that computes
//   NOTHING and one that computes "no" are indistinguishable from AL: both read false.
//
//   That is not hypothetical. Installed was read as false by a consumer of this corpus on the
//   reasoning that it was "a FlowField with nothing behind it", and this file's Installed test
//   is what showed a real tier answering true. The other two were left unmeasured at the time.
//   They are measured here, for the same reason and in the same shape: each pins TRUE, which
//   only a real computation can produce, rather than false, which anything can produce.

codeunit 61201 "Test Published App Sys Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CloudAppIdTok: Label '{a1b2c3d4-e5f6-7890-abcd-ef1234567890}', Locked = true;
        OnPremAppNameTok: Label 'AL Language Coverage Tests (OnPrem)', Locked = true;
        PublisherTok: Label 'AL Language', Locked = true;

    [Test]
    procedure PublishedApplication_Find_ThisAppsId_ReturnsItsManifestIdentity()
    // CLAIM: publishing this app wrote a row that carries the manifest's own name, publisher
    // and four version parts - not blanks, and not the values of some other row.
    var
        PublishedApplication: Record "Published Application";
        ThisModule: ModuleInfo;
        ThisVersion: Version;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);
        ThisVersion := ThisModule.AppVersion();

        PublishedApplication.SetRange(ID, ThisModule.Id());
        Assert.IsTrue(PublishedApplication.FindFirst(), 'This app must have a Published Application row of its own.');

        Assert.AreEqual(OnPremAppNameTok, PublishedApplication.Name, 'Name must be the manifest''s name.');
        Assert.AreEqual(PublisherTok, PublishedApplication.Publisher, 'Publisher must be the manifest''s publisher.');

        // The four version parts are DERIVED from the manifest via ModuleInfo rather than
        // written out as 1/0/0/0, so bumping app.json's "version" cannot break this test with a
        // failure that points nowhere near the manifest. The claim is unchanged: the Published
        // Application row and ModuleInfo must report the same four parts.
        //
        // Guard first, because two surfaces that both reported a zero version would satisfy the
        // four comparisons vacuously. A published app always carries a non-zero version, so this
        // holds across any future bump while still failing an implementation that reports blanks.
        Assert.AreNotEqual('0.0.0.0', Format(ThisVersion), 'ModuleInfo must report a non-zero manifest version, otherwise the comparisons below prove nothing.');

        Assert.AreEqual(ThisVersion.Major(), PublishedApplication."Version Major", 'Version Major must be the manifest version''s first part.');
        Assert.AreEqual(ThisVersion.Minor(), PublishedApplication."Version Minor", 'Version Minor must be the manifest version''s second part.');
        Assert.AreEqual(ThisVersion.Build(), PublishedApplication."Version Build", 'Version Build must be the manifest version''s third part.');
        Assert.AreEqual(ThisVersion.Revision(), PublishedApplication."Version Revision", 'Version Revision must be the manifest version''s fourth part.');

        // The same values ModuleInfo reports, so the two platform surfaces cannot disagree
        // about who this app is.
        Assert.AreEqual(ThisModule.Name(), PublishedApplication.Name, 'Name must agree with ModuleInfo.');
        Assert.AreEqual(ThisModule.Publisher(), PublishedApplication.Publisher, 'Publisher must agree with ModuleInfo.');
    end;

    [Test]
    procedure PublishedApplication_Find_UnknownAppId_ReturnsNoRow()
    // CLAIM: the ID filter selects, it does not match everything. Without this the test above
    // would also pass against a table whose every row answered to every app id.
    var
        PublishedApplication: Record "Published Application";
    begin
        Initialize();

        PublishedApplication.SetRange(ID, CreateGuid());
        Assert.IsTrue(PublishedApplication.IsEmpty(), 'No app was published under a freshly created app id.');
    end;

    [Test]
    procedure PublishedApplication_Get_UnknownRuntimePackageId_RaisesRecordNotFound()
    // CLAIM: "Runtime Package ID" is the primary key and it is not invented for an id nobody
    // published - Get raises the platform's record-not-found error rather than returning a row.
    var
        PublishedApplication: Record "Published Application";
    begin
        Initialize();

        asserterror PublishedApplication.Get(CreateGuid());
        Assert.ExpectedErrorCannotFind(Database::"Published Application");
    end;

    [Test]
    procedure PublishedApplication_Get_ThisAppsRuntimePackageId_ReturnsThisAppsRow()
    // CLAIM: the row found by app id is the row Get returns for that row's "Runtime Package
    // ID" - i.e. that column really is the primary key, and it is not blank, which would make
    // every app's row answer to every other app's lookup.
    var
        PublishedApplication: Record "Published Application";
        ThisModule: ModuleInfo;
        RuntimePackageId: Guid;
        EmptyId: Guid;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);

        PublishedApplication.SetRange(ID, ThisModule.Id());
        Assert.IsTrue(PublishedApplication.FindFirst(), 'This app must have a Published Application row of its own.');
        RuntimePackageId := PublishedApplication."Runtime Package ID";
        Assert.AreNotEqual(EmptyId, RuntimePackageId, 'A published app must carry a non-blank Runtime Package ID.');

        Clear(PublishedApplication);
        PublishedApplication.Get(RuntimePackageId);
        Assert.AreEqual(ThisModule.Id(), PublishedApplication.ID, 'Get on the Runtime Package ID must return this app''s row.');
    end;

    [Test]
    procedure PublishedApplication_TwoApps_DoNotShareEitherPackageId()
    // CLAIM: the two apps this repository publishes are told apart by both GUID columns. A
    // platform that stamped one shared value would let either app's ownership check answer
    // for the other.
    var
        ThisApp: Record "Published Application";
        CloudApp: Record "Published Application";
        ThisModule: ModuleInfo;
        CloudAppId: Guid;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);
        Evaluate(CloudAppId, CloudAppIdTok);

        ThisApp.SetRange(ID, ThisModule.Id());
        Assert.IsTrue(ThisApp.FindFirst(), 'This app must have a Published Application row of its own.');

        CloudApp.SetRange(ID, CloudAppId);
        Assert.IsTrue(CloudApp.FindFirst(), 'The Cloud coverage app this one depends on must be listed too.');
        Assert.AreEqual('AL Language Coverage Tests', CloudApp.Name, 'The row found by app id must be the Cloud coverage app''s.');

        Assert.AreNotEqual(
            ThisApp."Runtime Package ID", CloudApp."Runtime Package ID",
            'Two published apps must not share a Runtime Package ID.');
        Assert.AreNotEqual(
            ThisApp."Package ID", CloudApp."Package ID",
            'Two published apps must not share a Package ID.');
    end;

    [Test]
    procedure PublishedApplication_ThisApp_PackageIdIsItsRuntimePackageId()
    // CLAIM: within ONE row the two GUID columns carry the same value.
    //
    // Measured, and the reason this test exists rather than its opposite. The first revision
    // of this file asserted that the two columns differ, on the reading that publishing
    // assigns them independently. All eight BC legs, 27.0 through 28.4, of run 34023230684
    // disagreed: every one reported the two columns equal for this app. So the pair does not
    // discriminate within a row - what tells two apps apart is the values differing BETWEEN
    // rows, which the test above pins.
    //
    // What this does NOT claim: that they are equal for every app on every tier. An app
    // republished over an earlier version can carry a runtime package id from the later
    // publish. The claim is about a freshly published app, which is what this tier has.
    var
        ThisApp: Record "Published Application";
        ThisModule: ModuleInfo;
        EmptyId: Guid;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);

        ThisApp.SetRange(ID, ThisModule.Id());
        Assert.IsTrue(ThisApp.FindFirst(), 'This app must have a Published Application row of its own.');

        Assert.AreNotEqual(EmptyId, ThisApp."Package ID", 'A published app must carry a non-blank Package ID.');
        Assert.AreEqual(
            ThisApp."Package ID", ThisApp."Runtime Package ID",
            'A freshly published app carries one GUID in both package columns.');
    end;

    [Test]
    procedure AllObj_AppRuntimePackageId_ThisAppsObject_IdentifiesThisApp()
    // CLAIM: AllObj stamps an object with its owning app's runtime package id, and that id
    // resolves through Published Application back to this app. This is the join the System
    // Application's module-ownership check makes, asserted end to end.
    var
        PublishedApplication: Record "Published Application";
        AllObj: Record AllObj;
        ThisModule: ModuleInfo;
        EmptyId: Guid;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);

        AllObj.Get(AllObj."Object Type"::Codeunit, Codeunit::"Test Published App Sys Table");
        Assert.AreNotEqual(EmptyId, AllObj."App Runtime Package ID", 'An object of a published app must carry its app''s runtime package id.');

        PublishedApplication.Get(AllObj."App Runtime Package ID");
        Assert.AreEqual(ThisModule.Id(), PublishedApplication.ID, 'The runtime package id on this app''s own object must resolve to this app.');
        Assert.AreEqual(
            AllObj."App Package ID", PublishedApplication."Package ID",
            'The App Package ID column must be the same app''s Package ID, not a second unrelated value.');
    end;

    [Test]
    procedure AllObj_AppRuntimePackageId_AnotherAppsTable_IdentifiesThatApp()
    // CLAIM: the negative half, and what stops the test above passing for a platform that
    // stamped one value on everything. ALT Universal (60000) belongs to the Cloud coverage
    // app, so its AllObj row must resolve to THAT app and not to this one.
    var
        PublishedApplication: Record "Published Application";
        AllObj: Record AllObj;
        ThisApp: Record "Published Application";
        ThisModule: ModuleInfo;
        CloudAppId: Guid;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);
        Evaluate(CloudAppId, CloudAppIdTok);

        ThisApp.SetRange(ID, ThisModule.Id());
        Assert.IsTrue(ThisApp.FindFirst(), 'This app must have a Published Application row of its own.');

        AllObj.Get(AllObj."Object Type"::Table, Database::"ALT Universal");
        Assert.AreNotEqual(
            ThisApp."Runtime Package ID", AllObj."App Runtime Package ID",
            'A table another app owns must not carry this app''s runtime package id.');

        PublishedApplication.Get(AllObj."App Runtime Package ID");
        Assert.AreEqual(CloudAppId, PublishedApplication.ID, 'ALT Universal must resolve to the app that declares it.');
    end;

    [Test]
    procedure PublishedApplication_CalcFields_Installed_IsTrueForThisApp()
    // CLAIM: Installed is a FlowField over "Installed Application" (2000000212) matched on
    // "Runtime Package ID". An app whose test codeunits are running is installed, so it reads
    // true - which is not the Boolean default, so a FlowField that computed nothing fails here.
    var
        PublishedApplication: Record "Published Application";
        ThisModule: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);

        PublishedApplication.SetRange(ID, ThisModule.Id());
        Assert.IsTrue(PublishedApplication.FindFirst(), 'This app must have a Published Application row of its own.');

        PublishedApplication.CalcFields(Installed);
        Assert.IsTrue(PublishedApplication.Installed, 'The app whose tests are running must read as installed.');
    end;

    [Test]
    procedure PublishedApplication_CalcFields_TenantVisible_IsTrueForThisApp()
    // CLAIM: "Tenant Visible" is a Lookup FlowField over "NAV App Extra" (2000000157) matched
    // on "Runtime Package ID". An app that is published and whose test codeunits are running
    // is visible to the tenant running them, so it reads true.
    //
    // WHY THIS IS WORTH ASKING. The column reads FALSE where nothing computes it, and false is
    // also the Boolean default, so the two are indistinguishable from the outside. That is
    // exactly the shape that made the Installed assertion below wrong for a long time before
    // this repository measured it: an implementation that computes nothing looks identical to
    // one that computes "no". Pinning true here separates them, because true is a value only a
    // real computation can produce.
    var
        PublishedApplication: Record "Published Application";
        ThisModule: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);

        PublishedApplication.SetRange(ID, ThisModule.Id());
        Assert.IsTrue(PublishedApplication.FindFirst(), 'This app must have a Published Application row of its own.');

        PublishedApplication.CalcFields("Tenant Visible");
        Assert.IsTrue(PublishedApplication."Tenant Visible", 'The app whose tests are running must be visible to this tenant.');
    end;

    [Test]
    procedure PublishedApplication_CalcFields_PerTenantOrInstalled_IsTrueForThisApp()
    // CLAIM: "PerTenant Or Installed" is the second Lookup FlowField over "NAV App Extra",
    // matched on the same "Runtime Package ID". An app that is installed in this tenant
    // satisfies the "Or Installed" half however it was scoped, so it reads true.
    //
    // Same reasoning as the test above about why true rather than false is the claim worth
    // pinning: false is unfalsifiable here, true is not.
    var
        PublishedApplication: Record "Published Application";
        ThisModule: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);

        PublishedApplication.SetRange(ID, ThisModule.Id());
        Assert.IsTrue(PublishedApplication.FindFirst(), 'This app must have a Published Application row of its own.');

        PublishedApplication.CalcFields("PerTenant Or Installed");
        Assert.IsTrue(PublishedApplication."PerTenant Or Installed", 'The app whose tests are running must read as per-tenant or installed.');
    end;

    [Test]
    procedure PublishedApplication_CalcFields_BothFlowFields_AlsoTrueForTheOtherApp()
    // CLAIM: the two tests above are not passing because THIS app happens to be special. The
    // Cloud coverage app this one depends on is a second, separately published app with its
    // own "Runtime Package ID", and it must answer the same way.
    //
    // What this adds over the two tests above: it forces the lookup to be performed for a
    // SECOND key. An implementation that answered the first row correctly and every other row
    // by default would pass both tests above and fail this one.
    var
        CloudApp: Record "Published Application";
        CloudAppId: Guid;
    begin
        Initialize();
        Evaluate(CloudAppId, CloudAppIdTok);

        CloudApp.SetRange(ID, CloudAppId);
        Assert.IsTrue(CloudApp.FindFirst(), 'The Cloud coverage app this one depends on must be listed too.');
        Assert.AreEqual('AL Language Coverage Tests', CloudApp.Name, 'The row found by app id must be the Cloud coverage app''s.');

        CloudApp.CalcFields("Tenant Visible", "PerTenant Or Installed", Installed);
        Assert.IsTrue(CloudApp."Tenant Visible", 'The other published app must be visible to this tenant too.');
        Assert.IsTrue(CloudApp."PerTenant Or Installed", 'The other published app must read as per-tenant or installed too.');
        Assert.IsTrue(CloudApp.Installed, 'The other published app is installed - this app depends on it, so it cannot not be.');
    end;

    [Test]
    procedure PublishedApplication_CalcFields_UnpublishedRuntimePackageId_HasNoRowToLookUp()
    // CLAIM: the negative half. The three FlowFields resolve through "Runtime Package ID", and
    // a runtime package id nobody published has no Published Application row at all - so there
    // is nothing for CalcFields to be called on. Without this the tests above would also pass
    // against a platform whose every row answered to every id.
    var
        PublishedApplication: Record "Published Application";
    begin
        Initialize();

        PublishedApplication.SetRange("Runtime Package ID", CreateGuid());
        Assert.IsTrue(PublishedApplication.IsEmpty(), 'No app was published under a freshly created runtime package id.');
    end;

    local procedure Initialize()
    begin
        // "Published Application" is a read-only platform table written by publishing, not by
        // test code -- nothing to DeleteAll.
    end;
}
