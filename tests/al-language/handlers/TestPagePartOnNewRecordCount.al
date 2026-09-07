// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/pagetriggers/devenv-triggers-auto-onnewrecord
// Scope: in-scope
// Fixtures used: ONRC Log (60353), ONRC Header (60354), ONRC Line (60355),
//                ONRC Lines (60356), ONRC Card (60357); shared Assert (60021)
//
/// <summary>
/// Pins HOW MANY TIMES a subpage part's OnNewRecord trigger runs for a single row -- the
/// question codeunit 60996 ("TPDL Tests") leaves open, and cannot answer with the witness it
/// uses.
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
/// number-series draw, a log row, a counter, a call out to a setup codeunit. A double firing
/// silently doubles it, and nothing in the finished row says so.
///
/// THE WITNESS HERE IS A COUNT. "ONRC Lines"'s OnNewRecord appends one row to "ONRC Log", a
/// table the page does not own, and every assertion below names a concrete integer. That is
/// what makes the claim falsifiable in both directions at once: `Assert.AreEqual(1, ...)` fails
/// against an implementation that never fires the trigger (0) and against one that fires it
/// twice (2). It is a separate table because a counter kept on the line row could not survive
/// -- NavForm.NewRecord's ALInit wipes the buffer the trigger runs against, and a draft line
/// nobody types into is discarded rather than saved.
///
/// THE ARMS, and what each isolates.
///
///   1. DraftLine_Shown  -- land on the draft line and touch nothing. Counts the firings that
///      merely SHOWING the blank line costs. 60996 already establishes this is not zero; this
///      arm says what it is.
///   2. DraftLine_Written -- land on the draft line and write one field. Counts the firings for
///      the whole show-then-promote sequence.
///   3. New_OnEmptyPart  -- the control. New() is one NavForm.NewRecord by construction, so an
///      answer other than 1 here would say the fixture itself miscounts, and every other number
///      in the file would have to be read in that light.
///
/// ARM 2 MINUS ARM 1 IS THE ANSWER TO "does the write start the record a second time". If the
/// promotion re-runs the platform's new-record step, arm 2 exceeds arm 1; if typing only marks
/// an already-started row for saving, they are equal.
///
/// A fourth arm walks off the end of EXISTING data rather than opening empty, because that is
/// the other route onto the draft line and the two need not cost the same.
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

    // ARM 3, THE CONTROL, and it runs first in this file on purpose: every other number here is
    // read against it. New() is exactly one NavForm.NewRecord, so a count other than 1 would
    // mean the fixture cannot count and no other arm's figure could be trusted.
    [Test]
    procedure New_OnEmptyLinkedPart_RunsOnNewRecordExactlyOnce()
    var
        Card: TestPage "ONRC Card";
    begin
        Initialize();
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);
        Card.Lines.New();

        Assert.AreEqual(1, OnNewRecordCount(),
            'New() on an empty linked part must raise the part page''s OnNewRecord exactly once');

        Card.Lines.Descr.SetValue('typed after New');
        Card.Close();

        // The write after New() must not start a SECOND record: the row New() started is the one
        // being filled in. This is the same distinction arm 2 draws for the draft line, on the
        // path where the answer is already settled.
        Assert.AreEqual(1, OnNewRecordCount(),
            'writing into the row New() started must not raise OnNewRecord again');
        Assert.AreEqual(1, LineCountFor('H1'), 'exactly one line must have been written for H1');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');
    end;

    // ARM 1. Merely showing the draft line. 60996 established the trigger has run by this point;
    // this says how often. Nothing is typed, so nothing is saved either -- asserted, so a count
    // of 1 cannot be explained away as a row having been written.
    [Test]
    procedure DraftLine_ShownAndUntouched_RunsOnNewRecordExactlyOnce()
    var
        Card: TestPage "ONRC Card";
    begin
        Initialize();
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);
        Assert.IsFalse(Card.Lines.First(),
            'H1 has no lines, so First() on the part must return false and land on the draft line');

        Assert.AreEqual(1, OnNewRecordCount(),
            'landing on the draft line must raise the part page''s OnNewRecord exactly once');

        Card.Close();

        Assert.AreEqual(1, OnNewRecordCount(),
            'closing a card over an untouched draft line must not raise OnNewRecord again');
        Assert.AreEqual(0, LineCountFor('H1'),
            'an untouched draft line must not be written -- so the firing above cannot be a saved row');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');
    end;

    // ARM 2, AND THE ONE THIS FILE EXISTS FOR. Land on the draft line, then write one field.
    // Against arm 1 this isolates what the WRITE costs: equal counts mean typing only marks an
    // already-started row for saving, a higher count means the promotion starts the record
    // again.
    [Test]
    procedure DraftLine_ShownThenWritten_RunsOnNewRecordExactlyOnce()
    var
        Line: Record "ONRC Line";
        Card: TestPage "ONRC Card";
    begin
        Initialize();
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);
        Assert.IsFalse(Card.Lines.First(),
            'H1 has no lines, so First() on the part must return false and land on the draft line');
        Assert.AreEqual(1, OnNewRecordCount(),
            'landing on the draft line must raise OnNewRecord once, before anything is typed');

        Card.Lines.Descr.SetValue('typed into the draft line');

        // THE MEASUREMENT. Read BEFORE Close(), so a later firing on the way out cannot be
        // mistaken for one the write caused.
        Assert.AreEqual(1, OnNewRecordCount(),
            'writing into the draft line must not raise OnNewRecord a second time -- the row was already started when the blank line became current');

        Card.Close();

        Assert.AreEqual(1, OnNewRecordCount(),
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

    // ARM 4. The other route onto the draft line: walking off the end of existing data rather
    // than opening empty. Two firings are expected here and only one of them is the draft line's
    // -- First() lands on a real row, which is not a new record at all, so the total still says
    // ONE new-record step for the one row that gets created.
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

    // TWO ROWS, TWO FIRINGS -- the arm that stops every "exactly once" above from being read as
    // "the trigger can only ever fire once per page". The count tracks ROWS STARTED, so a second
    // draft line promoted after the first is saved raises it again.
    [Test]
    procedure TwoRowsWrittenThroughTheDraftLine_RunOnNewRecordTwice()
    var
        Card: TestPage "ONRC Card";
    begin
        Initialize();
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);
        Assert.IsFalse(Card.Lines.First(), 'H1 has no lines, so First() must return false');

        Card.Lines.Descr.SetValue('first line');
        Assert.AreEqual(1, OnNewRecordCount(), 'the first row must account for exactly one firing');

        Assert.IsTrue(Card.Lines.Next(),
            'Next() must leave the row just written and land on a fresh draft line');
        Card.Lines.Descr.SetValue('second line');

        Assert.AreEqual(2, OnNewRecordCount(),
            'a second row started through the draft line must raise OnNewRecord once more -- one firing per row, not one per page');

        Card.Close();

        Assert.AreEqual(2, OnNewRecordCount(), 'closing the card must not raise OnNewRecord again');
        Assert.AreEqual(2, LineCountFor('H1'), 'both rows must be written for H1');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');
    end;
}
