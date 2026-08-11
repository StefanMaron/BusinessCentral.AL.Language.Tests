// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: ALT ObsoleteState Fixture (60984) — see TestFieldObsoleteStateFixture.Table.al
//
// Pins the built-in "Field" system virtual table (2000000041)'s ObsoleteState/ObsoleteReason
// columns for a field declared ObsoleteState = Removed / Pending, and the undeclared default
// (No). The row for a Removed field is present in the Field table (BusinessCentral.AL.Runner
// issue #1780's earlier symptom was "row present, ObsoleteState reads No" — a naive provider
// that answers every row's ObsoleteState with the constant No would satisfy a check that only
// looks at the Removed field; the Pending case and the SetRange filter checks below rule that
// degenerate implementation out, and the negative test proves a Live field never matches a
// Removed-state filter.

codeunit 60956 "Test Field ObsoleteState VTbl"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Field_Get_LiveField_ReportsObsoleteStateNo()
    var
        FieldRow: Record Field;
    begin
        Initialize();

        Assert.IsTrue(FieldRow.Get(Database::"ALT ObsoleteState Fixture", 2), 'Field has no row for "Live Field".');
        Assert.AreEqual(FieldRow.ObsoleteState::No, FieldRow.ObsoleteState, 'Live Field must report ObsoleteState = No.');
        Assert.AreEqual('', FieldRow.ObsoleteReason, 'Live Field must report a blank ObsoleteReason.');
    end;

    [Test]
    procedure Field_Get_PendingField_ReportsObsoleteStatePending()
    var
        FieldRow: Record Field;
    begin
        Initialize();

        Assert.IsTrue(FieldRow.Get(Database::"ALT ObsoleteState Fixture", 3), 'Field has no row for "Pending Field".');
        Assert.AreEqual(FieldRow.ObsoleteState::Pending, FieldRow.ObsoleteState, 'Pending Field must report ObsoleteState = Pending.');
        Assert.AreEqual('pending in fixture', FieldRow.ObsoleteReason, 'Pending Field must report its declared ObsoleteReason.');
    end;

    [Test]
    procedure Field_Get_RemovedField_ReportsObsoleteStateRemoved()
    var
        FieldRow: Record Field;
    begin
        Initialize();

        Assert.IsTrue(FieldRow.Get(Database::"ALT ObsoleteState Fixture", 4), 'Field has no row for "Removed Field".');
        Assert.AreEqual(FieldRow.ObsoleteState::Removed, FieldRow.ObsoleteState, 'Removed Field must report ObsoleteState = Removed.');
        Assert.AreEqual('removed in fixture', FieldRow.ObsoleteReason, 'Removed Field must report its declared ObsoleteReason.');
    end;

    [Test]
    procedure Field_SetRange_ObsoleteStateRemoved_ReturnsOnlyTheRemovedField()
    var
        FieldRow: Record Field;
    begin
        Initialize();

        // [WHEN] filtering the Field table for this table's Removed rows
        FieldRow.SetRange(TableNo, Database::"ALT ObsoleteState Fixture");
        FieldRow.SetRange(ObsoleteState, FieldRow.ObsoleteState::Removed);

        // [THEN] exactly one row matches — field 4, "Removed Field" — not zero (#1780's
        // symptom) and not more than the one field actually declared Removed.
        Assert.RecordCount(FieldRow, 1);
        Assert.IsTrue(FieldRow.FindFirst(), 'Expected exactly one Removed-state row.');
        Assert.AreEqual(4, FieldRow."No.", 'The single Removed-state row must be field 4.');
    end;

    [Test]
    procedure Field_SetRange_ObsoleteStateRemoved_ExcludesLiveAndPendingFields()
    var
        FieldRow: Record Field;
    begin
        Initialize();

        // Negative control: neither the Live (No) nor the Pending field must match a
        // Removed-state filter. A provider that answered every row's ObsoleteState with a
        // fixed value would fail either this test or the positive one above.
        FieldRow.SetRange(TableNo, Database::"ALT ObsoleteState Fixture");
        FieldRow.SetRange("No.", 2, 3);
        FieldRow.SetRange(ObsoleteState, FieldRow.ObsoleteState::Removed);
        Assert.IsTrue(FieldRow.IsEmpty(), 'Live/Pending fields must not report ObsoleteState = Removed.');
    end;

    local procedure Initialize()
    begin
        // Field is a read-only system virtual table — nothing to DeleteAll.
    end;
}
