// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataclassification-property
// Scope: in-scope
// Fixtures used: ALT DC Inheritance Fix (60967) — see DcInheritanceFix.Table.al.
//
// What a field's DataClassification is when the FIELD declares none. The documentation says
// the table-level value applies; these tests ask a service tier whether that holds for every
// field or only for the fields BC actually classifies.
//
// TestFieldDataClassificationVirtualTable.al (#292) already pins the two easy rows: a field
// that declares its own value reports it, and a silent field on a CustomerContent table
// reports CustomerContent. That second row cannot distinguish inheritance from a constant,
// because the inherited value and the default are the same word. Here the table declares
// SystemMetadata, so the two come apart: a silent field inheriting reports SystemMetadata and
// a silent field NOT inheriting reports CustomerContent, and each test names which it expects.
//
// The FlowField row asks a different question from the other three, and is here because the
// answer is easy to predict wrongly: a field whose FieldClass is not Normal reports
// SystemMetadata whatever the table and the field declare, so the table-level value cannot be
// read off that row in either direction. Field 2 declaring CustomerContent on the same
// SystemMetadata table is what stops that row being read as inheritance.
//
// All four fields are read through the same surface, the "Field" system virtual table
// (2000000041), so nothing here depends on a difference between two providers.

codeunit 60972 "Test Field DC Inheritance"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure FieldDcInherit_SilentOrdinaryField_ReportsTheTableValue()
    var
        FieldRow: Record Field;
    begin
        // [GIVEN] field 1 declares no DataClassification, on a table declaring SystemMetadata
        Assert.IsTrue(FieldRow.Get(Database::"ALT DC Inheritance Fix", 1), 'Field has no row for field 1.');
        // [THEN] it reports the table's value, not the CustomerContent default
        Assert.AreEqual(FieldRow.DataClassification::SystemMetadata, FieldRow.DataClassification,
            'A field declaring no DataClassification takes the table''s SystemMetadata.');
    end;

    [Test]
    procedure FieldDcInherit_FieldWithItsOwnValue_KeepsIt()
    var
        FieldRow: Record Field;
    begin
        // [GIVEN] field 2 declares CustomerContent while the table declares SystemMetadata
        Assert.IsTrue(FieldRow.Get(Database::"ALT DC Inheritance Fix", 2), 'Field has no row for field 2.');
        // [THEN] its own declaration wins — the negative control for the test above
        Assert.AreEqual(FieldRow.DataClassification::CustomerContent, FieldRow.DataClassification,
            'A field declaring CustomerContent keeps it on a SystemMetadata table.');
    end;

    [Test]
    procedure FieldDcInherit_SilentBlobField_ReportsCustomerContent()
    var
        FieldRow: Record Field;
    begin
        // [GIVEN] field 3 is a Blob declaring no DataClassification, table declares SystemMetadata
        Assert.IsTrue(FieldRow.Get(Database::"ALT DC Inheritance Fix", 3), 'Field has no row for field 3.');
        // [THEN] it does NOT take the table's value
        Assert.AreEqual(FieldRow.DataClassification::CustomerContent, FieldRow.DataClassification,
            'A silent Blob field is not classified from the table.');
    end;

    [Test]
    procedure FieldDcInherit_FlowField_ReportsSystemMetadataWhateverTheTableSays()
    var
        FieldRow: Record Field;
    begin
        // [GIVEN] field 4 is a FlowField declaring no DataClassification, table declares SystemMetadata
        Assert.IsTrue(FieldRow.Get(Database::"ALT DC Inheritance Fix", 4), 'Field has no row for field 4.');
        // [THEN] SystemMetadata — and NOT because the table says so. Any field whose FieldClass
        // is not Normal reports SystemMetadata; field 2 on this same table declares
        // CustomerContent and keeps it, so this row is not the table's value leaking through.
        Assert.AreEqual(FieldRow.DataClassification::SystemMetadata, FieldRow.DataClassification,
            'A FlowField reports SystemMetadata.');
    end;
}
