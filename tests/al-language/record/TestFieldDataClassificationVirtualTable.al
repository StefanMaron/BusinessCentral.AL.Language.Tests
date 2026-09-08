// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataclassification-property
// Scope: in-scope
// Fixtures used: ALT Field Classification Fix (60965) — see TestFieldDataClassificationFixture.Table.al;
//                ALT Universal (60000) as the TableRelation target.
//
// What a table's own compiled metadata says about its fields, read back through the surfaces AL
// has for it: the "Field" system virtual table (2000000041) for DataClassification and the
// relation columns, RecordRef/FieldRef for the system fields and the key list.
//
// Each assertion names a concrete value, and the four DataClassification rows are four
// DIFFERENT values, so a provider answering a constant — the table-level default is the
// tempting one — fails three of them.

codeunit 60965 "Test Field Classification VTbl"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Field_DataClassification_PerField_ReportsEachDeclaredValue()
    var
        FieldRow: Record Field;
    begin
        // [GIVEN] a table whose four data fields each declare a different DataClassification
        // [THEN] each row reports its OWN declared value, not the table's default
        Assert.IsTrue(FieldRow.Get(Database::"ALT Field Classification Fix", 2), 'Field has no row for field 2.');
        Assert.AreEqual(FieldRow.DataClassification::EndUserIdentifiableInformation, FieldRow.DataClassification,
            'Field 2 declares DataClassification = EndUserIdentifiableInformation.');

        Assert.IsTrue(FieldRow.Get(Database::"ALT Field Classification Fix", 3), 'Field has no row for field 3.');
        Assert.AreEqual(FieldRow.DataClassification::AccountData, FieldRow.DataClassification,
            'Field 3 declares DataClassification = AccountData.');

        Assert.IsTrue(FieldRow.Get(Database::"ALT Field Classification Fix", 4), 'Field has no row for field 4.');
        Assert.AreEqual(FieldRow.DataClassification::SystemMetadata, FieldRow.DataClassification,
            'Field 4 declares DataClassification = SystemMetadata.');

        Assert.IsTrue(FieldRow.Get(Database::"ALT Field Classification Fix", 5), 'Field has no row for field 5.');
        Assert.AreEqual(FieldRow.DataClassification::CustomerContent, FieldRow.DataClassification,
            'Field 5 declares DataClassification = CustomerContent.');
    end;

    [Test]
    procedure Field_DataClassification_UndeclaredField_InheritsTheTableDefault()
    var
        FieldRow: Record Field;
    begin
        // [GIVEN] field 1 declares no DataClassification and the table declares CustomerContent
        // [THEN] the field row reports the table's default — the one row where the constant a
        //        naive provider would answer happens to be right, kept as the control
        Assert.IsTrue(FieldRow.Get(Database::"ALT Field Classification Fix", 1), 'Field has no row for field 1.');
        Assert.AreEqual(FieldRow.DataClassification::CustomerContent, FieldRow.DataClassification,
            'Field 1 declares none, so it takes the table''s CustomerContent.');
    end;

    [Test]
    procedure Field_RelationTableNo_DeclaredTableRelation_NamesTheTargetTable()
    var
        FieldRow: Record Field;
    begin
        // [GIVEN] field 5 declares TableRelation = "ALT Universal"."Entry No."
        Assert.IsTrue(FieldRow.Get(Database::"ALT Field Classification Fix", 5), 'Field has no row for field 5.');

        // [THEN] the relation columns name that table and that field, by number
        Assert.AreEqual(Database::"ALT Universal", FieldRow.RelationTableNo,
            'RelationTableNo must be ALT Universal (60000).');
        Assert.AreEqual(1, FieldRow.RelationFieldNo,
            'RelationFieldNo must be 1 ("Entry No." on ALT Universal).');
    end;

    [Test]
    procedure Field_RelationTableNo_FieldWithoutARelation_ReportsZero()
    var
        FieldRow: Record Field;
    begin
        // Negative control for the test above: a field declaring no TableRelation reports 0,
        // so the positive result cannot come from a provider that stamps one table id on
        // every row.
        Assert.IsTrue(FieldRow.Get(Database::"ALT Field Classification Fix", 2), 'Field has no row for field 2.');
        Assert.AreEqual(0, FieldRow.RelationTableNo,
            'A field with no TableRelation must report RelationTableNo = 0.');
    end;

    [Test]
    procedure RecordRef_SystemCreatedBy_Relation_IsTheUserTable()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        // [GIVEN] the platform's own SystemCreatedBy field (2000000002) on an ordinary table
        RecRef.Open(Database::"ALT Field Classification Fix");
        FldRef := RecRef.Field(2000000002);

        // [THEN] it relates to User (2000000120) — the relation the platform gives it, which
        // nothing in the table's AL source declares
        Assert.AreEqual(Database::User, FldRef.Relation(),
            'SystemCreatedBy must relate to the User table (2000000120).');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_OrdinaryField_Relation_IsZero()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        // Negative control: a field declaring no TableRelation has no relation.
        RecRef.Open(Database::"ALT Field Classification Fix");
        FldRef := RecRef.Field(2);
        Assert.AreEqual(0, FldRef.Relation(),
            'A field with no TableRelation must report Relation() = 0.');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_KeyIndex_SecondaryKey_IsTheDeclaredOne()
    var
        RecRef: RecordRef;
        KeyRef: KeyRef;
        FldRef: FieldRef;
    begin
        // [GIVEN] a table declaring two keys: PK on "Code" and ByAccountData on "Account Data"
        RecRef.Open(Database::"ALT Field Classification Fix");

        // [THEN] both are present and in declaration order, by field number rather than by
        // count — a table that lost its secondary key would still answer KeyCount >= 1
        KeyRef := RecRef.KeyIndex(1);
        FldRef := KeyRef.FieldIndex(1);
        Assert.AreEqual(1, FldRef.Number(), 'Key 1 must be the primary key, on field 1 ("Code").');

        KeyRef := RecRef.KeyIndex(2);
        FldRef := KeyRef.FieldIndex(1);
        Assert.AreEqual(3, FldRef.Number(), 'Key 2 must be ByAccountData, on field 3 ("Account Data").');

        RecRef.Close();
    end;
}
