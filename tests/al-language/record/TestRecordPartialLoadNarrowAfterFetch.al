// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-partial-records
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setloadfields-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-arefieldsloaded-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Universal (60000); shared Assert (60021)
// BC versions: 27.0+
//
// WHAT THIS MEASURES, AND WHY 60775 DOES NOT ALREADY COVER IT.
//
// Codeunit 60775 "Test Record Partial Load" pins five claims about partial records, and every
// one of its tests RE-FETCHES (Get / FindFirst) between changing the load set and asking
// AreFieldsLoaded. That is the shape the BC documentation describes, and it leaves one
// ordering unmeasured:
//
//     fetch  ->  SetLoadFields(narrower)  ->  AreFieldsLoaded, WITHOUT re-fetching
//
// The question that ordering asks is WHICH OF TWO THINGS AreFieldsLoaded reports:
//
//   (a) the BUFFER currently in hand -- which was fetched under the WIDER set, so the field
//       is still physically loaded and the answer is TRUE; or
//   (b) the REQUESTED load set -- which the narrowing call just shrank, so the answer is FALSE.
//
// Both are defensible readings of "are these fields loaded", and nothing in the documentation
// states which one BC implements. This codeunit asks a real service tier.
//
// The assertions below are written to record BC's answer, not to argue for one. Whichever way
// the service tier answers, that answer is the specification -- and the reason this test exists
// is that an implementation which guesses the other way is silently wrong on this ordering
// while passing all five of 60775's tests.
//
// Test 3 is the control. It performs the SAME narrowing and then DOES re-fetch, which is
// 60775's shape, so a reader can see that the only difference between the two answers is the
// missing re-fetch. Without it, a failure in tests 1-2 could not be distinguished from the
// narrowing itself not taking effect at all.

codeunit 60766 "Test Rec Partial Load Narrow"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Narrowing AFTER a fetch, then asking WITHOUT re-fetching ─────────────────

    [Test]
    procedure PartialLoadNarrow_AfterFetch_NoRefetch_ReportsBufferInHand()
    // CLAIM: after a FULL fetch, narrowing the load set with SetLoadFields and asking
    // AreFieldsLoaded WITHOUT re-fetching reports TRUE for a field the narrowing call just
    // dropped -- because the buffer in hand was fetched under the wider set and the field is
    // still physically there. The competing answer is FALSE (reporting the requested set).
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 520;
        Rec."Integer Field" := 44;
        Rec."Text Field" := 'narrow-after-fetch';
        Rec.Insert();

        // A full fetch: no SetLoadFields at all, so every field is loaded.
        Clear(Rec);
        Rec.Get(520);
        Assert.IsTrue(
          Rec.AreFieldsLoaded(Rec."Text Field"),
          'Precondition: after a full fetch with no SetLoadFields, Text Field must be LOADED');

        // Narrow the load set to exclude Text Field -- and do NOT re-fetch.
        Rec.SetLoadFields(Rec."Integer Field");

        Assert.IsTrue(
          Rec.AreFieldsLoaded(Rec."Text Field"),
          'After narrowing WITHOUT a re-fetch, AreFieldsLoaded must report the buffer in hand, which still holds Text Field');

        // And the value is readable, which is the observable consequence of it being in hand.
        Assert.AreEqual(
          'narrow-after-fetch', Rec."Text Field",
          'The field still present in the fetched buffer must read its stored value');
    end;

    [Test]
    procedure PartialLoadNarrow_AfterNarrowFetch_WidenNoRefetch_StaysUnloaded()
    // CLAIM: the mirror direction. A field genuinely absent from the fetched buffer is not made
    // loaded by WIDENING the requested set without re-fetching -- the buffer is what answers,
    // and no fetch has happened to fill it. This is the arm that a "report the requested set"
    // implementation gets wrong in the opposite direction from test 1.
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 521;
        Rec."Integer Field" := 55;
        Rec."Text Field" := 'widen-no-refetch';
        Rec.Insert();

        // Fetch under a NARROW set: Text Field is genuinely not in the buffer.
        Clear(Rec);
        Rec.SetLoadFields(Rec."Integer Field");
        Rec.Get(521);
        Assert.IsFalse(
          Rec.AreFieldsLoaded(Rec."Text Field"),
          'Precondition: fetched under a narrow set, Text Field must be UNLOADED');

        // Widen the requested set -- and do NOT re-fetch.
        Rec.SetLoadFields();

        Assert.IsFalse(
          Rec.AreFieldsLoaded(Rec."Text Field"),
          'Widening the requested set WITHOUT a re-fetch must not make an absent field loaded: no fetch has filled the buffer');
    end;

    // ── The control: the same narrowing, WITH the re-fetch 60775 always does ─────

    [Test]
    procedure PartialLoadNarrow_AfterFetch_WithRefetch_ReportsNarrowedSet()
    // CLAIM: the control arm. Identical narrowing to test 1, but followed by a re-fetch, which
    // is the shape every test in 60775 uses. Here the answer flips to FALSE. The pair
    // establishes that the re-fetch -- not the SetLoadFields call on its own -- is what makes
    // the narrowed set observable, so tests 1 and 2 cannot pass merely because the narrowing
    // never took effect.
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 522;
        Rec."Integer Field" := 66;
        Rec."Text Field" := 'narrow-with-refetch';
        Rec.Insert();

        Clear(Rec);
        Rec.Get(522);
        Assert.IsTrue(
          Rec.AreFieldsLoaded(Rec."Text Field"),
          'Precondition: after a full fetch, Text Field must be LOADED');

        // The same narrowing as test 1 -- but this time re-fetch before asking.
        Rec.SetLoadFields(Rec."Integer Field");
        Rec.Get(522);

        Assert.IsFalse(
          Rec.AreFieldsLoaded(Rec."Text Field"),
          'After narrowing AND re-fetching, the narrowed load set is what answers, so Text Field must be UNLOADED');

        // Claim 3 of 60775 still holds on this path: the omitted field JIT-loads its real value.
        Assert.AreEqual(
          'narrow-with-refetch', Rec."Text Field",
          'Reading the omitted field must JIT-load its stored value, not return the empty default');
        Assert.IsTrue(
          Rec.AreFieldsLoaded(Rec."Text Field"),
          'After the JIT load, Text Field must report as loaded');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
