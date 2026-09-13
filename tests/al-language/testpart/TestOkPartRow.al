// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-new-method
// Scope: in-scope
// Fixtures used: OKP Header (60760), OKP Line (60761), OKP Header Card (60760),
//                OKP Lines Part (60761), Assert (60021)
//
// WHEN a test opens a card itself, starts a row in one of its parts with New(), types a value,
// and closes the card with its built-in OK action, is that row saved?
//
// "Test TestPart" (60346) pins the TestPage.Close() route for a part row, and
// "Opf Ok Part Flush Tests" (60663) pins OK pressed by a [ModalPageHandler]. This suite pins the
// remaining route: OK().Invoke() on a page the TEST opened, which is what Microsoft's own tests
// do (codeunit 136601 "ERM RS Data Templates", ConfigTemplateLine_Lookup*).
//
// Every assertion reads the part's table after the page has closed, so a row that was only
// ever held by the page fails it.
//
// Filed from AlRunner#4146.
codeunit 60760 "OKP Ok Part Row Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize(var Header: Record "OKP Header")
    var
        Line: Record "OKP Line";
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
        Line: Record "OKP Line";
    begin
        Line.SetRange("Header Code", HeaderCode);
        exit(Line.Count());
    end;

    // CLAIM: OK().Invoke() on the host saves the part row the test started and typed into.
    [Test]
    procedure OkInvoke_SavesThePartRowStartedByNew()
    var
        Header: Record "OKP Header";
        Line: Record "OKP Line";
        Card: TestPage "OKP Header Card";
    begin
        Initialize(Header);

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.Lines.Reference.SetValue('Alpha');
        Card.OK().Invoke();

        Assert.AreEqual(1, CountLines('H1'),
            'OK on the host must save the row typed into its part, as Close() does.');
        Line.SetRange("Header Code", 'H1');
        Line.FindFirst();
        Assert.AreEqual('Alpha', Line.Reference,
            'The saved part row must carry the value that was typed.');
    end;

    // Two typed rows: the first is saved when New() leaves it, the second is still being edited
    // when OK is pressed. Both must be in the table, so a fixed count of 1 cannot pass.
    [Test]
    procedure OkInvoke_SavesTheRowStillBeingEditedAfterAnEarlierOne()
    var
        Header: Record "OKP Header";
        Line: Record "OKP Line";
        Card: TestPage "OKP Header Card";
    begin
        Initialize(Header);

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.Lines.Reference.SetValue('First');
        Card.Lines.New();
        Card.Lines.Reference.SetValue('Second');
        Card.OK().Invoke();

        Assert.AreEqual(2, CountLines('H1'),
            'Both typed part rows must be saved, including the one being edited when OK was pressed.');
        Line.SetRange("Header Code", 'H1');
        Line.FindLast();
        Assert.AreEqual('Second', Line.Reference,
            'The last row in key order must be the one typed last.');
    end;

    // NEGATIVE CONTROL: New() with nothing typed, same OK. No row may appear, so an
    // implementation that satisfies the arms above by writing whatever New() started fails here.
    [Test]
    procedure OkInvoke_DoesNotSaveAnUntouchedNewPartRow()
    var
        Header: Record "OKP Header";
        Card: TestPage "OKP Header Card";
    begin
        Initialize(Header);

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.OK().Invoke();

        Assert.AreEqual(0, CountLines('H1'),
            'A part row that New() started and nothing was typed into must not be saved.');
    end;
}
