// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extend-enums
// Scope: in-scope
// Fixtures used: EEI Marker (interface), EEI impls (60890-60892), EEI Kind (60893),
//                EEI Kind Ext (enumextension 60890)
//
// Written for AL Runner issue #4197, reported by an outside contributor: an enumextension
// supplies the Implementation for an interface declared on the enum it extends, and the
// runner did not resolve it. The existing "EEM Tests" (60888) already pin that an
// extension's values reach Ordinals() and Names(); NONE of them casts an extension-added
// value to the enum's interface, which is the step that failed. That gap is what these add.
//
// Why each implementation returns a distinct string: "EEM Interface".HandleAction returns
// nothing, so a cast resolving to the WRONG codeunit, or falling back to the enum's
// DefaultImplementation, is indistinguishable from the right one. A marker makes the
// implementation that actually ran the thing asserted.
codeunit 60916 "EEI Enum Ext Impl Tests"
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
    procedure EnumExtValue_WithOwnImplementation_DispatchesToIt()
    var
        Marker: Interface "EEI Marker";
    begin
        // [SCENARIO] A value an ENUMEXTENSION adds, declaring its own Implementation,
        //            dispatches to that implementation.
        Initialize();

        Marker := Enum::"EEI Kind"::Extended;

        Assert.AreEqual('EXTENSION', Marker.Marker(),
            'an enumextension value must dispatch to the Implementation the extension declares');
    end;

    [Test]
    procedure EnumExtValue_WithNoImplementation_FallsBackToTheBaseEnumDefault()
    var
        Marker: Interface "EEI Marker";
    begin
        // [SCENARIO] A value the enumextension adds WITHOUT an Implementation reaches the
        //            BASE enum's DefaultImplementation -- an enumextension declares no
        //            DefaultImplementation of its own.
        Initialize();

        Marker := Enum::"EEI Kind"::"Extended No Impl";

        Assert.AreEqual('DEFAULT', Marker.Marker(),
            'an enumextension value with no Implementation must reach the base enum DefaultImplementation');
    end;

    [Test]
    procedure BaseEnumValue_StillDispatchesToItsOwnImplementation()
    var
        Marker: Interface "EEI Marker";
    begin
        // [SCENARIO] The base enum's own value is unaffected by the extension -- the
        //            other direction of the merge, which a clobbering registration breaks.
        Initialize();

        Marker := Enum::"EEI Kind"::Base;

        Assert.AreEqual('BASE', Marker.Marker(),
            'the base enum value must keep dispatching to its own Implementation');
    end;

    [Test]
    procedure ExtendedOrdinalAndBaseOrdinal_AreBothPresent()
    var
        Ordinals: List of [Integer];
    begin
        // [SCENARIO] Base declares 1 value (0); the extension adds 2 (10, 20).
        Initialize();

        Ordinals := Enum::"EEI Kind".Ordinals();

        Assert.AreEqual(3, Ordinals.Count(), 'expected 1 base ordinal + 2 extension ordinals');
        Assert.IsTrue(Ordinals.Contains(0), 'base ordinal 0 must be present');
        Assert.IsTrue(Ordinals.Contains(10), 'extension ordinal 10 must be present');
        Assert.IsTrue(Ordinals.Contains(20), 'extension ordinal 20 must be present');
    end;
}
