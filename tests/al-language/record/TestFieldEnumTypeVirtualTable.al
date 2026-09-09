// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-using-enums
// Scope: in-scope
// Fixtures used: ALT Field Enum Type Fix (60470) and ALT Field Enum Kind (60469) —
//                see TestFieldEnumTypeFixture.Table.al / TestFieldEnumTypeFixture.Enum.al.
//
// What the "Field" system virtual table (2000000041) reports for a field whose type is an AL
// ENUM object, as opposed to a plain Option field that declares its own OptionMembers.
//
// The two differ in where the option metadata comes from: an Option field carries its members
// inline, while an Enum field only names an enum OBJECT, which the platform must resolve to
// answer OptionString at all. That resolution is the whole subject here. The enum's ordinals
// are deliberately sparse (0, 5, 10), so a reader that treats an AL ordinal as a 0..Count-1
// array index is separated from one that resolves the real object.

codeunit 60471 "Test Field Enum Type VTbl"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Field_EnumTypedField_OptionStringNamesTheEnumsMembers()
    var
        FieldRow: Record Field;
        Members: List of [Text];
    begin
        // [GIVEN] field 2 is typed by enum "ALT Field Enum Kind", which declares three values
        Assert.IsTrue(FieldRow.Get(Database::"ALT Field Enum Type Fix", 2),
            'Field has no row for the Enum-typed field 2.');

        // [THEN] OptionString carries the ENUM OBJECT's members, comma-joined. Naming each
        //        member rather than only the count: a provider answering some other enum's
        //        members would still produce three.
        Members := FieldRow.OptionString.Split(',');
        Assert.AreEqual(3, Members.Count(),
            'OptionString for an Enum-typed field must state the enum''s three values.');
        Assert.AreEqual('Unassigned', Members.Get(1),
            'The first value of enum "ALT Field Enum Kind" is Unassigned.');
        Assert.AreEqual('Middle', Members.Get(2),
            'The second value of enum "ALT Field Enum Kind" is Middle.');
        Assert.AreEqual('Far Out', Members.Get(3),
            'The third value of enum "ALT Field Enum Kind" is "Far Out" — the quotes are AL syntax, not part of the name.');
    end;

    [Test]
    procedure Field_EnumTypedField_TypeIsReportedAsOption()
    var
        FieldRow: Record Field;
    begin
        // [GIVEN] field 2 is declared `Enum "ALT Field Enum Kind"` in AL
        Assert.IsTrue(FieldRow.Get(Database::"ALT Field Enum Type Fix", 2),
            'Field has no row for the Enum-typed field 2.');

        // [THEN] the Field table reports the underlying storage type, which for an enum is
        //        Option — an enum is not a separate Type value on this table
        Assert.AreEqual(FieldRow.Type::Option, FieldRow.Type,
            'An Enum-typed field is reported as Type::Option by the Field virtual table.');
    end;

    [Test]
    procedure Field_PlainOptionField_OptionStringNamesItsInlineMembers()
    var
        FieldRow: Record Field;
        Members: List of [Text];
    begin
        // [GIVEN] field 3 is a plain Option field declaring OptionMembers inline
        Assert.IsTrue(FieldRow.Get(Database::"ALT Field Enum Type Fix", 3),
            'Field has no row for the Option field 3.');

        // [THEN] its OptionString is its OWN members, not the enum's — the control that keeps
        //        the enum assertion above from passing on a provider that answers one constant
        Members := FieldRow.OptionString.Split(',');
        Assert.AreEqual(3, Members.Count(),
            'OptionString for the plain Option field must state its three inline members.');
        Assert.AreEqual('Alpha', Members.Get(1), 'Field 3 declares OptionMembers = Alpha,Beta,Gamma.');
        Assert.AreEqual('Beta', Members.Get(2), 'Field 3 declares OptionMembers = Alpha,Beta,Gamma.');
        Assert.AreEqual('Gamma', Members.Get(3), 'Field 3 declares OptionMembers = Alpha,Beta,Gamma.');
    end;

    [Test]
    procedure Field_NonOptionField_HasNoOptionString()
    var
        FieldRow: Record Field;
    begin
        // [GIVEN] field 4 is a Text field — neither an enum nor an option
        Assert.IsTrue(FieldRow.Get(Database::"ALT Field Enum Type Fix", 4),
            'Field has no row for the Text field 4.');

        // [THEN] OptionString is empty. The negative half: a provider that answered SOME
        //        option string for every row would pass the two positives above and fail here.
        Assert.AreEqual('', FieldRow.OptionString,
            'A Text field declares no options, so OptionString is blank.');
        Assert.AreEqual(FieldRow.Type::Text, FieldRow.Type, 'Field 4 is declared Text[30].');
    end;

    [Test]
    procedure Field_EnumTypedField_SparseOrdinalsSurviveTheRoundTrip()
    var
        Fixture: Record "ALT Field Enum Type Fix";
        Kind: Enum "ALT Field Enum Kind";
    begin
        // [GIVEN] the enum's ordinals are 0, 5, 10 — not 0, 1, 2
        // [THEN] each member's ordinal is its DECLARED value, so a reader using the member's
        //        position in the list answers 1 and 2 where BC answers 5 and 10
        Assert.AreEqual(0, Kind::Unassigned.AsInteger(), 'value(0; Unassigned).');
        Assert.AreEqual(5, Kind::Middle.AsInteger(), 'value(5; Middle).');
        Assert.AreEqual(10, Kind::"Far Out".AsInteger(), 'value(10; "Far Out").');

        // [AND] a value stored in the enum-typed field reads back as the same ordinal
        Fixture.Init();
        Fixture."Entry No." := 1;
        Fixture.Kind := Kind::"Far Out";
        Fixture.Insert();

        Assert.IsTrue(Fixture.Get(1), 'The inserted fixture row must be readable.');
        Assert.AreEqual(10, Fixture.Kind.AsInteger(),
            'The stored enum value keeps its declared ordinal 10, not its list position 2.');
    end;
}
