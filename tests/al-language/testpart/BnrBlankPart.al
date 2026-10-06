// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-class
// Scope: in-scope
// Fixtures used: BNR Header (69940), BNR Line (69941), BNR Kind (enum 69940), BNR Lines Part (69940),
//                BNR Card (69941), BNR Lines List (69942), BNR Line Card (69943); shared Assert (60021)
//
// WHAT does a control read when its part or page shows NO row?
// The first revisions of this file recorded the readings of one control of every field type
// instead of asserting them. Measured on real BC (every cloud leg): every control reads the empty
// string, whatever its type: Text, Code, Integer, Decimal, Boolean, Option, Date, Time, DateTime,
// Enum, BigInteger, Guid, Duration, and the fields that declare an InitValue. The typed accessors
// answer the type's default (AsInteger 0, AsDecimal 0, AsBoolean false, AsDate 0D, AsTime 0T),
// also on a field with an InitValue.
// This holds for a part whose link matches no row (the host moved to a row with no lines, or the
// host has no row at all), for a list and a card over an empty table, and for a list filtered to
// nothing. It does NOT hold for the draft line of an editable page, which is a row: there the
// controls read the defaults the line was started with (QInt 0, QIntInit its InitValue 5).
//
// NOT pinned here, on purpose: AsDateTime() on a control with no row raises an unhandled CLR
// NullReferenceException on BC (BC unboxes a null into a DateTime), and the text of that failure is
// not something an AL test should assert. The Value of a populated Date/Time/DateTime/Guid/Duration
// control is not asserted either; its spelling is not this file's claim.
codeunit 69940 "BNR Blank Part Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Header: Record "BNR Header";
        Line: Record "BNR Line";
    begin
        Line.DeleteAll();
        Header.DeleteAll();
        Header.Init();
        Header."No." := 'H0';
        Header.Insert();
        Header.Init();
        Header."No." := 'H1';
        Header.Insert();
    end;

    local procedure InsertFullLine(HeaderNo: Code[20]; LineNo: Integer)
    var
        Line: Record "BNR Line";
    begin
        Line.Init();
        Line."Header No." := HeaderNo;
        Line."Line No." := LineNo;
        Line.QTxt := 'text';
        Line.QCd := 'CODE';
        Line.QInt := 42;
        Line.QDec := 3.25;
        Line.QBool := true;
        Line.QOpt := Line.QOpt::Gamma;
        Line.QDt := DMY2Date(2, 3, 2024);
        Line.QTm := 123456T;
        Line.QDtTm := CreateDateTime(DMY2Date(2, 3, 2024), 123456T);
        Line.QEn := Line.QEn::One;
        Line.QBig := 9000000000L;
        Line.QGd := '{11111111-2222-3333-4444-555555555555}';
        Line.QDur := 5000;
        Line.QIntInit := 7;
        Line.QDecInit := 7.5;
        Line.QBoolInit := false;
        Line.Insert();
    end;

    local procedure ObsPart(var Card: TestPage "BNR Card"): Text
    var
        Obs: Text;
    begin
        Obs += 'HeaderNo=[' + Card.Lines.HeaderNo.Value + '] ';
        Obs += 'LineNo=[' + Card.Lines.LineNo.Value + '] ';
        Obs += 'QTxt=[' + Card.Lines.QTxt.Value + '] ';
        Obs += 'QCd=[' + Card.Lines.QCd.Value + '] ';
        Obs += 'QInt=[' + Card.Lines.QInt.Value + '] ';
        Obs += 'QDec=[' + Card.Lines.QDec.Value + '] ';
        Obs += 'QBool=[' + Card.Lines.QBool.Value + '] ';
        Obs += 'QOpt=[' + Card.Lines.QOpt.Value + '] ';
        Obs += 'QDt=[' + Card.Lines.QDt.Value + '] ';
        Obs += 'QTm=[' + Card.Lines.QTm.Value + '] ';
        Obs += 'QDtTm=[' + Card.Lines.QDtTm.Value + '] ';
        Obs += 'QEn=[' + Card.Lines.QEn.Value + '] ';
        Obs += 'QBig=[' + Card.Lines.QBig.Value + '] ';
        Obs += 'QGd=[' + Card.Lines.QGd.Value + '] ';
        Obs += 'QDur=[' + Card.Lines.QDur.Value + '] ';
        Obs += 'QIntInit=[' + Card.Lines.QIntInit.Value + '] ';
        Obs += 'QDecInit=[' + Card.Lines.QDecInit.Value + '] ';
        Obs += 'QBoolInit=[' + Card.Lines.QBoolInit.Value + '] ';
        exit(Obs);
    end;

    local procedure ObsList(var Card: TestPage "BNR Lines List"): Text
    var
        Obs: Text;
    begin
        Obs += 'HeaderNo=[' + Card.HeaderNo.Value + '] ';
        Obs += 'LineNo=[' + Card.LineNo.Value + '] ';
        Obs += 'QTxt=[' + Card.QTxt.Value + '] ';
        Obs += 'QCd=[' + Card.QCd.Value + '] ';
        Obs += 'QInt=[' + Card.QInt.Value + '] ';
        Obs += 'QDec=[' + Card.QDec.Value + '] ';
        Obs += 'QBool=[' + Card.QBool.Value + '] ';
        Obs += 'QOpt=[' + Card.QOpt.Value + '] ';
        Obs += 'QDt=[' + Card.QDt.Value + '] ';
        Obs += 'QTm=[' + Card.QTm.Value + '] ';
        Obs += 'QDtTm=[' + Card.QDtTm.Value + '] ';
        Obs += 'QEn=[' + Card.QEn.Value + '] ';
        Obs += 'QBig=[' + Card.QBig.Value + '] ';
        Obs += 'QGd=[' + Card.QGd.Value + '] ';
        Obs += 'QDur=[' + Card.QDur.Value + '] ';
        Obs += 'QIntInit=[' + Card.QIntInit.Value + '] ';
        Obs += 'QDecInit=[' + Card.QDecInit.Value + '] ';
        Obs += 'QBoolInit=[' + Card.QBoolInit.Value + '] ';
        exit(Obs);
    end;

    local procedure ObsLCard(var Card: TestPage "BNR Line Card"): Text
    var
        Obs: Text;
    begin
        Obs += 'HeaderNo=[' + Card.HeaderNo.Value + '] ';
        Obs += 'LineNo=[' + Card.LineNo.Value + '] ';
        Obs += 'QTxt=[' + Card.QTxt.Value + '] ';
        Obs += 'QCd=[' + Card.QCd.Value + '] ';
        Obs += 'QInt=[' + Card.QInt.Value + '] ';
        Obs += 'QDec=[' + Card.QDec.Value + '] ';
        Obs += 'QBool=[' + Card.QBool.Value + '] ';
        Obs += 'QOpt=[' + Card.QOpt.Value + '] ';
        Obs += 'QDt=[' + Card.QDt.Value + '] ';
        Obs += 'QTm=[' + Card.QTm.Value + '] ';
        Obs += 'QDtTm=[' + Card.QDtTm.Value + '] ';
        Obs += 'QEn=[' + Card.QEn.Value + '] ';
        Obs += 'QBig=[' + Card.QBig.Value + '] ';
        Obs += 'QGd=[' + Card.QGd.Value + '] ';
        Obs += 'QDur=[' + Card.QDur.Value + '] ';
        Obs += 'QIntInit=[' + Card.QIntInit.Value + '] ';
        Obs += 'QDecInit=[' + Card.QDecInit.Value + '] ';
        Obs += 'QBoolInit=[' + Card.QBoolInit.Value + '] ';
        exit(Obs);
    end;

    local procedure AssertPartBlank(var Card: TestPage "BNR Card")
    begin
        Assert.AreEqual('', Card.Lines.HeaderNo.Value, 'HeaderNo reads blank');
        Assert.AreEqual('', Card.Lines.LineNo.Value, 'LineNo reads blank');
        Assert.AreEqual('', Card.Lines.QTxt.Value, 'QTxt reads blank');
        Assert.AreEqual('', Card.Lines.QCd.Value, 'QCd reads blank');
        Assert.AreEqual('', Card.Lines.QInt.Value, 'QInt reads blank');
        Assert.AreEqual('', Card.Lines.QDec.Value, 'QDec reads blank');
        Assert.AreEqual('', Card.Lines.QBool.Value, 'QBool reads blank');
        Assert.AreEqual('', Card.Lines.QOpt.Value, 'QOpt reads blank');
        Assert.AreEqual('', Card.Lines.QDt.Value, 'QDt reads blank');
        Assert.AreEqual('', Card.Lines.QTm.Value, 'QTm reads blank');
        Assert.AreEqual('', Card.Lines.QDtTm.Value, 'QDtTm reads blank');
        Assert.AreEqual('', Card.Lines.QEn.Value, 'QEn reads blank');
        Assert.AreEqual('', Card.Lines.QBig.Value, 'QBig reads blank');
        Assert.AreEqual('', Card.Lines.QGd.Value, 'QGd reads blank');
        Assert.AreEqual('', Card.Lines.QDur.Value, 'QDur reads blank');
        Assert.AreEqual('', Card.Lines.QIntInit.Value, 'QIntInit reads blank');
        Assert.AreEqual('', Card.Lines.QDecInit.Value, 'QDecInit reads blank');
        Assert.AreEqual('', Card.Lines.QBoolInit.Value, 'QBoolInit reads blank');
    end;

    local procedure AssertPartTypedDefaults(var Card: TestPage "BNR Card")
    begin
        Assert.AreEqual(0, Card.Lines.QInt.AsInteger(), 'AsInteger');
        Assert.AreEqual(0, Card.Lines.QDec.AsDecimal(), 'AsDecimal');
        Assert.IsFalse(Card.Lines.QBool.AsBoolean(), 'AsBoolean');
        Assert.AreEqual(0D, Card.Lines.QDt.AsDate(), 'AsDate');
        Assert.AreEqual(0T, Card.Lines.QTm.AsTime(), 'AsTime');
        Assert.AreEqual(0, Card.Lines.QIntInit.AsInteger(), 'AsInteger of a field with an InitValue');
        Assert.AreEqual(0, Card.Lines.QDecInit.AsDecimal(), 'AsDecimal of a field with an InitValue');
        Assert.IsFalse(Card.Lines.QBoolInit.AsBoolean(), 'AsBoolean of a field with an InitValue');
    end;

    local procedure AssertListBlank(var Card: TestPage "BNR Lines List")
    begin
        Assert.AreEqual('', Card.HeaderNo.Value, 'HeaderNo reads blank');
        Assert.AreEqual('', Card.LineNo.Value, 'LineNo reads blank');
        Assert.AreEqual('', Card.QTxt.Value, 'QTxt reads blank');
        Assert.AreEqual('', Card.QCd.Value, 'QCd reads blank');
        Assert.AreEqual('', Card.QInt.Value, 'QInt reads blank');
        Assert.AreEqual('', Card.QDec.Value, 'QDec reads blank');
        Assert.AreEqual('', Card.QBool.Value, 'QBool reads blank');
        Assert.AreEqual('', Card.QOpt.Value, 'QOpt reads blank');
        Assert.AreEqual('', Card.QDt.Value, 'QDt reads blank');
        Assert.AreEqual('', Card.QTm.Value, 'QTm reads blank');
        Assert.AreEqual('', Card.QDtTm.Value, 'QDtTm reads blank');
        Assert.AreEqual('', Card.QEn.Value, 'QEn reads blank');
        Assert.AreEqual('', Card.QBig.Value, 'QBig reads blank');
        Assert.AreEqual('', Card.QGd.Value, 'QGd reads blank');
        Assert.AreEqual('', Card.QDur.Value, 'QDur reads blank');
        Assert.AreEqual('', Card.QIntInit.Value, 'QIntInit reads blank');
        Assert.AreEqual('', Card.QDecInit.Value, 'QDecInit reads blank');
        Assert.AreEqual('', Card.QBoolInit.Value, 'QBoolInit reads blank');
    end;

    local procedure AssertListTypedDefaults(var Card: TestPage "BNR Lines List")
    begin
        Assert.AreEqual(0, Card.QInt.AsInteger(), 'AsInteger');
        Assert.AreEqual(0, Card.QDec.AsDecimal(), 'AsDecimal');
        Assert.IsFalse(Card.QBool.AsBoolean(), 'AsBoolean');
        Assert.AreEqual(0D, Card.QDt.AsDate(), 'AsDate');
        Assert.AreEqual(0T, Card.QTm.AsTime(), 'AsTime');
        Assert.AreEqual(0, Card.QIntInit.AsInteger(), 'AsInteger of a field with an InitValue');
        Assert.AreEqual(0, Card.QDecInit.AsDecimal(), 'AsDecimal of a field with an InitValue');
        Assert.IsFalse(Card.QBoolInit.AsBoolean(), 'AsBoolean of a field with an InitValue');
    end;

    local procedure AssertLineCardBlank(var Card: TestPage "BNR Line Card")
    begin
        Assert.AreEqual('', Card.HeaderNo.Value, 'HeaderNo reads blank');
        Assert.AreEqual('', Card.LineNo.Value, 'LineNo reads blank');
        Assert.AreEqual('', Card.QTxt.Value, 'QTxt reads blank');
        Assert.AreEqual('', Card.QCd.Value, 'QCd reads blank');
        Assert.AreEqual('', Card.QInt.Value, 'QInt reads blank');
        Assert.AreEqual('', Card.QDec.Value, 'QDec reads blank');
        Assert.AreEqual('', Card.QBool.Value, 'QBool reads blank');
        Assert.AreEqual('', Card.QOpt.Value, 'QOpt reads blank');
        Assert.AreEqual('', Card.QDt.Value, 'QDt reads blank');
        Assert.AreEqual('', Card.QTm.Value, 'QTm reads blank');
        Assert.AreEqual('', Card.QDtTm.Value, 'QDtTm reads blank');
        Assert.AreEqual('', Card.QEn.Value, 'QEn reads blank');
        Assert.AreEqual('', Card.QBig.Value, 'QBig reads blank');
        Assert.AreEqual('', Card.QGd.Value, 'QGd reads blank');
        Assert.AreEqual('', Card.QDur.Value, 'QDur reads blank');
        Assert.AreEqual('', Card.QIntInit.Value, 'QIntInit reads blank');
        Assert.AreEqual('', Card.QDecInit.Value, 'QDecInit reads blank');
        Assert.AreEqual('', Card.QBoolInit.Value, 'QBoolInit reads blank');
    end;

    local procedure AssertListDraftLine(var Card: TestPage "BNR Lines List")
    begin
        Assert.AreEqual('0', Card.QInt.Value, 'QInt reads its default on the draft line');
        Assert.AreEqual('0.00', Card.QDec.Value, 'QDec');
        Assert.AreEqual('No', Card.QBool.Value, 'QBool');
        Assert.AreEqual('Alpha', Card.QOpt.Value, 'QOpt');
        Assert.AreEqual('Zero', Card.QEn.Value, 'QEn');
        Assert.AreEqual('0', Card.QBig.Value, 'QBig');
        Assert.AreEqual('5', Card.QIntInit.Value, 'QIntInit reads its InitValue');
        Assert.AreEqual('2.50', Card.QDecInit.Value, 'QDecInit reads its InitValue');
        Assert.AreEqual('Yes', Card.QBoolInit.Value, 'QBoolInit reads its InitValue');
        Assert.AreEqual(0, Card.QInt.AsInteger(), 'AsInteger on the draft line');
    end;

    local procedure AssertPartDraftLine(var Card: TestPage "BNR Card")
    begin
        Assert.AreEqual('0', Card.Lines.QInt.Value, 'QInt reads its default on the draft line');
        Assert.AreEqual('0.00', Card.Lines.QDec.Value, 'QDec');
        Assert.AreEqual('No', Card.Lines.QBool.Value, 'QBool');
        Assert.AreEqual('Alpha', Card.Lines.QOpt.Value, 'QOpt');
        Assert.AreEqual('Zero', Card.Lines.QEn.Value, 'QEn');
        Assert.AreEqual('0', Card.Lines.QBig.Value, 'QBig');
        Assert.AreEqual('5', Card.Lines.QIntInit.Value, 'QIntInit reads its InitValue');
        Assert.AreEqual('2.50', Card.Lines.QDecInit.Value, 'QDecInit reads its InitValue');
        Assert.AreEqual('Yes', Card.Lines.QBoolInit.Value, 'QBoolInit reads its InitValue');
        Assert.AreEqual(0, Card.Lines.QInt.AsInteger(), 'AsInteger on the draft line');
    end;

    // CLAIM: a part whose link matches no row reads blank in every control.
    [Test]
    procedure NoRow_Part_EveryControlReadsBlank()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H0');
        AssertPartBlank(Card);
    end;

    // CLAIM: the typed accessors of such a control answer the type's default, also for a field whose
    // InitValue is not the default.
    [Test]
    procedure NoRow_Part_TypedReadsAreTheTypeDefault()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H0');
        AssertPartTypedDefaults(Card);
    end;

    // CLAIM: the part blanks while the host shows a row without lines and reads its row again after,
    // so the blank is the part's state and not a one-way latch.
    [Test]
    procedure NoRow_Part_ReadsBlankWhileTheHostShowsNoLines_AndItsValuesAgainAfter()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H1');
        Assert.AreEqual('42', Card.Lines.QInt.Value, 'a row is shown');
        Assert.AreEqual('7', Card.Lines.QIntInit.Value, 'a row is shown (InitValue field)');
        Assert.AreEqual(42, Card.Lines.QInt.AsInteger(), 'typed read of a shown row');

        Card.GoToKey('H0');
        AssertPartBlank(Card);

        Card.GoToKey('H1');
        Assert.AreEqual('42', Card.Lines.QInt.Value, 'a row is shown again');
        Assert.AreEqual('text', Card.Lines.QTxt.Value, 'a row is shown again (text)');
    end;

    // CLAIM: a part of a host that has no row at all reads blank too.
    [Test]
    procedure NoRow_PartOfAHostOverAnEmptyTable_EveryControlReadsBlank()
    var
        Card: TestPage "BNR Card";
        Header: Record "BNR Header";
        Line: Record "BNR Line";
    begin
        Initialize();
        Header.DeleteAll();
        Line.DeleteAll();
        Card.OpenView();
        AssertPartBlank(Card);
    end;

    // CLAIM: a list over an empty table reads blank in every control, and so do its typed accessors.
    [Test]
    procedure NoRow_ListOverAnEmptyTable_EveryControlReadsBlank()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenView();
        AssertListBlank(Card);
        AssertListTypedDefaults(Card);
    end;

    // CLAIM: First() and Last() on that list answer false and leave it showing no row.
    [Test]
    procedure NoRow_ListOverAnEmptyTable_AfterFirstAndLast_StillReadsBlank()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenView();
        Assert.IsFalse(Card.First(), 'First() has no row to go to');
        AssertListBlank(Card);
        Assert.IsFalse(Card.Last(), 'Last() has no row to go to');
        AssertListBlank(Card);
    end;

    // CONTRAST: the same list with a row reads that row, so the blank above is the absence of a row.
    [Test]
    procedure NoRow_Contrast_ListWithARow_ReadsItsValues()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Assert.AreEqual('42', Card.QInt.Value, 'a row is shown');
        Assert.AreEqual('text', Card.QTxt.Value, 'a row is shown (text)');
        Assert.AreEqual('7', Card.QIntInit.Value, 'a row is shown (InitValue field)');
    end;

    // CLAIM: a card over an empty table reads blank in every control.
    [Test]
    procedure NoRow_CardOverAnEmptyTable_EveryControlReadsBlank()
    var
        Card: TestPage "BNR Line Card";
    begin
        Initialize();
        Card.OpenView();
        AssertLineCardBlank(Card);
    end;

    // CLAIM: a list filtered to nothing reads blank.
    [Test]
    procedure NoRow_ListFilteredToNothing_EveryControlReadsBlank()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.Filter.SetFilter("Header No.", 'ZZZ');
        AssertListBlank(Card);
    end;

    // CONTRAST: the draft line of an editable list over an empty table is a row, whose controls read
    // the defaults it was started with.
    [Test]
    procedure NoRow_Contrast_EditableListOverAnEmptyTable_ShowsTheDraftLine_ReadingItsDefaults()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenEdit();
        AssertListDraftLine(Card);
    end;

    // CONTRAST: and so is the draft line of a part under an editable host.
    [Test]
    procedure NoRow_Contrast_PartUnderAnEditableHostWithNoLines_ShowsTheDraftLine_ReadingItsDefaults()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenEdit();
        Card.GoToKey('H0');
        Assert.AreEqual('H0', Card.Lines.HeaderNo.Value, 'the draft line carries the link value');
        AssertPartDraftLine(Card);
    end;

    // CLAIM: a row started with New() on an empty editable list reads the values written to it.
    [Test]
    procedure NoRow_Contrast_NewRowOnAnEmptyEditableList_ReadsTheValuesWrittenToIt()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenEdit();
        Card.New();
        Card.HeaderNo.SetValue('X');
        Card.LineNo.SetValue(1);
        Card.QInt.SetValue(5);
        Assert.AreEqual('5', Card.QInt.Value, 'the new row reads what was written');
        Assert.AreEqual(5, Card.QInt.AsInteger(), 'typed read of the new row');
        Assert.AreEqual('X', Card.HeaderNo.Value, 'the new row reads its key');
    end;
}
