// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-cancel-method
// Scope: in-scope
// Fixtures used: PCN Header (60533), PCN Line (60534), PCN Card (60533),
//                PCN Lines Part (60534), PCN Dialog (60535), Assert (60021)
//
// WHEN a [ModalPageHandler] starts a row in a part with New(), types a value into it, and then
// closes the modal with the built-in Cancel, does that row reach the database?
//
// "Opf Ok Part Flush Tests" (60663) pins the OK half of this on a temporary-sourced part, and
// "OKP Ok Part Row Tests" (60760) pins OK on a card the test opened itself. Neither says
// anything about Cancel, and the two plausible answers are far apart. Cancel could leave the
// pending row unwritten -- which is what these arms expect -- or it could write it like any
// other close, since a card's already-committed edits are famously NOT rolled back by Cancel
// or Escape, and a close that sets no explicit save/discard intent has to do one or the other.
//
// How the arms separate those, and separate both from a broken fixture:
//
//   * ..._WithNothingTyped_ClosesTheModalReportingCancel -- the chrome control. Whether a page
//     offers a built-in Cancel at all is a property of its chrome, and the page types disagree
//     ("TBA Tests" (60338) measures four that do). If a host here has no Cancel, this arm is
//     where that shows up, and the measurement arms cannot be misread as an answer about part
//     rows.
//   * ..._SavesThePendingPartRow (OK) -- the positive control. The row CAN be written through
//     this fixture, so a zero below is about Cancel and not about a SubPageLink that never
//     worked.
//   * ..._DiscardsThePendingPartRow -- the measurement.
//   * ..._KeepsTheCommittedPartRowAndDropsThePendingOne -- the discriminator. Two rows are
//     typed: the first is committed when New() moves off it, the second is still being edited
//     when Cancel is pressed. 2 means Cancel saves everything, 1 means it drops only what is
//     pending, 0 means it rolls the part back -- one assertion, three distinguishable answers.
//   * CancelInvoke_OnACard_DiscardsThePendingHostFieldChange -- the same question one level up,
//     so the part answer can be compared against the host answer instead of assumed to match.
//
// Every arm runs twice over, once on a Card and once on a StandardDialog, because the two
// questions above are independent: a page type that offers no Cancel cannot answer the part-row
// question at all, and only a StandardDialog is already known to offer one ("Test Page Modal"
// (60703) is one and codeunit 60702 invokes its Cancel).
//
// Every assertion reads the table AFTER RunModal has returned, so a row that only ever lived in
// the page cannot satisfy one.
//
// Filed from AlRunner#4150. Nothing in that issue had been measured against a service tier;
// this file is the measurement, and the assertions are what its author expected rather than
// anything a tier has yet confirmed.
codeunit 60535 "PCN Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize(var Header: Record "PCN Header")
    var
        Line: Record "PCN Line";
    begin
        Line.DeleteAll();
        Header.DeleteAll();

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

    // --- Card host -------------------------------------------------------------------------

    // CHROME CONTROL: a modally-run Card offers a built-in Cancel, and invoking it closes the
    // page reporting Cancel.
    [Test]
    [HandlerFunctions('PcnCardCancelNothingTypedHandler')]
    procedure CancelInvoke_OnACard_WithNothingTyped_ClosesTheModalReportingCancel()
    var
        Header: Record "PCN Header";
        Card: Page "PCN Card";
        Result: Action;
    begin
        Initialize(Header);

        Card.SetRecord(Header);
        Result := Card.RunModal();

        Assert.AreEqual(Format(Action::Cancel), Format(Result),
            'Cancel().Invoke() on a modally-run Card must close it reporting Cancel.');
        Assert.AreEqual(0, CountLines('H1'),
            'A handler that typed nothing must leave the part''s table empty.');
    end;

    // POSITIVE CONTROL: the same fixture closed with OK writes the typed row.
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

    // CLAIM: a part row that was started and typed into but never left is not written when the
    // handler closes the modal with Cancel.
    [Test]
    [HandlerFunctions('PcnCardTypeALineThenCancelHandler')]
    procedure CancelInvoke_OnACard_DiscardsThePendingPartRow()
    var
        Header: Record "PCN Header";
        Card: Page "PCN Card";
        Result: Action;
    begin
        Initialize(Header);

        Card.SetRecord(Header);
        Result := Card.RunModal();

        Assert.AreEqual(Format(Action::Cancel), Format(Result),
            'Cancel().Invoke() must close the modal reporting Cancel even after a part row was typed.');
        Assert.AreEqual(0, CountLines('H1'),
            'Cancel must not write the part row that was still being edited when it was pressed.');
    end;

    // DISCRIMINATOR: 2 = Cancel saves everything, 1 = it drops only the pending row,
    // 0 = it rolls the part back.
    [Test]
    [HandlerFunctions('PcnCardTypeTwoLinesThenCancelHandler')]
    procedure CancelInvoke_OnACard_KeepsTheCommittedPartRowAndDropsThePendingOne()
    var
        Header: Record "PCN Header";
        Card: Page "PCN Card";
    begin
        Initialize(Header);

        Card.SetRecord(Header);
        Card.RunModal();

        Assert.AreEqual(1, CountLines('H1'),
            'Cancel must keep the part row that New() already committed and drop only the one still being edited.');
        Assert.AreEqual('First', FirstReference('H1'),
            'The row that survives Cancel must be the one the handler finished, not the one it was still typing.');
    end;

    // The same question about the HOST record, so the part answer can be compared with it rather
    // than assumed to be the same fact.
    [Test]
    [HandlerFunctions('PcnCardTypeHeaderFieldThenCancelHandler')]
    procedure CancelInvoke_OnACard_DiscardsThePendingHostFieldChange()
    var
        Header: Record "PCN Header";
        Card: Page "PCN Card";
    begin
        Initialize(Header);

        Card.SetRecord(Header);
        Card.RunModal();

        Header.Get('H1');
        Assert.AreEqual('Host', Header.Descr,
            'Cancel must not write the host field change that was pending when it was pressed.');
    end;

    // --- StandardDialog host ---------------------------------------------------------------

    // CHROME CONTROL for the second host.
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

    // POSITIVE CONTROL for the second host.
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

    // The measurement on the second host.
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

    // The discriminator on the second host.
    [Test]
    [HandlerFunctions('PcnDialogTypeTwoLinesThenCancelHandler')]
    procedure CancelInvoke_OnAStandardDialog_KeepsTheCommittedPartRowAndDropsThePendingOne()
    var
        Header: Record "PCN Header";
        Dialog: Page "PCN Dialog";
    begin
        Initialize(Header);

        Dialog.SetRecord(Header);
        Dialog.RunModal();

        Assert.AreEqual(1, CountLines('H1'),
            'Cancel must keep the part row that New() already committed and drop only the one still being edited.');
        Assert.AreEqual('First', FirstReference('H1'),
            'The row that survives Cancel must be the one the handler finished, not the one it was still typing.');
    end;

    // --- handlers ---------------------------------------------------------------------------

    [ModalPageHandler]
    procedure PcnCardCancelNothingTypedHandler(var Card: TestPage "PCN Card")
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
    procedure PcnCardTypeALineThenCancelHandler(var Card: TestPage "PCN Card")
    begin
        Card.Lines.New();
        Card.Lines.Reference.SetValue('Alpha');
        Card.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure PcnCardTypeTwoLinesThenCancelHandler(var Card: TestPage "PCN Card")
    begin
        Card.Lines.New();
        Card.Lines.Reference.SetValue('First');
        Card.Lines.New();
        Card.Lines.Reference.SetValue('Second');
        Card.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure PcnCardTypeHeaderFieldThenCancelHandler(var Card: TestPage "PCN Card")
    begin
        Card.Descr.SetValue('Changed');
        Card.Cancel().Invoke();
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
        Dialog.Cancel().Invoke();
    end;
}
