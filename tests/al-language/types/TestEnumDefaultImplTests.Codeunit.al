// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al
// Scope: in-scope
// Fixtures used: EDI Greeter (interface), EDI Kind (60309), EDI Default Impl (60310),
//                EDI Own Impl (60311), EDI Unknown Impl (60312)
//
// CLAIM: an enum can name its implementing codeunit in three places -- per value with
// `Implementation`, once for the whole enum with `DefaultImplementation`, and for
// ordinals it does not declare with `UnknownValueImplementation` -- and assigning an
// enum value to an interface variable resolves them in that order.
//
// An enum that declares ONLY DefaultImplementation still casts to its interface. Base
// Application enum 205 "Alt. Cust VAT Reg. Doc." is written exactly that way and
// Codeunit 207 "Alt. Cust. VAT Reg. Orchest." casts it on every Sales Header insert.
//
// Each implementation returns a distinct string, so a resolver that always landed on
// one of them could not pass more than one of these tests.
codeunit 60313 "EDI Default Impl Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure EnumInterface_ValueWithoutOwnImplementation_UsesDefaultImplementation()
    var
        Greeter: Interface "EDI Greeter";
    begin
        // [SCENARIO] "Falls Back" declares no Implementation of its own, so the cast
        //            must reach the enum-level DefaultImplementation.
        Initialize();

        Greeter := Enum::"EDI Kind"::"Falls Back";

        Assert.AreEqual('DEFAULT', Greeter.Greet(),
            'a value with no Implementation must dispatch to the enum DefaultImplementation');
    end;

    [Test]
    procedure EnumInterface_ValueWithOwnImplementation_PrefersItOverTheDefault()
    var
        Greeter: Interface "EDI Greeter";
    begin
        // [SCENARIO] "Has Own" declares its own Implementation, which outranks the
        //            enum-level default -- the first step of the fallback.
        Initialize();

        Greeter := Enum::"EDI Kind"::"Has Own";

        Assert.AreEqual('OWN', Greeter.Greet(),
            'a value with its own Implementation must dispatch to that, not to the DefaultImplementation');
    end;

    [Test]
    procedure EnumInterface_UndeclaredOrdinal_UsesUnknownValueImplementation()
    var
        Kind: Enum "EDI Kind";
        Greeter: Interface "EDI Greeter";
    begin
        // [SCENARIO] Ordinal 99 is not declared by the enum, so neither of the first two
        //            steps applies and the cast must reach UnknownValueImplementation.
        Initialize();

        Kind := "EDI Kind".FromInteger(99);
        Assert.AreEqual(99, Kind.AsInteger(), 'FromInteger(99) must carry the undeclared ordinal through');

        Greeter := Kind;

        Assert.AreEqual('UNKNOWN', Greeter.Greet(),
            'an ordinal the enum does not declare must dispatch to UnknownValueImplementation');
    end;

    [Test]
    procedure EnumInterface_DeclaredOrdinalThroughFromInteger_StillUsesTheDeclaredChain()
    var
        Kind: Enum "EDI Kind";
        Greeter: Interface "EDI Greeter";
    begin
        // [SCENARIO] The negative direction for the previous test: reaching the value
        //            through FromInteger is not itself what selects
        //            UnknownValueImplementation -- a DECLARED ordinal still runs the
        //            normal chain.
        Initialize();

        Kind := "EDI Kind".FromInteger(0);
        Greeter := Kind;
        Assert.AreEqual('DEFAULT', Greeter.Greet(),
            'declared ordinal 0 must still fall back to DefaultImplementation, not to UnknownValueImplementation');

        Kind := "EDI Kind".FromInteger(1);
        Greeter := Kind;
        Assert.AreEqual('OWN', Greeter.Greet(),
            'declared ordinal 1 must still use its own Implementation');
    end;
}
