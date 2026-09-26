// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-getenumvalueordinal-method
// Scope: in-scope
// Fixtures used: Assert (60021), ALT Field Enum Type Fix (60470; field 2 = Enum "ALT Field Enum Kind",
//                ordinals 0, 5, 10; field 3 = Option Alpha,Beta,Gamma), ALT Field Enum Kind (60469),
//                TPEDO Row (67485; field 2 = Enum "TPEDO Kind", declared order 4, 0, 1, 2),
//                TPEDO Kind (67485), TPEDO Kind Ext (67485).
//
// CLAIM: FieldRef.GetEnumValueOrdinal(Index), GetEnumValueCaption(Index) and
// GetEnumValueName(Index) take a 1-based POSITION in the enum's declared value list and answer
// the ordinal, caption and name of the value at that position. When the ordinals are not
// 0, 1, 2, ... in declared order -- a gapped enum (0, 5, 10) or an extended one whose base value
// is declared first (4, then 0, 1, 2) -- the ordinal is the declared one, never Index - 1, and
// the caption is that value's own caption. An Index outside 1..EnumValueCount() answers -1 for
// the ordinal and an empty caption. Codeunit 60131 covers only a contiguous 0..4 enum, where
// position and ordinal coincide and cannot be told apart.
//
// Written by agent stma-auto2-2, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4798. The expected
// values were written before any BC service tier ran them; this pull request's CI is the first
// real-BC measurement.

codeunit 67486 "FieldRef Enum Ordinal By Index"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure GappedKindField(var RecRef: RecordRef; var FldRef: FieldRef)
    begin
        RecRef.Open(Database::"ALT Field Enum Type Fix");
        FldRef := RecRef.Field(2);
    end;

    local procedure DeclaredOrderKindField(var RecRef: RecordRef; var FldRef: FieldRef)
    begin
        RecRef.Open(Database::"TPEDO Row");
        FldRef := RecRef.Field(2);
    end;

    // ── Gapped enum: ordinals 0, 5, 10 ─────────────────────────────────────────

    [Test]
    procedure GappedEnum_GetEnumValueOrdinal_ReturnsDeclaredOrdinals()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        GappedKindField(RecRef, FldRef);
        Assert.AreEqual(3, FldRef.EnumValueCount(), 'EnumValueCount() of ALT Field Enum Kind');
        Assert.AreEqual(0, FldRef.GetEnumValueOrdinal(1), 'GetEnumValueOrdinal(1) is the ordinal of Unassigned');
        Assert.AreEqual(5, FldRef.GetEnumValueOrdinal(2), 'GetEnumValueOrdinal(2) is the ordinal of Middle, not the position 1');
        Assert.AreEqual(10, FldRef.GetEnumValueOrdinal(3), 'GetEnumValueOrdinal(3) is the ordinal of Far Out, not the position 2');
    end;

    [Test]
    procedure GappedEnum_GetEnumValueCaption_ReturnsThatValuesCaption()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        GappedKindField(RecRef, FldRef);
        Assert.AreEqual('Not assigned', FldRef.GetEnumValueCaption(1), 'GetEnumValueCaption(1)');
        Assert.AreEqual('Middle', FldRef.GetEnumValueCaption(2), 'GetEnumValueCaption(2): a value with no Caption answers its name');
        Assert.AreEqual('Far out value', FldRef.GetEnumValueCaption(3), 'GetEnumValueCaption(3)');
    end;

    [Test]
    procedure GappedEnum_GetEnumValueName_ReturnsThatValuesName()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        GappedKindField(RecRef, FldRef);
        Assert.AreEqual('Unassigned', FldRef.GetEnumValueName(1), 'GetEnumValueName(1)');
        Assert.AreEqual('Far Out', FldRef.GetEnumValueName(3), 'GetEnumValueName(3)');
    end;

    [Test]
    procedure GappedEnum_IndexOutOfRange_AnswersMinusOneAndEmpty()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        GappedKindField(RecRef, FldRef);
        Assert.AreEqual(-1, FldRef.GetEnumValueOrdinal(0), 'GetEnumValueOrdinal(0) is below the 1-based range');
        Assert.AreEqual(-1, FldRef.GetEnumValueOrdinal(4), 'GetEnumValueOrdinal(4) is past the last of 3 values');
        Assert.AreEqual('', FldRef.GetEnumValueCaption(4), 'GetEnumValueCaption(4) is past the last of 3 values');
    end;

    // ── Declared order is not ordinal order: 4, then 0, 1, 2 ───────────────────

    [Test]
    procedure DeclaredOrderEnum_GetEnumValueOrdinal_FollowsDeclaredOrder()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        DeclaredOrderKindField(RecRef, FldRef);
        Assert.AreEqual(4, FldRef.EnumValueCount(), 'EnumValueCount() of TPEDO Kind with its extension');
        Assert.AreEqual(4, FldRef.GetEnumValueOrdinal(1), 'GetEnumValueOrdinal(1) is the base value Zulu, ordinal 4');
        Assert.AreEqual(0, FldRef.GetEnumValueOrdinal(2), 'GetEnumValueOrdinal(2) is Alpha, ordinal 0');
        Assert.AreEqual(1, FldRef.GetEnumValueOrdinal(3), 'GetEnumValueOrdinal(3) is Beta, ordinal 1');
        Assert.AreEqual(2, FldRef.GetEnumValueOrdinal(4), 'GetEnumValueOrdinal(4) is Gamma, ordinal 2');
    end;

    [Test]
    procedure DeclaredOrderEnum_GetEnumValueCaption_FollowsDeclaredOrder()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        DeclaredOrderKindField(RecRef, FldRef);
        Assert.AreEqual('Zulu caption', FldRef.GetEnumValueCaption(1), 'GetEnumValueCaption(1)');
        Assert.AreEqual('Alpha caption', FldRef.GetEnumValueCaption(2), 'GetEnumValueCaption(2)');
        Assert.AreEqual('Beta caption', FldRef.GetEnumValueCaption(3), 'GetEnumValueCaption(3)');
        Assert.AreEqual('Gamma caption', FldRef.GetEnumValueCaption(4), 'GetEnumValueCaption(4)');
        Assert.AreEqual('Zulu', FldRef.GetEnumValueName(1), 'GetEnumValueName(1)');
    end;

    // ── Control: a plain Option field, whose ordinal IS its position ───────────

    [Test]
    procedure PlainOption_GetEnumValueOrdinal_IsPositionMinusOne()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(Database::"ALT Field Enum Type Fix");
        FldRef := RecRef.Field(3);
        Assert.AreEqual(0, FldRef.GetEnumValueOrdinal(1), 'Option Alpha is ordinal 0');
        Assert.AreEqual(2, FldRef.GetEnumValueOrdinal(3), 'Option Gamma is ordinal 2');
        Assert.AreEqual('Gamma', FldRef.GetEnumValueCaption(3), 'Option Gamma caption');
    end;
}
