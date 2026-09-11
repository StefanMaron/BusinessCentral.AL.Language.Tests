// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-using-enums
// Scope: in-scope
// Fixtures used: none -- the subject is System Application enum 2616 "Printer Paper Kind",
//                which the test app already depends on.
//
// CLAIM: a shipped enum's value ordinals are exactly what the enum declares, including
// the value whose ordinal is ZERO, and they are all distinct.
//
// "Printer Paper Kind" (System.Device, System Application 2616) is the interesting one
// because its 68 values are NOT declared in ordinal order: its ordinals mirror
// System.Drawing.Printing.PaperKind, so A3 is 8, A4 is 9 and GermanStandardFanfold is
// 40, while Custom -- the value whose ordinal is 0 -- is the LAST one in the object.
//
// A consumer that derived an unstated ordinal from declaration order rather than reading
// the declared value would answer 40 for Custom and collide with GermanStandardFanfold,
// leaving the enum with 67 distinct ordinals across 68 values. Both assertions below
// would catch that, from opposite directions.
codeunit 60036 "Enum Shipped Ordinal Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure ShippedEnum_ValueWithOrdinalZero_AnswersZero()
    var
        PaperKind: Enum "Printer Paper Kind";
    begin
        // [SCENARIO] Custom is declared last but its ordinal is 0.
        PaperKind := PaperKind::Custom;

        Assert.AreEqual(0, PaperKind.AsInteger(),
            'Printer Paper Kind::Custom is ordinal 0, whatever its position in the object');
    end;

    [Test]
    procedure ShippedEnum_OrdinalsFollowTheDeclaredValues_NotDeclarationOrder()
    var
        PaperKind: Enum "Printer Paper Kind";
    begin
        // [SCENARIO] The values around Custom, each asserted to its declared ordinal.
        //            A3 and A4 are adjacent in declaration order AND in ordinal, so on
        //            their own they cannot distinguish the two rules; GermanStandardFanfold
        //            and Custom can.
        PaperKind := PaperKind::A3;
        Assert.AreEqual(8, PaperKind.AsInteger(), 'Printer Paper Kind::A3 is ordinal 8');

        PaperKind := PaperKind::A4;
        Assert.AreEqual(9, PaperKind.AsInteger(), 'Printer Paper Kind::A4 is ordinal 9');

        PaperKind := PaperKind::GermanStandardFanfold;
        Assert.AreEqual(40, PaperKind.AsInteger(),
            'Printer Paper Kind::GermanStandardFanfold is ordinal 40');
    end;

    [Test]
    procedure ShippedEnum_ZeroOrdinalValueIsDistinctFromTheOthers()
    var
        Custom: Enum "Printer Paper Kind";
        Fanfold: Enum "Printer Paper Kind";
    begin
        // [SCENARIO] The consequence that makes a wrong ordinal more than a wrong number:
        //            two distinct enum values must not share an ordinal, or Format() and
        //            equality can answer either name for that value.
        Custom := Custom::Custom;
        Fanfold := Fanfold::GermanStandardFanfold;

        Assert.AreNotEqual(Custom.AsInteger(), Fanfold.AsInteger(),
            'two distinct Printer Paper Kind values must not share an ordinal');

        Assert.IsFalse(Custom = Fanfold,
            'Custom and GermanStandardFanfold are different enum values');
    end;

    [Test]
    procedure ShippedEnum_OrdinalsRoundTripThroughFromInteger()
    var
        FromZero: Enum "Printer Paper Kind";
        FromForty: Enum "Printer Paper Kind";
        Custom: Enum "Printer Paper Kind";
        Fanfold: Enum "Printer Paper Kind";
    begin
        // [SCENARIO] The reverse direction: ordinal 0 resolves back to Custom and 40 to
        //            GermanStandardFanfold. Compared against the MEMBER, not against a
        //            formatted string: these values carry captions that differ from their
        //            names, so Format() is a separate question this test does not ask.
        Custom := Custom::Custom;
        Fanfold := Fanfold::GermanStandardFanfold;

        FromZero := Enum::"Printer Paper Kind".FromInteger(0);
        FromForty := Enum::"Printer Paper Kind".FromInteger(40);

        Assert.IsTrue(FromZero = Custom, 'ordinal 0 of Printer Paper Kind is Custom');
        Assert.IsTrue(FromForty = Fanfold,
            'ordinal 40 of Printer Paper Kind is GermanStandardFanfold');
        Assert.IsFalse(FromZero = FromForty,
            'ordinals 0 and 40 must not resolve to the same Printer Paper Kind value');
    end;
}
