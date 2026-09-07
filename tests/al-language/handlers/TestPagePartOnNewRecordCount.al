// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/pagetriggers/devenv-triggers-auto-onnewrecord
// Scope: in-scope
// Fixtures used: ONRC Log (60353), ONRC Header (60354), ONRC Line (60355),
//                ONRC Lines (60356), ONRC Card (60357); shared Assert (60021)
//
/// <summary>
/// Pins HOW MANY TIMES a subpage part's OnNewRecord trigger runs -- the question codeunit 60996
/// ("TPDL Tests") leaves open, and cannot answer with the witness it uses.
///
/// WHY THE EXISTING SUITE CANNOT ANSWER IT. 60996 measured, on all 8 BC legs, that the draft
/// line of a linked part has ALREADY run the page's OnNewRecord before anyone types into it
/// (LinkedPart_DraftLine_HasRunTheOnNewRecordTrigger, run 33997895349). Its witness is
/// `Rec."Set By OnNewRecord" := 'NEWREC'`, and an assignment is idempotent: one firing, two
/// firings and five firings all leave 'NEWREC' in the field. So every arm of that file passes
/// whether the platform raises the trigger once per row or repeatedly, and the same is true of
/// any OnNewRecord that only assigns defaults -- which is what most real ones do.
///
/// That matters as soon as an OnNewRecord has a SIDE EFFECT rather than only a default: a
/// number-series draw, a log row, a counter, a call out to a setup codeunit. Repeated firings
/// silently multiply it, and nothing in the finished row says so.
///
/// WHAT REAL BC ANSWERED, and it is not "once". This file was first written asserting one firing
/// per row throughout. A real service tier said otherwise, identically on all 8 cloud legs of
/// run 34140530877 (BC 27.0, 27.3, 27.5, 28.0, 28.1, 28.2, 28.3, 28.4):
///
///   * opening the card on an EMPTY part and landing on its draft line costs SIX firings,
///     not one (three separate arms measured 6);
///   * New() on that same empty part costs SEVEN -- the six above, plus one for New() itself.
///
/// Those numbers are the measurement, and the assertions below now pin them. They are stable
/// across every version, so this is deterministic platform behaviour rather than a range, and
/// the exact figures are pinned as exact figures.
///
/// THE MECHANISM the numbers point at, stated as the reading it is: showing a blank draft line
/// in an EMPTY repeater raises the trigger repeatedly as the client fills the visible viewport,
/// whereas a row that genuinely starts adds exactly one. Arm 4 is what makes that reading
/// falsifiable rather than decorative -- on a part that already HAS a row, opening costs zero
/// (landing on real data is not a new record) and walking onto the draft line with Next() costs
/// exactly one. So the six is a property of rendering an empty repeater, not a per-row cost.
///
/// HOW THE LATER ASSERTIONS IN EACH ARM ARE WRITTEN, and why they are not absolute integers.
/// Run 34140530877 failed each arm at its FIRST count assertion, so only that first number was
/// measured; every count after it in the same arm never executed. Rather than invent absolutes
/// that no tier has confirmed, each arm now captures the measured baseline in a variable and
/// asserts the exact DELTA from it -- +0 for a step that must not start a record, +1 for a step
/// that starts exactly one. The deltas are exact integers, so nothing here is weakened to a
/// range or an inequality: an implementation that fires an extra time fails, and one that stops
/// firing fails too.
///
/// THE ARMS, and what each isolates.
///
///   1. DraftLine_Shown  -- land on the draft line and touch nothing. Counts what merely SHOWING
///      the blank line costs. Measured: 6.
///   2. DraftLine_Written -- land on the draft line and write one field. Arm 2's delta over
///      arm 1's baseline answers "does the write start the record a second time".
///   3. New_OnEmptyPart  -- New() on an empty part. Measured: 7, i.e. arm 1's six plus one.
///   4. DraftLine_ReachedByNext -- the control, and the arm that passed unchanged. A part with
///      existing data: opening costs 0, Next() onto the draft line costs 1. This is what keeps
///      the sixes above attributable to the empty-repeater render rather than to counting at all.
///
/// The negative is in the data: a second header carries its own line, so an implementation that
/// ignores the SubPageLink shows a row it should not, and the counts move.
/// </summary>
codeunit 60358 "ONRC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // The firings a card open costs when the linked part is EMPTY, so the client renders the
    // blank draft line to fill the viewport. Measured on all 8 cloud legs of run 34140530877.
    // A procedure rather than a literal repeated in three arms, so the measured constant and the
    // run that measured it are stated once.
    local procedure OpenOnEmptyPartFirings(): Integer
    begin
        exit(6);
    end;

    local procedure Initialize()
    var
        Header: Record "ONRC Header";
        Line: Record "ONRC Line";
        Log: Record "ONRC Log";
    begin
        Log.DeleteAll();
        Line.DeleteAll();
        Header.DeleteAll();

        AddHeader('H1', 'First');
        AddHeader('H2', 'Second');
    end;

    local procedure AddHeader(No: Code[20]; Descr: Text[50])
    var
        Header: Record "ONRC Header";
    begin
        Header.Init();
        Header."No." := No;
        Header.Descr := Descr;
        Header.Insert();
    end;

    // Assignment, not Validate, and no page involved: a seeded line must not run the part's
    // OnNewRecord, so the log counts only what the tests themselves cause.
    local procedure AddLine(HeaderNo: Code[20]; LineNo: Integer; Descr: Text[50])
    var
        Line: Record "ONRC Line";
    begin
        Line.Init();
        Line."Header No." := HeaderNo;
        Line."Line No." := LineNo;
        Line.Descr := Descr;
        Line.Insert();
    end;

    local procedure OpenCardOn(HeaderNo: Code[20]; var Card: TestPage "ONRC Card")
    var
        Header: Record "ONRC Header";
    begin
        Header.Get(HeaderNo);
        Card.OpenEdit();
        Card.GoToRecord(Header);
    end;

    local procedure OnNewRecordCount(): Integer
    var
        Log: Record "ONRC Log";
    begin
        exit(Log.Count());
    end;

    local procedure LineCountFor(HeaderNo: Code[20]): Integer
    var
        Line: Record "ONRC Line";
    begin
        Line.SetRange("Header No.", HeaderNo);
        exit(Line.Count());
    end;

    // ARM 3. New() on an empty linked part. Real BC answers SEVEN: the six that opening the card
    // on an empty part costs, plus exactly one for the New() itself. The name ends in
    // "OncePlusTheOpenCost" because that +1 -- not the absolute 7 -- is the claim this arm makes
    // about New(); the 6 underneath it is
    // arm 1's measured constant, asserted here again so a change in it cannot hide inside this
    // arm's total.
    [Test]
    procedure New_OnEmptyLinkedPart_RunsOnNewRecordOncePlusTheOpenCost()
    var
        Card: TestPage "ONRC Card";
        AfterNew: Integer;
    begin
        Initialize();
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);
        Card.Lines.New();

        AfterNew := OnNewRecordCount();
        Assert.AreEqual(OpenOnEmptyPartFirings() + 1, AfterNew,
            'New() on an empty linked part must raise OnNewRecord exactly once more than opening the card on that empty part already did');

        Card.Lines.Descr.SetValue('typed after New');
        Card.Close();

        // The write after New() must not start a SECOND record: the row New() started is the one
        // being filled in. Asserted as an exact delta of zero against the count measured above.
        Assert.AreEqual(AfterNew, OnNewRecordCount(),
            'writing into the row New() started must not raise OnNewRecord again');
        Assert.AreEqual(1, LineCountFor('H1'), 'exactly one line must have been written for H1');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');
    end;

    // ARM 1. Merely showing the draft line of an EMPTY part. Real BC answers SIX -- the blank
    // line is rendered repeatedly to fill the viewport. Nothing is typed, so nothing is saved
    // either, which is asserted: the six firings cannot be explained as rows having been written.
    [Test]
    procedure DraftLine_ShownAndUntouched_RunsOnNewRecordOncePerRenderedBlankLine()
    var
        Card: TestPage "ONRC Card";
        AfterShown: Integer;
    begin
        Initialize();
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);
        Assert.IsFalse(Card.Lines.First(),
            'H1 has no lines, so First() on the part must return false and land on the draft line');

        AfterShown := OnNewRecordCount();
        Assert.AreEqual(OpenOnEmptyPartFirings(), AfterShown,
            'landing on the draft line of an empty part must raise OnNewRecord once per rendered blank line');

        Card.Close();

        Assert.AreEqual(AfterShown, OnNewRecordCount(),
            'closing a card over an untouched draft line must not raise OnNewRecord again');
        Assert.AreEqual(0, LineCountFor('H1'),
            'an untouched draft line must not be written -- so the firings above cannot be saved rows');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');
    end;

    // ARM 2, AND THE ONE THIS FILE EXISTS FOR. Land on the draft line, then write one field.
    // Against arm 1's measured baseline this isolates what the WRITE costs: an equal count means
    // typing only marks an already-started row for saving, a higher count means the promotion
    // starts the record again. Asserted as an exact delta so either answer is falsifiable.
    [Test]
    procedure DraftLine_ShownThenWritten_WriteDoesNotRaiseOnNewRecordAgain()
    var
        Line: Record "ONRC Line";
        Card: TestPage "ONRC Card";
        AfterShown: Integer;
    begin
        Initialize();
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);
        Assert.IsFalse(Card.Lines.First(),
            'H1 has no lines, so First() on the part must return false and land on the draft line');
        AfterShown := OnNewRecordCount();
        Assert.AreEqual(OpenOnEmptyPartFirings(), AfterShown,
            'landing on the draft line of an empty part must raise OnNewRecord once per rendered blank line, before anything is typed');

        Card.Lines.Descr.SetValue('typed into the draft line');

        // THE MEASUREMENT. Read BEFORE Close(), so a later firing on the way out cannot be
        // mistaken for one the write caused. Exact delta of zero against the baseline above.
        Assert.AreEqual(AfterShown, OnNewRecordCount(),
            'writing into the draft line must not raise OnNewRecord again -- the row was already started when the blank line became current');

        Card.Close();

        Assert.AreEqual(AfterShown, OnNewRecordCount(),
            'saving the promoted draft line on close must not raise OnNewRecord again');
        Assert.AreEqual(1, LineCountFor('H1'),
            'typing into the draft line must insert exactly one line for H1');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');

        Line.SetRange("Header No.", 'H1');
        Line.FindFirst();
        Assert.AreEqual('typed into the draft line', Line.Descr,
            'the typed value must reach the backing table -- the count above is for a row that really was written');
        Assert.AreEqual('H1', Line."Header No.",
            'the promoted row must carry the SubPageLink''s value');
    end;

    // ARM 4, THE CONTROL, and the one arm run 34140530877 passed exactly as written -- so not a
    // character of it is changed here. It is what stops the sixes above from being read as "the
    // fixture miscounts": on a part that already has a row, opening costs ZERO and Next() onto
    // the draft line costs exactly ONE. The empty-part cost is therefore a render property, not
    // a counting artefact and not a per-row price.
    [Test]
    procedure DraftLine_ReachedByNextThenWritten_RunsOnNewRecordExactlyOnce()
    var
        Line: Record "ONRC Line";
        Card: TestPage "ONRC Card";
    begin
        Initialize();
        AddLine('H1', 10000, 'seeded');
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);
        Assert.IsTrue(Card.Lines.First(), 'the part must land on H1''s seeded line');

        // Standing on a REAL row is not a new record. This is what stops the counts below from
        // being read as "any cursor move fires the trigger".
        Assert.AreEqual(0, OnNewRecordCount(),
            'landing on an existing data row must not raise OnNewRecord at all');

        Assert.IsTrue(Card.Lines.Next(), 'Next() past the last data row must land on the draft line');
        Assert.AreEqual(1, OnNewRecordCount(),
            'walking onto the draft line must raise OnNewRecord exactly once');

        Card.Lines.Descr.SetValue('typed after walking to the end');

        Assert.AreEqual(1, OnNewRecordCount(),
            'writing into a draft line reached by Next() must not raise OnNewRecord a second time');

        Card.Close();

        Assert.AreEqual(1, OnNewRecordCount(),
            'saving the promoted row on close must not raise OnNewRecord again');
        Assert.AreEqual(2, LineCountFor('H1'),
            'the promoted draft line must be a second line for H1, alongside the seeded one');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');

        Line.SetRange("Header No.", 'H1');
        Line.SetRange(Descr, 'typed after walking to the end');
        Assert.AreEqual(1, Line.Count(), 'exactly one line must carry the typed description');
        Line.FindFirst();
        Assert.IsTrue(Line."Line No." > 10000,
            'AutoSplitKey must number the promoted line past the line already there');
    end;

    // TWO ROWS. The arm that stops the constants above from being read as "the trigger fires a
    // fixed number of times per page and then stops". The count tracks work the platform does,
    // so a second row started after the first is saved raises it AGAIN -- asserted as an exact
    // +1 delta over the count measured after the first row, which is the per-row claim stated in
    // the only form run 34140530877 left measured.
    [Test]
    procedure TwoRowsWrittenThroughTheDraftLine_SecondRowRaisesOnNewRecordOnceMore()
    var
        Card: TestPage "ONRC Card";
        AfterFirstRow: Integer;
    begin
        Initialize();
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);
        Assert.IsFalse(Card.Lines.First(), 'H1 has no lines, so First() must return false');

        Card.Lines.Descr.SetValue('first line');
        AfterFirstRow := OnNewRecordCount();
        Assert.AreEqual(OpenOnEmptyPartFirings(), AfterFirstRow,
            'writing the first row must cost nothing beyond the firings opening the empty part already paid');

        Assert.IsTrue(Card.Lines.Next(),
            'Next() must leave the row just written and land on a fresh draft line');
        Card.Lines.Descr.SetValue('second line');

        Assert.AreEqual(AfterFirstRow + 1, OnNewRecordCount(),
            'a second row started through the draft line must raise OnNewRecord exactly once more -- one firing per row started, not a fixed budget per page');

        Card.Close();

        Assert.AreEqual(AfterFirstRow + 1, OnNewRecordCount(),
            'closing the card must not raise OnNewRecord again');
        Assert.AreEqual(2, LineCountFor('H1'), 'both rows must be written for H1');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');
    end;
}
