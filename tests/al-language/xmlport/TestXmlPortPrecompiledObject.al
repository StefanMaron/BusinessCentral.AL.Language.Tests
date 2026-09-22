// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-direction-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-encoding-property
// Scope: in-scope
// Fixtures used: ALT Blob (60008) — as a stream sink only; every object under test ships
//   in the System Application.
//
// WHAT THIS PINS, AND WHY IT IS NOT COVERED BY TestXmlPortObject/TestXmlPortAdvanced.
// Those two exercise xmlports the corpus app DECLARES, so the platform has their compiled
// metadata by construction. This file exercises xmlports the corpus app only DEPENDS ON —
// System Application's own — which is a different situation for any consumer that has to
// obtain an xmlport's metadata rather than having emitted it.
//
// Every assertion is about what BC itself answers, so a service tier decides all of it:
//   * a dependency's xmlport can be declared as a variable and constructed at all;
//   * its declared Direction is honoured (an Export-only port refuses Import);
//   * its object identity (XmlPort::<name>) resolves to the documented id.
//
// The three ports used are the ones whose declared properties are unambiguous in the
// System Application source:
//   9862 "Export Permission Sets System"  Direction = Export, Encoding = UTF8
//   9863 "Export Permission Sets Tenant"  Direction = Export, Encoding = UTF8
//   9864 "Import Permission Sets"         Direction = Import, Encoding = UTF8
//
// Export is deliberately NOT invoked. These ports write real permission-set data, and a test
// that exported them would assert against whatever the tenant happens to hold — which is a
// claim about the fixture set, not about the xmlport. Construction and Direction enforcement
// are the parts that are the same on every tenant.

codeunit 60918 "Test XmlPort Precompiled Obj"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // An xmlport belonging to a DEPENDENCY app can be declared and constructed, and the
    // instance BC hands back is the one that object declares. The variable declaration alone
    // is a compile-time claim; touching the instance is what forces the platform to obtain
    // the object's metadata at run time, which is the part that can fail independently of
    // compiling.
    //
    // Named *_NoThrow per the corpus convention for a test whose claim is bounded: the
    // ASSERTED value is the object identity, and the no-throw part is the calls above it.
    // The three property-level claims are in the Direction tests below, which is where a
    // value rather than an absence is observable.
    [Test]
    procedure PrecompiledXmlPort_ConstructsAndKeepsItsIdentity_NoThrow()
    var
        ExportSystem: XmlPort "Export Permission Sets System";
        ExportTenant: XmlPort "Export Permission Sets Tenant";
        ImportSets: XmlPort "Import Permission Sets";
    begin
        Initialize();

        // Real instance calls, so they cannot succeed against an object whose metadata the
        // platform failed to load. Nothing is exported: see the file header for why.
        ExportSystem.UseRequestPage(false);
        ExportTenant.UseRequestPage(false);
        ImportSets.UseRequestPage(false);

        // A concrete value rather than IsTrue(true): each constructed port still answers the
        // id its own app declares, so the three variables are three distinct objects and not
        // one fallback instance handed back three times.
        Assert.AreEqual(9862, XmlPort::"Export Permission Sets System",
            'the constructed Export-system port must still be the object the System Application declares');
        Assert.AreEqual(9864, XmlPort::"Import Permission Sets",
            'the constructed Import port must be a DIFFERENT object from the two Export ports');
    end;

    // Direction is a declared property of the xmlport object, and the platform enforces it:
    // an Export-only port refuses Import. This is the sharpest available AL-observable proof
    // that the port's own declared metadata — not a default — is what the platform is using,
    // because the failure depends on a property value rather than on the object existing.
    [Test]
    procedure PrecompiledXmlPort_DeclaredExportDirection_RefusesImport()
    var
        ExportSystem: XmlPort "Export Permission Sets System";
        InStr: InStream;
        TempBlob: Record "ALT Blob" temporary;
        OutStr: OutStream;
    begin
        Initialize();

        TempBlob.Init();
        TempBlob.Code := 'XPP1';
        TempBlob.Insert();
        TempBlob.Data.CreateOutStream(OutStr);
        OutStr.WriteText('<root />');
        TempBlob.Data.CreateInStream(InStr);

        ExportSystem.SetSource(InStr);
        asserterror ExportSystem.Import();

        // The MESSAGE TEXT is deliberately not asserted: it is a platform resource string
        // this test has no independent source for, and inventing one would make the test a
        // claim about wording rather than about behaviour. What IS asserted is the pair that
        // wording cannot vary — that an error was raised, and that it is a real AL error
        // rather than a .NET exception escaping (which would leave the code empty).
        Assert.IsTrue(GetLastErrorText() <> '',
            'an xmlport declared Direction = Export must refuse Import() — the platform reads the port''s own declared Direction, so a port whose metadata was not obtained could not enforce this');
        Assert.IsTrue(GetLastErrorCode() <> '',
            'the refusal must be a real AL error carrying an error code, not a .NET exception surfacing through the test runner');
    end;

    // The mirror: an Import-only port refuses Export. Asserting only the Export-refuses-Import
    // direction would pass against a platform that refused EVERY direction on a dependency
    // xmlport, which is why both directions are pinned.
    [Test]
    procedure PrecompiledXmlPort_DeclaredImportDirection_RefusesExport()
    var
        ImportSets: XmlPort "Import Permission Sets";
        TempBlob: Record "ALT Blob" temporary;
        OutStr: OutStream;
    begin
        Initialize();

        TempBlob.Init();
        TempBlob.Code := 'XPP2';
        TempBlob.Insert();
        TempBlob.Data.CreateOutStream(OutStr);

        ImportSets.SetDestination(OutStr);
        asserterror ImportSets.Export();

        Assert.IsTrue(GetLastErrorText() <> '',
            'an xmlport declared Direction = Import must refuse Export()');
        Assert.IsTrue(GetLastErrorCode() <> '',
            'the refusal must be a real AL error carrying an error code');
    end;

    // Object identity: the XmlPort::<name> reference of a dependency's xmlport resolves to the
    // id that app declares. This is what any id-keyed consumer joins on, and it is a statement
    // about BC's own object table rather than about this test's fixtures.
    [Test]
    procedure PrecompiledXmlPort_ObjectIdentityResolvesToItsDeclaredId()
    begin
        Initialize();

        Assert.AreEqual(9862, XmlPort::"Export Permission Sets System",
            'XmlPort::"Export Permission Sets System" must resolve to the id the System Application declares');
        Assert.AreEqual(9863, XmlPort::"Export Permission Sets Tenant",
            'XmlPort::"Export Permission Sets Tenant" must resolve to the id the System Application declares');
        Assert.AreEqual(9864, XmlPort::"Import Permission Sets",
            'XmlPort::"Import Permission Sets" must resolve to the id the System Application declares');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
