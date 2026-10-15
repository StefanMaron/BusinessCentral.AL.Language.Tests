// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Universal (60000), ALT Keyed (60006)
// BC versions: 27.0+
//
// CLAIM UNDER TEST: boxing a Record into a Variant and unboxing it back into a typed Record
// carries the CURRENT RECORD's field values but NOT the surrounding record state. A plain
// Record assignment copies field values only — filters and the current key are left behind,
// exactly as they are on a direct `Rec2 := Rec1` assignment. The Variant round trip adds no
// state of its own: a Variant passed by value isolates the caller, one passed by var does not.
// The filter and key tests carry the direct assignment as a control, so they show the Variant
// hop drops nothing that the assignment itself keeps.
//
// Measured on W1 sandboxes BC 27.0 (27.0.38460.56409), 28.5 (28.5.54151.56408) and 29.0
// (29.0.54011.55816): every assertion holds unchanged on all three, so no version guard.

codeunit 69500 "Test Record Variant RoundTrip"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure RoundTrip_FieldValues_Survive()
    // CLAIM: the current record's field values cross Record -> Variant -> Record unchanged.
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        V: Variant;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 42;
        Rec."Text Field" := 'boxed';

        V := Rec;
        Rec2 := V;

        Assert.AreEqual(1, Rec2."Entry No.", 'Entry No. must survive the Variant round trip');
        Assert.AreEqual(42, Rec2."Integer Field", 'Integer Field must survive the Variant round trip');
        Assert.AreEqual('boxed', Rec2."Text Field", 'Text Field must survive the Variant round trip');
    end;

    [Test]
    procedure RoundTrip_Filters_AreLost()
    // CLAIM: a plain assignment copies the current record, not its filters; the Variant hop keeps it so.
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        Direct: Record "ALT Universal";
        V: Variant;
    begin
        Initialize();
        Rec.SetRange("Entry No.", 1, 5);
        Rec.SetFilter("Integer Field", '>%1', 10);
        Assert.AreNotEqual('', Rec.GetFilters(), 'the source carries filters before the round trip');

        V := Rec;
        Rec2 := V;
        Direct := Rec;

        Assert.AreEqual('', Rec2.GetFilters(), 'filters must NOT cross the Variant round trip — assignment copies the record, not the view');
        Assert.AreEqual('', Direct.GetFilters(), 'control: a direct assignment does not copy the filters either');
    end;

    [Test]
    procedure RoundTrip_CurrentKey_IsDefault()
    // CLAIM: the current key is not carried; the target sorts on its default (primary) key.
    var
        Rec: Record "ALT Keyed";
        Rec2: Record "ALT Keyed";
        Fresh: Record "ALT Keyed";
        Direct: Record "ALT Keyed";
        V: Variant;
    begin
        Initialize();
        Rec.SetCurrentKey(Amount);
        Assert.AreNotEqual(Fresh.CurrentKey(), Rec.CurrentKey(), 'the source is on a non-default key before the round trip');

        V := Rec;
        Rec2 := V;
        Direct := Rec;

        Assert.AreEqual(Fresh.CurrentKey(), Rec2.CurrentKey(), 'the current key must NOT cross the Variant round trip — the target is on its default key');
        Assert.AreEqual(Fresh.CurrentKey(), Direct.CurrentKey(), 'control: a direct assignment does not copy the current key either');
    end;

    [Test]
    procedure VariantByValue_CalleeReassign_NotSeen()
    // CLAIM: a Variant passed by value isolates the caller from a reassignment in the callee.
    var
        Rec: Record "ALT Universal";
        Readback: Record "ALT Universal";
        V: Variant;
    begin
        Initialize();
        Rec."Entry No." := 1;
        V := Rec;

        ReassignVariantByValue(V);

        Readback := V;
        Assert.AreEqual(1, Readback."Entry No.", 'a Variant passed by value must NOT see the callee''s reassignment');
    end;

    [Test]
    procedure VariantByRef_CalleeReassign_Seen()
    // CLAIM: a Variant passed by var does see a reassignment in the callee.
    var
        Rec: Record "ALT Universal";
        Readback: Record "ALT Universal";
        V: Variant;
    begin
        Initialize();
        Rec."Entry No." := 1;
        V := Rec;

        ReassignVariantByRef(V);

        Readback := V;
        Assert.AreEqual(999, Readback."Entry No.", 'a Variant passed by var must see the callee''s reassignment');
    end;

    local procedure ReassignVariantByValue(V: Variant)
    var
        Other: Record "ALT Universal";
    begin
        Other."Entry No." := 999;
        V := Other;
    end;

    local procedure ReassignVariantByRef(var V: Variant)
    var
        Other: Record "ALT Universal";
    begin
        Other."Entry No." := 999;
        V := Other;
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
