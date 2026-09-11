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
// BC'S ANSWER, MEASURED. The service tier answered (a) -- the buffer in hand -- on the 27.3 and
// 27.5 cloud legs of corpus PR #323, identically. It went further than the question asked: the
// field stays loaded even across a RE-FETCH, which the first version of test 3 asserted would
// unload it. That assertion was wrong and has been corrected to what BC does; this comment is
// the record of it, per ask-the-corpus-before-claiming-bc-behavior.md -- the tier adjudicates,
// and a corpus assertion is never adjusted to match anything but BC.
//
// THE DISTINGUISHING FACTOR IS THE PRECEDING FULL FETCH, not the re-fetch. That is what
// reconciles this file with 60775, whose PartialLoad_SetLoadFieldsNoArgs_ResetsToFullLoad
// asserts UNLOADED and is green in the same run: there the record is first fetched under an
// ALREADY-NARROW set, so the field was never in the buffer to begin with. Narrowing is a hint
// about what to fetch next; it does not evict a row already materialised.
//
// Each test therefore carries both directions. Test 3's negative half fetches a DIFFERENT row
// for the first time under the narrow set and asserts UNLOADED, so the file cannot be satisfied
// by an implementation that simply answers "loaded" to everything.

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

    // ── The same narrowing, WITH a re-fetch: still loaded, plus the negative half ─

    [Test]
    procedure PartialLoadNarrow_AfterFetch_WithRefetch_KeepsTheFieldLoaded()
    // CLAIM: narrowing after a FULL fetch does not unload what is already in hand, even when a
    // re-fetch follows. The field stays LOADED.
    //
    // MEASURED, not predicted. The first version of this test asserted the opposite -- that the
    // re-fetch makes the narrowed set observable -- and BC said no, identically on the 27.3 and
    // 27.5 cloud legs of corpus PR #323 (two independent binaries; 27.0 and 27.3 ship the same
    // Ncl.dll). The assertion below is BC's answer, and the comment is the correction.
    //
    // WHY THIS DOES NOT CONTRADICT 60775, which asserts UNLOADED on an apparently similar shape
    // (PartialLoad_SetLoadFieldsNoArgs_ResetsToFullLoad, green on the same legs in the same run):
    // the distinguishing factor is the PRECEDING FULL FETCH, not the re-fetch. 60775 starts from
    // Clear(Rec) and first fetches under an ALREADY-NARROW set, so the field was never in the
    // buffer. This test fetches everything first, so the field IS in the buffer, and narrowing
    // does not evict it -- SetLoadFields updates the requested set and invalidates the result-set
    // enumerator, but nothing discards a row already materialised. Narrowing is a hint about what
    // to fetch NEXT, not an instruction to forget what was already fetched.
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 522;
        Rec."Integer Field" := 66;
        Rec."Text Field" := 'narrow-with-refetch';
        Rec.Insert();

        Rec."Entry No." := 523;
        Rec."Integer Field" := 77;
        Rec."Text Field" := 'never-widely-fetched';
        Rec.Insert();

        Clear(Rec);
        Rec.Get(522);
        Assert.IsTrue(
          Rec.AreFieldsLoaded(Rec."Text Field"),
          'Precondition: after a full fetch, Text Field must be LOADED');

        // The same narrowing as test 1 -- and this time re-fetch before asking.
        Rec.SetLoadFields(Rec."Integer Field");
        Rec.Get(522);

        Assert.IsTrue(
          Rec.AreFieldsLoaded(Rec."Text Field"),
          'Narrowing after a full fetch must not unload a field already in the buffer, even across a re-fetch');

        // The value is readable, which is what "still loaded" has to mean to be worth asserting.
        Assert.AreEqual(
          'narrow-with-refetch', Rec."Text Field",
          'The field that stayed loaded must read its stored value');

        // The negative half, so this is not merely "everything is always loaded": a field the
        // narrowed set excludes AND that was never fetched under a wider set is genuinely
        // unloaded. Entry 523 is read for the first time under the narrow set.
        Clear(Rec);
        Rec.SetLoadFields(Rec."Integer Field");
        Rec.Get(523);
        Assert.IsFalse(
          Rec.AreFieldsLoaded(Rec."Text Field"),
          'A field never fetched under a wider set must be UNLOADED under the narrowed set');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
