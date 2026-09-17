// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-cancel-method
// Scope: in-scope
// Fixtures used: PCN Header (60533), PCN Line (60534), PCN Probe (60536), PCN Card (60533),
//                PCN Lines Part (60534), PCN Dialog (60535), Assert (60021)
//
// WHEN a [ModalPageHandler] starts a row in a part with New(), types a value into it, and then
// closes the modal with the built-in Cancel, does that row reach the database?
//
// "Opf Ok Part Flush Tests" (60663) pins the OK half of this on a temporary-sourced part, and
// "OKP Ok Part Row Tests" (60760) pins OK on a card the test opened itself. Neither says
// anything about Cancel, and neither writes a real table through a handler-closed modal.
//
// The measurements run on a StandardDialog, not on a Card, and that is not a preference. Page
// 60703 "Test Page Modal" records, verified against real BC, that a plain Card-type modal has
// no client Cancel affordance -- TestPage.Cancel() answers "not found" on one even when the page
// declares an action named Cancel -- and that PageType = StandardDialog is what gives the client
// OK/Cancel chrome. "TRT Tests" (60844, TestPageRecordTriggers.al) records the same refusal for a Card
// opened with OpenNew(). So a Card cannot answer a question about Cancel at all; it is kept here
// for two arms that do not need one.
//
// **These assertions are what I expected, not what a tier has confirmed.** The two plausible
// answers are far apart and the decompile in AlRunner#4150 does not choose between them: Cancel
// could leave the pending row unwritten, or it could write it like any other close, since a
// card's already-committed edits are famously NOT rolled back by Cancel or Escape and a close
// that sets no explicit save-or-discard intent has to do one of the two. If the tier disagrees,
// the assertion follows the tier.
//
// How the arms separate those, and separate both from a broken fixture:
//
//   * CancelInvoke_OnACard_HasNoBuiltInCancelAction -- the refusal, in the shape "TBA Tests"
//     (60338) uses for the same fact about a NavigatePage and a ConfirmationDialog. It asserts
//     the platform's exact text, so "not found" cannot be confused with some other failure on
//     the way to the page.
//   * OkInvoke_OnACard_SavesThePendingPartRow -- the other half of that pair: the Card modal
//     DOES have a built-in OK, and pressing it writes the part row. So the arm above is a
//     statement about Cancel and not about a page nothing can drive.
//   * ..._SavesThePendingPartRow (OK, dialog) -- the positive control for the measurements. The
//     row CAN be written through this fixture, so a zero below is about Cancel and not about a
//     SubPageLink that never worked.
//   * ..._DiscardsThePendingPartRow -- the measurement.
//   * ..._KeepsTheCommittedPartRowAndDropsThePendingOne -- the discriminator. Two rows are
//     typed: the first is committed when New() moves off it, the second is still being edited
//     when Cancel is pressed. 2 means Cancel saves everything, 1 means it drops only what is
//     pending, 0 means it rolls the part back. The handler also records what it saw right after
//     the second New(), in "PCN Probe" (60536), because a 0 has a second cause -- New() never
//     committed the first row either -- which the count alone cannot separate from a rollback.
//   * the two host-field arms -- the same question one level up, so the part answer can be
//     compared against the host answer instead of assumed to match it. They come as a pair on
//     purpose: the Cancel arm asserts the value Initialize() seeded, so on its own it would pass
//     if SetValue silently no-opped or the field were not editable, and the OK arm is what rules
//     that out.
//
// Every assertion reads the table AFTER RunModal has returned, so a row that only ever lived in
// the page cannot satisfy one.
//
// Filed from AlRunner#4150. Nothing in that issue had been measured against a service tier;
// this file is the measurement.
codeunit 60535 "PCN Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        BuiltInCancelNotFoundErr: Label 'The built-in action = Cancel is not found on the page';

    local procedure Initialize(var Header: Record "PCN Header")
    var
        Line: Record "PCN Line";
        Probe: Record "PCN Probe";
    begin
        Line.DeleteAll();
        Header.DeleteAll();
        Probe.DeleteAll();

        Header.Init();
        Header."Code" := 'H1';
        Header.Descr := 'Host';
        Header.Insert();
    end;

    local procedure CountLines(HeaderCode: Code[20]): Integer
    var
        Line: Record "PCN Line";
    begin
        Line.SetRange("Header Code", HeaderCode);
        exit(Line.Count());
    end;

    local procedure FirstReference(HeaderCode: Code[20]): Text[30]
    var
        Line: Record "PCN Line";
    begin
        Line.SetRange("Header Code", HeaderCode);
        Line.FindFirst();
        exit(Line.Reference);
    end;

    local procedure RecordProbe(HeaderCode: Code[20])
    var
        Probe: Record "PCN Probe";
        Line: Record "PCN Line";
    begin
        Line.SetRange("Header Code", HeaderCode);

        if not Probe.Get('AFTER-SECOND-NEW') then begin
            Probe.Init();
            Probe."No." := 'AFTER-SECOND-NEW';
            Probe.Insert();
        end;
        Probe."Line Count" := Line.Count();
        Probe.Modify();
    end;

    // --- Card host: what it can and cannot be asked ------------------------------------------

    // A modally-run Card has no built-in Cancel. Page 60703 "Test Page Modal" records this
    // against real BC; this arm is the executable form of it, and it is what makes every Cancel
    // measurement below run on the StandardDialog instead.
    [Test]
    [HandlerFunctions('PcnCardCancelHandler')]
    procedure CancelInvoke_OnACard_HasNoBuiltInCancelAction()
    var
        Header: Record "PCN Header";
        Card: Page "PCN Card";
    begin
        Initialize(Header);

        Card.SetRecord(Header);
        asserterror Card.RunModal();

        Assert.ExpectedError(BuiltInCancelNotFoundErr);
    end;

    // The other half of that pair: the same Card modal DOES offer a built-in OK, and pressing it
    // writes the part row to a real table. So the refusal above is about Cancel specifically.
    [Test]
    [HandlerFunctions('PcnCardTypeALineThenOkHandler')]
    procedure OkInvoke_OnACard_SavesThePendingPartRow()
    var
        Header: Record "PCN Header";
        Card: Page "PCN Card";
        Result: Action;
    begin
        Initialize(Header);

        Card.SetRecord(Header);
        Result := Card.RunModal();

        Assert.AreEqual(Format(Action::OK), Format(Result),
            'OK().Invoke() on a modally-run Card must close it reporting OK.');
        Assert.AreEqual(1, CountLines('H1'),
            'OK on the host must save the row the handler typed into its part.');
        Assert.AreEqual('Alpha', FirstReference('H1'),
            'The saved part row must carry the value the handler typed.');
    end;

    // --- StandardDialog host: the measurements -----------------------------------------------

    // CHROME CONTROL: this host does offer a built-in Cancel, and invoking it reports Cancel.
    [Test]
    [HandlerFunctions('PcnDialogCancelNothingTypedHandler')]
    procedure CancelInvoke_OnAStandardDialog_WithNothingTyped_ClosesTheModalReportingCancel()
    var
        Header: Record "PCN Header";
        Dialog: Page "PCN Dialog";
        Result: Action;
    begin
        Initialize(Header);

        Dialog.SetRecord(Header);
        Result := Dialog.RunModal();

        Assert.AreEqual(Format(Action::Cancel), Format(Result),
            'Cancel().Invoke() on a StandardDialog must close it reporting Cancel.');
        Assert.AreEqual(0, CountLines('H1'),
            'A handler that typed nothing must leave the part''s table empty.');
    end;

    // POSITIVE CONTROL: the same fixture closed with OK writes the typed row.
    [Test]
    [HandlerFunctions('PcnDialogTypeALineThenOkHandler')]
    procedure OkInvoke_OnAStandardDialog_SavesThePendingPartRow()
    var
        Header: Record "PCN Header";
        Dialog: Page "PCN Dialog";
        Result: Action;
    begin
        Initialize(Header);

        Dialog.SetRecord(Header);
        Result := Dialog.RunModal();

        Assert.AreEqual(Format(Action::OK), Format(Result),
            'OK().Invoke() on a StandardDialog must close it reporting OK.');
        Assert.AreEqual(1, CountLines('H1'),
            'OK on the host must save the row the handler typed into its part.');
        Assert.AreEqual('Alpha', FirstReference('H1'),
            'The saved part row must carry the value the handler typed.');
    end;

    // CLAIM: a part row that was started and typed into but never left is not written when the
    // handler closes the modal with Cancel.
    [Test]
    [HandlerFunctions('PcnDialogTypeALineThenCancelHandler')]
    procedure CancelInvoke_OnAStandardDialog_DiscardsThePendingPartRow()
    var
        Header: Record "PCN Header";
        Dialog: Page "PCN Dialog";
        Result: Action;
    begin
        Initialize(Header);

        Dialog.SetRecord(Header);
        Result := Dialog.RunModal();

        Assert.AreEqual(Format(Action::Cancel), Format(Result),
            'Cancel().Invoke() must close the modal reporting Cancel even after a part row was typed.');
        Assert.AreEqual(0, CountLines('H1'),
            'Cancel must not write the part row that was still being edited when it was pressed.');
    end;

    // DISCRIMINATOR: 2 = Cancel saves everything, 1 = it drops only the pending row,
    // 0 = it rolls the part back -- and the probe is what makes that third reading safe, because
    // 0 would also be the answer if New() had never committed the first row.
    [Test]
    [HandlerFunctions('PcnDialogTypeTwoLinesThenCancelHandler')]
    procedure CancelInvoke_OnAStandardDialog_KeepsTheCommittedPartRowAndDropsThePendingOne()
    var
        Header: Record "PCN Header";
        Probe: Record "PCN Probe";
        Dialog: Page "PCN Dialog";
    begin
        Initialize(Header);

        Dialog.SetRecord(Header);
        Dialog.RunModal();

        Assert.IsTrue(Probe.Get('AFTER-SECOND-NEW'),
            'The handler must have recorded what it saw after the second New().');
        Assert.AreEqual(1, Probe."Line Count",
            'Moving to a second row with New() must have committed the first one, so a zero below is a rollback and not a row that was never written.');
        Assert.AreEqual(1, CountLines('H1'),
            'Cancel must keep the part row that New() already committed and drop only the one still being edited.');
        Assert.AreEqual('First', FirstReference('H1'),
            'The row that survives Cancel must be the one the handler finished, not the one it was still typing.');
    end;

    // HOST FIELD, positive half: a field change on the host record itself is saved by OK. This is
    // what stops the Cancel arm below from passing on the value Initialize() seeded.
    [Test]
    [HandlerFunctions('PcnDialogTypeHeaderFieldThenOkHandler')]
    procedure OkInvoke_OnAStandardDialog_SavesThePendingHostFieldChange()
    var
        Header: Record "PCN Header";
        Dialog: Page "PCN Dialog";
    begin
        Initialize(Header);

        Dialog.SetRecord(Header);
        Dialog.RunModal();

        Header.Get('H1');
        Assert.AreEqual('Changed', Header.Descr,
            'OK must write the host field change the handler typed.');
    end;

    // HOST FIELD, the question: the same change, cancelled.
    [Test]
    [HandlerFunctions('PcnDialogTypeHeaderFieldThenCancelHandler')]
    procedure CancelInvoke_OnAStandardDialog_DiscardsThePendingHostFieldChange()
    var
        Header: Record "PCN Header";
        Dialog: Page "PCN Dialog";
    begin
        Initialize(Header);

        Dialog.SetRecord(Header);
        Dialog.RunModal();

        Header.Get('H1');
        Assert.AreEqual('Host', Header.Descr,
            'Cancel must not write the host field change that was pending when it was pressed.');
    end;

    // --- handlers ---------------------------------------------------------------------------

    [ModalPageHandler]
    procedure PcnCardCancelHandler(var Card: TestPage "PCN Card")
    begin
        Card.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure PcnCardTypeALineThenOkHandler(var Card: TestPage "PCN Card")
    begin
        Card.Lines.New();
        Card.Lines.Reference.SetValue('Alpha');
        Card.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PcnDialogCancelNothingTypedHandler(var Dialog: TestPage "PCN Dialog")
    begin
        Dialog.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure PcnDialogTypeALineThenOkHandler(var Dialog: TestPage "PCN Dialog")
    begin
        Dialog.Lines.New();
        Dialog.Lines.Reference.SetValue('Alpha');
        Dialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PcnDialogTypeALineThenCancelHandler(var Dialog: TestPage "PCN Dialog")
    begin
        Dialog.Lines.New();
        Dialog.Lines.Reference.SetValue('Alpha');
        Dialog.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure PcnDialogTypeTwoLinesThenCancelHandler(var Dialog: TestPage "PCN Dialog")
    begin
        Dialog.Lines.New();
        Dialog.Lines.Reference.SetValue('First');
        Dialog.Lines.New();
        Dialog.Lines.Reference.SetValue('Second');

        // The moment the first row is expected to have been committed, read before anything
        // closes the page. Without it a final count of zero could be a rollback or a first row
        // that was never written, and nothing else in the fixture tells those apart.
        RecordProbe('H1');

        Dialog.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure PcnDialogTypeHeaderFieldThenOkHandler(var Dialog: TestPage "PCN Dialog")
    begin
        Dialog.Descr.SetValue('Changed');
        Dialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PcnDialogTypeHeaderFieldThenCancelHandler(var Dialog: TestPage "PCN Dialog")
    begin
        Dialog.Descr.SetValue('Changed');
        Dialog.Cancel().Invoke();
    end;
}
