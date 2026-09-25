// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-next-method
// Scope: in-scope
// Fixtures used: OKP Header (60760), OKP Line (60761), OKP Header Card (60760),
//                OKP Lines Part (60761), ALT TestPart Row (60341), ALT TestPart Host (60344),
//                Assert (60021)
//
// WHERE does a part's FIRST Next() land when nothing has navigated the part yet?
//
// "Test TestPart" (60346) walks a part with Next() only after First() or Last(). Microsoft's
// own tests also call Next() on a part nothing has positioned, right after moving the host:
//
//     PostedSalesInvoice.OpenEdit();
//     PostedSalesInvoice.GotoKey(PostedSalesInvoiceNo);
//     PostedSalesInvoice.SalesInvLines.Next();   // expected: the invoice's FIRST line
//
// (codeunit 135407 "Prepayments Plan-based E2E", VerifyPostedSalesInvoicePrepayment). That
// test passes on BC, so the first Next() there lands on the first line, not the second.
//
// The claim, per arm: a part's repeater starts unpositioned -- its current row already reads
// as the first row, but the first Next() moves ONTO that first row rather than past it. That
// holds when the host has just opened, and again after the host moves to another row and the
// part refills. Once the test has positioned the part itself (First()), Next() steps to the
// second row as usual; that control arm is what stops a part which simply never moves from
// passing the others.
//
// Two headers with two lines each, and every line's Reference names its header and line, so
// a part that ignored the link or stayed on the first header's rows fails on the value.
//
// Filed from AlRunner#4623.
codeunit 60762 "OKP Part Next Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Line: Record "OKP Line";
        Header: Record "OKP Header";
    begin
        Line.DeleteAll();
        Header.DeleteAll();
        AddHeader('H1');
        AddLine('H1', 10000, 'H1-FIRST');
        AddLine('H1', 20000, 'H1-SECOND');
        AddHeader('H2');
        AddLine('H2', 10000, 'H2-FIRST');
        AddLine('H2', 20000, 'H2-SECOND');
    end;

    local procedure AddHeader(HeaderCode: Code[20])
    var
        Header: Record "OKP Header";
    begin
        Header.Init();
        Header."Code" := HeaderCode;
        Header.Descr := HeaderCode;
        Header.Insert();
    end;

    local procedure AddLine(HeaderCode: Code[20]; LineNo: Integer; Reference: Text[30])
    var
        Line: Record "OKP Line";
    begin
        Line.Init();
        Line."Header Code" := HeaderCode;
        Line."Line No." := LineNo;
        Line.Reference := Reference;
        Line.Insert();
    end;

    // CLAIM: the shape Microsoft's test uses. Host opened, moved to another header by GotoKey,
    // then one Next() on the part: it lands on that header's FIRST line.
    [Test]
    procedure LinkedPart_AfterHostGotoKey_FirstNextLandsOnTheFirstRow()
    var
        Card: TestPage "OKP Header Card";
    begin
        Initialize();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Assert.IsTrue(Card.Lines.Next(), 'the first Next() on a part with rows must answer true');
        Assert.AreEqual('H2-FIRST', Card.Lines.Reference.Value(),
            'the first Next() after the host''s GotoKey must land on the part''s first row');
        Card.Close();
    end;

    // CLAIM: and the second Next() then lands on the second line, so the first one was a real
    // move onto row one and the walk continues from there.
    [Test]
    procedure LinkedPart_AfterHostGotoKey_SecondNextLandsOnTheSecondRow()
    var
        Card: TestPage "OKP Header Card";
    begin
        Initialize();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Card.Lines.Next();
        Assert.IsTrue(Card.Lines.Next(), 'the second Next() must answer true while a second row exists');
        Assert.AreEqual('H2-SECOND', Card.Lines.Reference.Value(),
            'the second Next() after the host''s GotoKey must land on the part''s second row');
        Card.Close();
    end;

    // CLAIM: before any Next(), the part already READS as its first row. Unpositioned is about
    // where the next move goes, not about what the controls show.
    [Test]
    procedure LinkedPart_AfterHostGotoKey_ReadsTheFirstRowBeforeAnyNext()
    var
        Card: TestPage "OKP Header Card";
    begin
        Initialize();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Assert.AreEqual('H2-FIRST', Card.Lines.Reference.Value(),
            'before any navigation the part must read its first row');
        Card.Close();
    end;

    // CLAIM: the same holds on a read-only host, which is how Microsoft's test opens a posted
    // document (its subform has no draft line).
    [Test]
    procedure LinkedPart_OpenView_AfterHostGotoKey_FirstNextLandsOnTheFirstRow()
    var
        Card: TestPage "OKP Header Card";
    begin
        Initialize();
        Card.OpenView();
        Card.GoToKey('H2');
        Assert.IsTrue(Card.Lines.Next(), 'the first Next() on a part with rows must answer true');
        Assert.AreEqual('H2-FIRST', Card.Lines.Reference.Value(),
            'on a read-only host the first Next() after GotoKey must land on the part''s first row');
        Card.Close();
    end;

    // CLAIM: with no host move at all -- the host has just opened on its first header -- the
    // part's first Next() also lands on its first row.
    [Test]
    procedure LinkedPart_AtOpen_FirstNextLandsOnTheFirstRow()
    var
        Card: TestPage "OKP Header Card";
    begin
        Initialize();
        Card.OpenEdit();
        Assert.AreEqual('H1', Card."Code".Value(), 'the card must open on the lowest header');
        Assert.IsTrue(Card.Lines.Next(), 'the first Next() on a part with rows must answer true');
        Assert.AreEqual('H1-FIRST', Card.Lines.Reference.Value(),
            'the first Next() after the host opens must land on the part''s first row');
        Card.Close();
    end;

    // CONTROL: once the test has positioned the part itself with First(), Next() steps to the
    // SECOND row. A part whose Next() never moves at all passes the arms above and fails here.
    [Test]
    procedure LinkedPart_FirstThenNext_LandsOnTheSecondRow()
    var
        Card: TestPage "OKP Header Card";
    begin
        Initialize();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Card.Lines.First();
        Assert.IsTrue(Card.Lines.Next(), 'Next() after First() must answer true while a second row exists');
        Assert.AreEqual('H2-SECOND', Card.Lines.Reference.Value(),
            'Next() after First() must land on the part''s second row');
        Card.Close();
    end;

    // CLAIM: a part with no SubPageLink behaves the same way at open -- the first Next() lands
    // on the first row of its own rowset.
    [Test]
    procedure UnlinkedPart_AtOpen_FirstNextLandsOnTheFirstRow()
    var
        Row: Record "ALT TestPart Row";
        Host: TestPage "ALT TestPart Host";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Grp := 'A';
        Row."Line No." := 10;
        Row.Descr := 'Alpha';
        Row.Insert();
        Row.Init();
        Row.Grp := 'A';
        Row."Line No." := 20;
        Row.Descr := 'Beta';
        Row.Insert();

        Host.OpenEdit();
        Assert.IsTrue(Host.Lines.Next(), 'the first Next() on a part with rows must answer true');
        Assert.AreEqual('10', Host.Lines.LineNo.Value(),
            'the first Next() after the host opens must land on the unlinked part''s first row');
        Host.Close();
    end;
}
