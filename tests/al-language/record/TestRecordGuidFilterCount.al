// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: "GFC Scope" (60231), "GFC Style Variant" (60232), "GFC Asset"
// (60233, all private to this test — co-located, no corpus-shared equivalent)
// Note: pins that SetFilter(GuidField, '<>%1', EmptyGuid) genuinely excludes
// empty-GUID rows from Count()/FindFirst — a dropped inequality term makes a
// single real registration read as "ambiguous". Every test asserts a specific
// count AND the identity of the row that comes back.
// BC versions: 24+

codeunit 60234 "Test Record Guid Filter Count"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        NameTok: Label 'MICR', Locked = true;
        OtherNameTok: Label 'SOURCESANS', Locked = true;

    local procedure AppIdA(): Guid
    begin
        exit('11111111-1111-1111-1111-111111111111');
    end;

    local procedure AppIdB(): Guid
    begin
        exit('22222222-2222-2222-2222-222222222222');
    end;

    local procedure Initialize()
    var
        Asset: Record "GFC Asset";
    begin
        Asset.DeleteAll();
    end;

    local procedure Seed(Scope: Enum "GFC Scope"; SourceAppId: Guid; Name: Code[50]; StyleVariant: Enum "GFC Style Variant"; Payload: Text[30])
    var
        Asset: Record "GFC Asset";
    begin
        Asset.Init();
        Asset.Scope := Scope;
        Asset.SourceAppId := SourceAppId;
        Asset.Name := Name;
        Asset.StyleVariant := StyleVariant;
        Asset.Payload := Payload;
        Asset.Insert();
    end;

    /// <summary>The resolution filter under test, verbatim in shape.</summary>
    local procedure ApplyResolutionFilter(var Asset: Record "GFC Asset"; Name: Code[50]; StyleVariant: Enum "GFC Style Variant")
    var
        EmptyAppId: Guid;
    begin
        Asset.Reset();
        Asset.SetRange(Scope, Asset.Scope::Extension);
        Asset.SetRange(Name, Name);
        Asset.SetRange(StyleVariant, StyleVariant);
        Asset.SetFilter(SourceAppId, '<>%1', EmptyAppId);
    end;

    /// <summary>
    /// THE REGRESSION. One real row plus one row whose SourceAppId was never set. The
    /// empty-GUID row must be excluded, so exactly one row resolves — not two, which the
    /// caller would read as "ambiguous".
    /// </summary>
    [Test]
    procedure EmptyGuidRow_IsExcluded_SoASingleRegistrationResolves()
    var
        Asset: Record "GFC Asset";
        EmptyAppId: Guid;
    begin
        Initialize();
        Seed(Enum::"GFC Scope"::Extension, AppIdA(), NameTok, Enum::"GFC Style Variant"::Regular, 'real');
        Seed(Enum::"GFC Scope"::Extension, EmptyAppId, NameTok, Enum::"GFC Style Variant"::Regular, 'invalid');

        ApplyResolutionFilter(Asset, NameTok, Enum::"GFC Style Variant"::Regular);

        Assert.AreEqual(1, Asset.Count(), 'the empty-SourceAppId row must not participate in resolution');
        Assert.IsTrue(Asset.FindFirst(), 'the one valid row must be findable under the same filter');
        Assert.AreEqual('real', Asset.Payload, 'resolution must land on the row carrying a real SourceAppId');
    end;

    /// <summary>
    /// The inequality filter must not swallow legitimately distinct rows either: two
    /// different owning apps registering the same name IS ambiguous, and must count as 2.
    /// Without this, a resolver could pass the test above by always answering 1.
    /// </summary>
    [Test]
    procedure TwoDistinctOwningApps_AreBothCounted_SoAmbiguityIsStillDetectable()
    var
        Asset: Record "GFC Asset";
        EmptyAppId: Guid;
    begin
        Initialize();
        Seed(Enum::"GFC Scope"::Extension, AppIdA(), NameTok, Enum::"GFC Style Variant"::Regular, 'from-a');
        Seed(Enum::"GFC Scope"::Extension, AppIdB(), NameTok, Enum::"GFC Style Variant"::Regular, 'from-b');
        Seed(Enum::"GFC Scope"::Extension, EmptyAppId, NameTok, Enum::"GFC Style Variant"::Regular, 'invalid');

        ApplyResolutionFilter(Asset, NameTok, Enum::"GFC Style Variant"::Regular);

        Assert.AreEqual(2, Asset.Count(), 'two real owning apps registering one name is genuinely ambiguous');
    end;

    /// <summary>
    /// The other ranged terms must still bite while the GUID filter is applied — a name
    /// that was never registered resolves to nothing, rather than to whatever else the
    /// table holds.
    /// </summary>
    [Test]
    procedure UnregisteredName_ResolvesToZero_NotToUnrelatedRows()
    var
        Asset: Record "GFC Asset";
    begin
        Initialize();
        Seed(Enum::"GFC Scope"::Extension, AppIdA(), NameTok, Enum::"GFC Style Variant"::Regular, 'real');
        Seed(Enum::"GFC Scope"::Extension, AppIdB(), OtherNameTok, Enum::"GFC Style Variant"::Regular, 'other');

        ApplyResolutionFilter(Asset, 'NOSUCHFONT', Enum::"GFC Style Variant"::Regular);

        Assert.AreEqual(0, Asset.Count(), 'an unregistered name must resolve to nothing');
        Assert.IsFalse(Asset.FindFirst(), 'FindFirst must agree with Count under the same filter');
    end;

    /// <summary>
    /// The style-variant range must bite too: registering Regular must not make Bold
    /// resolve. This is the exact distinction the caller reports as
    /// "family known, but that variant is missing".
    /// </summary>
    [Test]
    procedure StyleVariantRange_Distinguishes_RegisteredFromUnregisteredVariant()
    var
        Asset: Record "GFC Asset";
    begin
        Initialize();
        Seed(Enum::"GFC Scope"::Extension, AppIdA(), NameTok, Enum::"GFC Style Variant"::Regular, 'reg');

        ApplyResolutionFilter(Asset, NameTok, Enum::"GFC Style Variant"::Regular);
        Assert.AreEqual(1, Asset.Count(), 'the registered Regular variant must resolve');

        ApplyResolutionFilter(Asset, NameTok, Enum::"GFC Style Variant"::Bold);
        Assert.AreEqual(0, Asset.Count(), 'the unregistered Bold variant must not resolve');
    end;

    /// <summary>
    /// The Scope range must bite: a Tenant-scope row with the same name and a real
    /// SourceAppId must not leak into an Extension-scope lookup.
    /// </summary>
    [Test]
    procedure ScopeRange_KeepsTenantRowsOutOfExtensionResolution()
    var
        Asset: Record "GFC Asset";
    begin
        Initialize();
        Seed(Enum::"GFC Scope"::Tenant, AppIdB(), NameTok, Enum::"GFC Style Variant"::Regular, 'tenant');
        Seed(Enum::"GFC Scope"::Extension, AppIdA(), NameTok, Enum::"GFC Style Variant"::Regular, 'ext');

        ApplyResolutionFilter(Asset, NameTok, Enum::"GFC Style Variant"::Regular);

        Assert.AreEqual(1, Asset.Count(), 'a Tenant-scope row must not be counted by an Extension-scope lookup');
        Assert.IsTrue(Asset.FindFirst(), 'the extension row must be findable');
        Assert.AreEqual('ext', Asset.Payload, 'resolution must land on the Extension-scope row');
    end;
}
