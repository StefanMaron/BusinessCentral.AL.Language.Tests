// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-data-type
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: ALT TestPart Row (60341), ALT TestPart Lines (60342), ALT TestPart Hidden
//   (60343), ALT TestPart Host (60344), ALT TestPart Caption Host (60345); shared Assert (60021)
// BC versions: 27.0+ (TestPart is runtime 1.0; every version in this matrix has it)
//
/// <summary>
/// CLAIM: TestPart is the TestPage-shaped handle a test gets when it reaches a `part()`
/// control through an open TestPage. It is NOT a thin alias for TestPage: it carries its own
/// implementations of the three boolean accessors -- Visible(), Enabled() and Editable() --
/// which answer from the PART CONTROL on the host, while every other member is inherited
/// from the same base TestPage uses and answers from the part PAGE. That split is the reason
/// this type is worth a file of its own, and it is what most of the tests below pin.
///
/// Nothing in this repository measured TestPart as a surface before this file. Searching the
/// suite for the type name -- with both `rg --hidden` and `command grep -rn`, which have
/// different silent-false-negative modes -- finds only the scraper scripts. Three of its 20
/// documented members (First, New, Next) are used INCIDENTALLY by other suites as a way to
/// reach rows while testing something else; the remaining 17 had no coverage at all, and
/// even those three were never asserted as claims about TestPart. docs/al-language-coverage-
/// gaps.md did not mention the type.
///
/// A note on the scraper: scripts/al-surface-inscope.json marks all 20 members "test-only".
/// That label is accurate here in a way it was NOT for SecretText, SessionSettings,
/// WebServiceActionContext or FilterPageBuilder -- TestPart genuinely only exists inside a
/// test. What it does not mean is "unreachable": a [Test] codeunit is exactly the context
/// this type is for, so the whole surface is measurable, and the label is not a reason to
/// skip it.
///
/// WHAT IS PINNED HERE, and what each test would catch if it broke:
///
///   1. Visible() AND Enabled() ANSWER FROM THE PART CONTROL, NOT FROM THE HOST OR THE PART
///      PAGE. The host opens with three parts over the SAME part page; one of them is
///      declared Visible = false and Enabled = false on the host's control. Both accessors
///      are asserted across that PAIR on ONE open host, so an implementation hardcoding true,
///      or reading the host's own visibility, or reading the part page's properties, fails --
///      none of those can produce two different answers for two controls over one page.
///      Ncl.dll agrees in advance: NavTestPart overrides exactly these two members, as
///      `return testPart.Enabled;` and `return testPart.Visible;` against the part control's
///      own metadata, and inherits everything else.
///   2. Editable() IS THE THIRD MEMBER OF THAT SET AND IS ASSERTED THE SAME WAY. The host
///      hosts the SAME part page twice, once plainly and once with Editable = false on the
///      control. Using one page for both arms is what rules out an implementation reading the
///      part page instead of the control: such an implementation must answer identically for
///      the two, and the test requires it not to.
///   3. Caption() READS THE PART PAGE, NOT THE HOSTING CONTROL. Two hosts host one part page:
///      the default host's control carries no caption, the caption host's control overrides
///      it with a different string. Caption() answers the PART PAGE's caption from both. The
///      three strings involved -- host page caption, part page caption, control caption --
///      are deliberately all different, so the assertion cannot pass by two of them
///      coinciding. Ncl.dll settles the direction in advance (ALCaption is
///      `return TestPage.Caption`), and the pairing is what MEASURES it.
///   4. First()/Next()/Last()/Previous() WALK THE PART'S OWN ROWSET IN KEY ORDER. Asserted
///      over three seeded rows by reading a distinctive value at each stop, so an
///      implementation answering the first row for every position fails, and one answering
///      "there are rows" unconditionally fails the empty-part arm.
///   5. Next() AND Previous() RETURN false AT THE ENDS RATHER THAN WRAPPING OR ERRORING. Both
///      ends are asserted, and both are asserted to leave the cursor where it was -- a
///      failed move is not a move.
///   6. GoToKey() TAKES THE PRIMARY KEY FIELDS IN ORDER AND ITS ARITY IS CHECKED. The fixture
///      table's key is deliberately COMPOSITE (Grp + "Line No."), which is what makes the
///      negative case expressible at all: GoToKey with one value where two are required is a
///      catchable error, and the same call with the right arity lands on the row. Every other
///      part fixture in this repository keys on a single field, where a one-value GoToKey is
///      correct and the arity check is invisible.
///   7. GoToKey() RETURNS false FOR A KEY THAT DOES NOT EXIST WHEN THE RETURN VALUE IS
///      CAPTURED, AND ERRORS WHEN IT IS DISCARDED. The trappable-return convention, asserted
///      in both directions -- an implementation that always errors passes the discarded half,
///      one that never errors passes the captured half.
///   8. GoToRecord() POSITIONS FROM A Record RATHER THAN FROM KEY VALUES, AND AGREES WITH
///      GoToKey() ON THE SAME ROW. Asserted by landing on a row that is neither first nor
///      last, so an implementation ignoring its argument fails.
///   9. GetField() RESOLVES A CONTROL BY ITS FIELD ID AND THE RESULT READS THE CURRENT ROW.
///      The value read through GetField() is asserted equal to the value read through the
///      named control on the same row, and DIFFERENT from the value on another row -- the
///      second half is what rules out an implementation returning a constant.
///  10. FindFirstField()/FindNextField()/FindPreviousField() SEARCH THE ROWSET BY A CONTROL
///      VALUE. Two rows deliberately SHARE a Descr value while differing in key, so
///      FindFirstField lands on the earlier and FindNextField advances to the later; a third
///      row with a unique value is the negative case. An implementation that ignored the
///      value argument and simply moved would fail the row-identity assertions.
///  11. ValidationErrorCount() AND GetValidationError() REPORT ERRORS RAISED BY THE PART'S
///      OWN FIELD VALIDATION. The fixture table's Grade field refuses any value starting with
///      'BAD' with a Label the test asserts by substring, so the error counted is a REAL
///      validation error from the part's AL, not a platform type-conversion message whose
///      text is a localization detail. The clean-part arm asserts the count is 0, which is
///      what rules out an implementation that always reports one.
///  12. GetValidationError() IS 1-BASED AND RANGE-CHECKED. Index 1 is the first error and
///      index 0 errors. Ncl.dll shows why this is worth pinning rather than assuming:
///      ALGetValidationError(index) is literally
///      `TestPage.GetValidationError(checked(index - 1))` wrapped in a translation of
///      ArgumentOutOfRangeException, so the 1-based-ness is a deliberate offset applied at
///      the AL boundary and a 0-based implementation would be a silent off-by-one.
///
/// COMPILE-TIME REFUSALS, measured with the real alc against this app's Cloud target. These
/// are negative cases that CANNOT be written as [Test] procedures, because the compiler
/// rejects them before a service tier ever sees them. They are recorded here rather than
/// deleted, following the precedent of network/TestHttpClientBlockNoHandler.al:
///
///   Host.PartA = Host.PartB                     error AL0175: "Operator '=' cannot be applied
///                                               to operands of type 'Lines' and
///                                               'ReadOnlyLines'". Note WHAT that message
///                                               names: not "TestPart" but the two CONTROL
///                                               names. Each part control on a host is its
///                                               own generated type, which is the compiler's
///                                               view of the same fact the tests below rest
///                                               on -- a part handle is inseparable from the
///                                               control it was reached through.
///   TestPart.Prev()                             error AL0666 -- 'Prev' is not available in
///                                               runtime version '16.0'; the supported range
///                                               is '3.0' until, but not including, '13.0'.
///                                               THIS IS A DOCUMENTED MEMBER THAT NO LONGER
///                                               EXISTS. scripts/al-surface.json lists Prev
///                                               and Previous side by side as two of the
///                                               twenty members, and Microsoft Learn still
///                                               publishes testpart-prev-method, but this
///                                               app targets runtime 16.0 and the compiler
///                                               refuses the call outright. So one of the
///                                               twenty members is unreachable, and the
///                                               obvious claim about the pair -- that Prev
///                                               and Previous are two spellings of one
///                                               operation -- is not expressible here. Every
///                                               backward walk below uses Previous().
///   TestPart.GetField(Id)                       compiles, with warning AL0667: deprecated
///                                               in runtime '3.0' or greater. Still callable,
///                                               so it is covered; recorded because the
///                                               warning will become an error in a future
///                                               release and this file will then need the
///                                               same treatment Prev just got.
///   var P: TestPart                             error AL0134: "'TestPart' is not recognized
///                                               as a valid type." TestPart is NOT a declarable
///                                               variable type. Unlike TestPage, which is
///                                               declared as `TestPage "Some Page"`, a
///                                               TestPart handle exists ONLY as the member
///                                               access `Host.PartName`. Consequence for
///                                               every test below: the part cannot be held in
///                                               a local, so each assertion re-reaches it
///                                               through the host, and there is no test of
///                                               "assignment semantics" to write -- the
///                                               question FilterPageBuilder and
///                                               WebServiceActionContext both answered does
///                                               not arise for this type.
///
/// What DOES compile, probed rather than assumed: Format(Host.Lines), assignment of a part
/// handle into a Variant, and Expand()/IsExpanded() on a plain ListPart.
///
/// ON Expand() AND IsExpanded(): they compile on a ListPart, so they are measured below
/// rather than withheld -- but the test that measures them makes the WEAKER of the two
/// available claims, and says so. These two members govern expandable (tree-shaped) part
/// controls, and this suite hosts flat ListParts, so what the pair can honestly pin here is
/// that IsExpanded() answers consistently with the last Expand() it was given, NOT what a
/// tree control would do. A tree-view fixture is a separate suite. Nothing else on the type
/// is withheld.
/// </summary>
codeunit 60346 "Test TestPart"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "ALT TestPart Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRow(Grp: Code[10]; LineNo: Integer; Descr: Text[50])
    var
        Row: Record "ALT TestPart Row";
    begin
        Row.Init();
        Row.Grp := Grp;
        Row."Line No." := LineNo;
        Row.Descr := Descr;
        Row.Insert();
    end;

    // Three rows in key order. Row 2 shares its Descr with row 3, which is what the
    // FindFirstField/FindNextField pair needs; row 1's Descr is unique, which is what the
    // not-found arm needs.
    local procedure SeedThreeRows()
    begin
        SeedRow('A', 10, 'Alpha');
        SeedRow('A', 20, 'Shared');
        SeedRow('A', 30, 'Shared');
    end;

    // ── Visible / Enabled / Editable: the three members TestPart overrides ──────────

    [Test]
    procedure TestPart_Visible_AnswersFromThePartControl()
    // CLAIM: Visible() answers from the part control on the host, so two controls over the
    // SAME part page answer differently when the host declares them differently. An
    // implementation hardcoding true, or reading the host page, cannot produce both answers.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        Assert.IsTrue(Host.Lines.Visible(),
            'the part control declared without Visible must report visible');
        Assert.IsFalse(Host.Hidden.Visible(),
            'the part control declared Visible = false must report not visible, on the same open host');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Enabled_AnswersFromThePartControl()
    // CLAIM: Enabled() is the sibling of Visible() and answers the same way -- from the
    // control, not the page. Asserted across the same pair, so the two tests together rule
    // out an implementation that conflated the two properties.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        Assert.IsTrue(Host.Lines.Enabled(),
            'the part control declared without Enabled must report enabled');
        Assert.IsFalse(Host.Hidden.Enabled(),
            'the part control declared Enabled = false must report not enabled, on the same open host');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Editable_AnswersFromThePartControl()
    // CLAIM: Editable() answers from the control too. This is the sharpest of the three,
    // because both arms host the IDENTICAL part page -- "ALT TestPart Lines" -- and differ
    // only in the host's Editable property. An implementation reading the part page must
    // answer the same for both, and this test requires it not to.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        Assert.IsTrue(Host.Lines.Editable(),
            'the part control declared without Editable must report editable');
        Assert.IsFalse(Host.ReadOnlyLines.Editable(),
            'the SAME part page hosted with Editable = false must report not editable');
        Host.Close();
    end;

    // ── Caption: inherited, and reads the part page ─────────────────────────────────

    [Test]
    procedure TestPart_Caption_ReadsThePartPageNotTheHost()
    // CLAIM: Caption() returns the PART PAGE's caption, not the host page's. All three
    // captions in play are spelled differently, so neither assertion can pass by coincidence.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        Assert.AreEqual('Part Lines Caption', Host.Lines.Caption(),
            'Caption() must return the part page''s own caption');
        Assert.AreNotEqual('Host Page Caption', Host.Lines.Caption(),
            'Caption() must not return the hosting page''s caption');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Caption_ReadsThePartPageNotTheControlOverride()
    // CLAIM: when the hosting CONTROL overrides the caption, Caption() still answers the part
    // page's own caption. This is the half the default host cannot decide -- there the control
    // has no caption and both readings agree. Ncl.dll predicts it (ALCaption returns
    // TestPage.Caption); this test is the measurement.
    var
        CaptionHost: TestPage "ALT TestPart Caption Host";
    begin
        Initialize();
        SeedThreeRows();

        CaptionHost.OpenEdit();

        Assert.AreEqual('Part Lines Caption', CaptionHost.Lines.Caption(),
            'Caption() must answer the part page''s caption even when the control overrides it');
        Assert.AreNotEqual('Control Level Caption', CaptionHost.Lines.Caption(),
            'Caption() must not answer the hosting control''s caption override');
        CaptionHost.Close();
    end;

    // ── Navigation: First / Next / Last / Prev / Previous ───────────────────────────

    [Test]
    procedure TestPart_First_LandsOnTheFirstRowInKeyOrder()
    // CLAIM: First() moves to the first row of the part's own rowset in key order and
    // answers true. The Descr asserted is unique to that row, so an implementation landing
    // anywhere else fails.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        Assert.IsTrue(Host.Lines.First(), 'First() must answer true when the part has rows');
        Assert.AreEqual('Alpha', Host.Lines.Descr.Value(),
            'First() must land on the lowest-keyed row');
        Assert.AreEqual('10', Host.Lines.LineNo.Value(),
            'First() must land on line 10, the lowest key');
        Host.Close();
    end;

    [Test]
    procedure TestPart_First_AnswersFalseOnAnEmptyPart()
    // CLAIM: the negative of the above. With the part's table empty, First() answers false
    // rather than landing on the trailing blank new-row line an editable repeater carries.
    // This is the arm that refuses a "there are always rows" implementation.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();

        Host.OpenEdit();

        Assert.IsFalse(Host.Lines.First(),
            'First() must answer false when the part''s source table is empty');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Next_WalksForwardOneRowAtATime()
    // CLAIM: Next() advances exactly one row per call, in key order. Reading a distinctive
    // value at each stop is what separates this from an implementation that answers the first
    // row for every position.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        Assert.AreEqual('10', Host.Lines.LineNo.Value(), 'the walk must start on line 10');
        Assert.IsTrue(Host.Lines.Next(), 'Next() must answer true while rows remain');
        Assert.AreEqual('20', Host.Lines.LineNo.Value(), 'one Next() must reach line 20');
        Assert.IsTrue(Host.Lines.Next(), 'Next() must answer true reaching the last row');
        Assert.AreEqual('30', Host.Lines.LineNo.Value(), 'two Next() calls must reach line 30');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Last_LandsOnTheHighestKeyedRow()
    // CLAIM: Last() jumps to the final row regardless of the current position. Called from
    // the first row, so an implementation that no-ops fails.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        Assert.IsTrue(Host.Lines.Last(), 'Last() must answer true when the part has rows');
        Assert.AreEqual('30', Host.Lines.LineNo.Value(),
            'Last() must land on the highest-keyed row');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Previous_WalksBackwardOneRowAtATime()
    // CLAIM: Previous() is the mirror of Next(). Walked from the last row so the starting
    // position is not the answer.
    //
    // This test is spelled Previous() and not Prev() because Prev() DOES NOT COMPILE on this
    // app's runtime -- see the header: alc rejects it with AL0666, "not available in runtime
    // version 16.0, supported 3.0 until 13.0". The documented surface still lists both, so
    // one of the twenty members is unreachable and the claim that they are two spellings of
    // one operation is no longer expressible here.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.Last();

        Assert.AreEqual('30', Host.Lines.LineNo.Value(), 'the backward walk must start on line 30');
        Assert.IsTrue(Host.Lines.Previous(), 'Previous() must answer true while earlier rows remain');
        Assert.AreEqual('20', Host.Lines.LineNo.Value(), 'one Previous() must reach line 20');
        Assert.IsTrue(Host.Lines.Previous(), 'Previous() must answer true reaching the first row');
        Assert.AreEqual('10', Host.Lines.LineNo.Value(), 'two Previous() calls must reach line 10');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Next_AnswersFalseAtTheEndAndDoesNotMove()
    // CLAIM: Next() past the last row answers false rather than wrapping to the first or
    // erroring, AND leaves the cursor where it was. The second half is the one that matters:
    // an implementation that wrapped would answer false only by accident, and the row
    // assertion catches it.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.Last();

        Assert.IsFalse(Host.Lines.Next(), 'Next() past the last row must answer false');
        Assert.AreEqual('30', Host.Lines.LineNo.Value(),
            'a failed Next() must leave the cursor on the last row, not wrap to the first');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Previous_AnswersFalseAtTheStartAndDoesNotMove()
    // CLAIM: the mirror of the above at the other end.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        Assert.IsFalse(Host.Lines.Previous(), 'Previous() before the first row must answer false');
        Assert.AreEqual('10', Host.Lines.LineNo.Value(),
            'a failed Previous() must leave the cursor on the first row, not wrap to the last');
        Host.Close();
    end;

    // ── GoToKey: arity-checked, and the trappable-return convention ─────────────────

    [Test]
    procedure TestPart_GoToKey_PositionsOnTheKeyedRow()
    // CLAIM: GoToKey() takes the primary key fields IN ORDER and lands on that row. The
    // target is the MIDDLE row, so neither "did not move" nor "went to an end" passes.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        Assert.IsTrue(Host.Lines.GoToKey('A', 20),
            'GoToKey() with both key fields must find the seeded row');
        Assert.AreEqual('20', Host.Lines.LineNo.Value(),
            'GoToKey() must land on the row it was given');
        Assert.AreEqual('Shared', Host.Lines.Descr.Value(),
            'the landed row must carry that row''s own data');
        Host.Close();
    end;

    [Test]
    procedure TestPart_GoToKey_ReturnsFalseForAKeyThatDoesNotExist()
    // CLAIM: with the return value CAPTURED, a missing key answers false rather than
    // erroring. Half of the trappable-return convention.
    var
        Host: TestPage "ALT TestPart Host";
        Found: Boolean;
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        Found := Host.Lines.GoToKey('A', 999);

        Assert.IsFalse(Found, 'GoToKey() with a captured return must answer false for a missing key');
        Host.Close();
    end;

    [Test]
    procedure TestPart_GoToKey_ErrorsForAMissingKeyWhenTheReturnIsDiscarded()
    // CLAIM: the other half. The SAME call with the return value DISCARDED raises a catchable
    // error. Asserting both directions is what rules out an implementation that always errors
    // (which would pass this test and fail the one above) or never errors (vice versa).
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        asserterror Host.Lines.GoToKey('A', 999);

        Assert.IsTrue(GetLastErrorText() <> '',
            'GoToKey() with a discarded return must raise a catchable error for a missing key');
        Host.Close();
    end;

    [Test]
    procedure TestPart_GoToKey_ErrorsWhenTheKeyFieldCountIsWrong()
    // CLAIM: GoToKey() checks the number of values against the number of primary key fields
    // and errors when they disagree. The fixture's key is COMPOSITE precisely so this case
    // exists -- with a single-field key, GoToKey('A') would be correct and this check would
    // be unobservable. Ncl.dll raises NavTestInvalidNumberOfKeyFieldValuesException here,
    // before any row lookup happens, which is why the row does not need to exist.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        asserterror Host.Lines.GoToKey('A');

        Assert.IsTrue(GetLastErrorText() <> '',
            'GoToKey() with fewer values than key fields must raise a catchable error');
        Host.Close();
    end;

    // ── GoToRecord ─────────────────────────────────────────────────────────────────

    [Test]
    procedure TestPart_GoToRecord_PositionsFromARecordVariable()
    // CLAIM: GoToRecord() positions the part from a Record rather than from key values, and
    // agrees with GoToKey() on the same row. The target is again the middle row, so an
    // implementation ignoring its argument fails.
    var
        Host: TestPage "ALT TestPart Host";
        Row: Record "ALT TestPart Row";
    begin
        Initialize();
        SeedThreeRows();
        Row.Get('A', 20);

        Host.OpenEdit();
        Host.Lines.First();

        Assert.IsTrue(Host.Lines.GoToRecord(Row),
            'GoToRecord() must find the row the Record variable identifies');
        Assert.AreEqual('20', Host.Lines.LineNo.Value(),
            'GoToRecord() must land on the row it was given');
        Host.Close();
    end;

    // ── GetField ───────────────────────────────────────────────────────────────────

    [Test]
    procedure TestPart_GetField_ResolvesByFieldIdAndReadsTheCurrentRow()
    // CLAIM: GetField() resolves a control by the underlying FIELD id and the handle reads
    // the CURRENT row. Asserted equal to the named control on the same row, and DIFFERENT
    // after moving -- the second half is what rules out an implementation returning a
    // constant or a stale first-row value.
    var
        Host: TestPage "ALT TestPart Host";
        Row: Record "ALT TestPart Row";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        Assert.AreEqual(Host.Lines.Descr.Value(), Host.Lines.GetField(Row.FieldNo(Descr)).Value(),
            'GetField() must read the same value as the named control on the same row');
        Assert.AreEqual('Alpha', Host.Lines.GetField(Row.FieldNo(Descr)).Value(),
            'GetField() must read the first row''s value while positioned there');

        Host.Lines.Next();

        Assert.AreEqual('Shared', Host.Lines.GetField(Row.FieldNo(Descr)).Value(),
            'GetField() must follow the cursor rather than answering a stale value');
        Host.Close();
    end;

    // ── FindFirstField / FindNextField / FindPreviousField ──────────────────────────

    [Test]
    procedure TestPart_FindFirstField_LandsOnTheEarliestMatchingRow()
    // CLAIM: FindFirstField() searches the rowset for a control VALUE and lands on the
    // earliest match. Two rows share 'Shared', so landing on line 20 rather than 30 is the
    // claim; an implementation returning the last match, or ignoring the value, fails.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        Assert.IsTrue(Host.Lines.FindFirstField(Host.Lines.Descr, 'Shared'),
            'FindFirstField() must find a row carrying the value');
        Assert.AreEqual('20', Host.Lines.LineNo.Value(),
            'FindFirstField() must land on the EARLIEST row carrying the value, not the last');
        Host.Close();
    end;

    [Test]
    procedure TestPart_FindNextField_AdvancesToTheNextMatchingRow()
    // CLAIM: FindNextField() continues the search from the current position, so the second
    // row sharing the value is reached. This is the test the duplicate Descr exists for.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.FindFirstField(Host.Lines.Descr, 'Shared');

        Assert.IsTrue(Host.Lines.FindNextField(Host.Lines.Descr, 'Shared'),
            'FindNextField() must find the second row carrying the value');
        Assert.AreEqual('30', Host.Lines.LineNo.Value(),
            'FindNextField() must advance past the row FindFirstField landed on');
        Host.Close();
    end;

    [Test]
    procedure TestPart_FindPreviousField_MovesBackToTheEarlierMatchingRow()
    // CLAIM: FindPreviousField() is the backward form. Driven from the later duplicate back
    // to the earlier one.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.Last();

        Assert.IsTrue(Host.Lines.FindPreviousField(Host.Lines.Descr, 'Shared'),
            'FindPreviousField() must find an earlier row carrying the value');
        Assert.AreEqual('20', Host.Lines.LineNo.Value(),
            'FindPreviousField() must land on the earlier of the two matching rows');
        Host.Close();
    end;

    [Test]
    procedure TestPart_FindFirstField_AnswersFalseForAValueNoRowCarries()
    // CLAIM: the negative case. A value present on no row answers false rather than landing
    // somewhere arbitrary. Without this, an implementation that ignored the value argument
    // and simply called First() would pass every test above.
    var
        Host: TestPage "ALT TestPart Host";
        Found: Boolean;
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        Found := Host.Lines.FindFirstField(Host.Lines.Descr, 'NoSuchDescription');

        Assert.IsFalse(Found,
            'FindFirstField() must answer false for a value no row carries');
        Host.Close();
    end;

    // ── ValidationErrorCount / GetValidationError ──────────────────────────────────

    [Test]
    procedure TestPart_ValidationErrorCount_IsZeroOnACleanPart()
    // CLAIM: a part with no failed input reports zero validation errors. The arm that rules
    // out an implementation always reporting one.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        Assert.AreEqual(0, Host.Lines.ValidationErrorCount(),
            'a part with no failed input must report zero validation errors');
        Host.Close();
    end;

    [Test]
    procedure TestPart_ValidationErrorCount_CountsARefusedFieldValidation()
    // CLAIM: a value the part's OWN field validation refuses is counted. The fixture table's
    // Grade trigger raises a Label for anything starting with 'BAD', so what is counted here
    // is a real AL validation error, not a platform type-conversion message.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        asserterror Host.Lines.Grade.SetValue('BADGRADE');

        Assert.IsTrue(Host.Lines.ValidationErrorCount() > 0,
            'a refused field validation must be counted on the part');
        Host.Close();
    end;

    [Test]
    procedure TestPart_GetValidationError_IsOneBasedAndCarriesTheMessage()
    // CLAIM: GetValidationError(1) is the FIRST error, and the text is the message the part's
    // own AL raised -- asserted by substring on the fixture's Label, so it cannot pass on an
    // arbitrary non-empty string. Ncl.dll shows the 1-based-ness is a deliberate offset
    // applied at the AL boundary (`GetValidationError(checked(index - 1))`), which is exactly
    // the kind of thing that would otherwise be a silent off-by-one.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        asserterror Host.Lines.Grade.SetValue('BADGRADE');

        Assert.IsTrue(StrPos(Host.Lines.GetValidationError(1), 'refuses the grade') > 0,
            'GetValidationError(1) must carry the message the part''s own validation raised');
        Host.Close();
    end;

    [Test]
    procedure TestPart_GetValidationError_ErrorsOnIndexZero()
    // CLAIM: the range check. Index 0 is below the 1-based range and raises a catchable
    // error rather than answering the first error or the empty string. This is the assertion
    // a 0-based implementation fails.
    var
        Host: TestPage "ALT TestPart Host";
        ErrText: Text;
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        asserterror Host.Lines.Grade.SetValue('BADGRADE');

        asserterror ErrText := Host.Lines.GetValidationError(0);

        Assert.IsTrue(GetLastErrorText() <> '',
            'GetValidationError(0) must raise a catchable error, because the index is 1-based');
        Host.Close();
    end;

    // ── Expand / IsExpanded ────────────────────────────────────────────────────────

    [Test]
    procedure TestPart_IsExpanded_TracksTheLastExpandCall()
    // CLAIM, and note it is the WEAKER of the two claims available: on a flat ListPart,
    // IsExpanded() answers consistently with the last Expand() it was given. What this does
    // NOT claim is what a tree-shaped part would do -- these two members exist for expandable
    // controls, and this suite hosts flat ListParts, so pinning "a tree collapses" here would
    // be pinning a control the fixture does not have.
    //
    // Both directions are asserted against the SAME part, and the two assertions must
    // disagree with each other, so an implementation hardcoding either answer fails. They are
    // covered rather than withheld because both members compile on a ListPart -- measured
    // with alc, not assumed -- and a member that compiles is a member the tier can adjudicate.
    var
        Host: TestPage "ALT TestPart Host";
        AfterExpand: Boolean;
        AfterCollapse: Boolean;
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        Host.Lines.Expand(true);
        AfterExpand := Host.Lines.IsExpanded();
        Host.Lines.Expand(false);
        AfterCollapse := Host.Lines.IsExpanded();

        Assert.AreNotEqual(AfterExpand, AfterCollapse,
            'IsExpanded() must not answer the same after Expand(true) and Expand(false)');
        Assert.IsTrue(AfterExpand, 'IsExpanded() must answer true after Expand(true)');
        Assert.IsFalse(AfterCollapse, 'IsExpanded() must answer false after Expand(false)');
        Host.Close();
    end;

    // ── New: the row-adding member ─────────────────────────────────────────────────

    [Test]
    procedure TestPart_New_AddsARowThePartCanThenWrite()
    // CLAIM: New() moves the part to a fresh row that accepts writes, and the write reaches
    // the part's own source table. Asserted durably through the table rather than through the
    // control, so a control tree that merely accepted the value without persisting fails.
    var
        Host: TestPage "ALT TestPart Host";
        Row: Record "ALT TestPart Row";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.New();
        Host.Lines.Grp.SetValue('B');
        Host.Lines.LineNo.SetValue(40);
        Host.Lines.Descr.SetValue('AddedThroughPart');
        Host.Close();

        Assert.IsTrue(Row.Get('B', 40),
            'New() plus SetValue on the part must insert a row into the part''s own table');
        Assert.AreEqual('AddedThroughPart', Row.Descr,
            'the value written through the part must reach the table');
    end;
}
