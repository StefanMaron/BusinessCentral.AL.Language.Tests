// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-class
// Scope: in-scope
// Fixtures used: BNR Header (69940), BNR Line (69941), BNR Kind (enum 69940), BNR Lines Part (69940),
//                BNR Card (69941), BNR Lines List (69942), BNR Line Card (69943)
//
// PROBE revision: records what each control reads on a part or page that shows no row, per field type.
codeunit 69940 "BNR Blank Part Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

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

    [Test]
    procedure P0_PartWithRow()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H1');
        Error(ObsPart(Card));
    end;

    [Test]
    procedure P1_PartHostRowWithNoLines()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H0');
        Error(ObsPart(Card));
    end;

    [Test]
    procedure P2_PartHostMovedFromRowToEmpty()
    var
        Card: TestPage "BNR Card";
        Seen: Text;
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H1');
        Seen := Card.Lines.QTxt.Value;
        Card.GoToKey('H0');
        Error('before=[' + Seen + '] after: ' + ObsPart(Card));
    end;

    [Test]
    procedure P3_PartHostOpenedOnEmptyHeaderTable()
    var
        Card: TestPage "BNR Card";
        Header: Record "BNR Header";
        Line: Record "BNR Line";
    begin
        Initialize();
        Header.DeleteAll();
        Line.DeleteAll();
        Card.OpenView();
        Error(ObsPart(Card));
    end;

    [Test]
    procedure P4_ListOpenedOnEmptyTable()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenView();
        Error(ObsList(Card));
    end;

    [Test]
    procedure P5_ListWithRow()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Error(ObsList(Card));
    end;

    [Test]
    procedure P6_CardOpenedOnEmptyTable()
    var
        Card: TestPage "BNR Line Card";
    begin
        Initialize();
        Card.OpenView();
        Error(ObsLCard(Card));
    end;

    [Test]
    procedure P7_ListFilteredToNothing()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.Filter.SetFilter("Header No.", 'ZZZ');
        Error(ObsList(Card));
    end;

    [Test]
    procedure T_Part_AsInteger()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H0');
        Error(Format(Card.Lines.QInt.AsInteger()));
    end;

    [Test]
    procedure T_Part_AsDecimal()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H0');
        Error(Format(Card.Lines.QDec.AsDecimal()));
    end;

    [Test]
    procedure T_Part_AsBoolean()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H0');
        Error(Format(Card.Lines.QBool.AsBoolean()));
    end;

    [Test]
    procedure T_Part_AsDate()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H0');
        Error(Format(Card.Lines.QDt.AsDate()));
    end;

    [Test]
    procedure T_Part_AsTime()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H0');
        Error(Format(Card.Lines.QTm.AsTime()));
    end;

    [Test]
    procedure T_Part_AsDateTime()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H0');
        Error(Format(Card.Lines.QDtTm.AsDateTime()));
    end;

    [Test]
    procedure T_List_AsInteger()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenView();
        Error(Format(Card.QInt.AsInteger()));
    end;

    [Test]
    procedure T_List_AsDecimal()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenView();
        Error(Format(Card.QDec.AsDecimal()));
    end;

    [Test]
    procedure T_List_AsBoolean()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenView();
        Error(Format(Card.QBool.AsBoolean()));
    end;

    [Test]
    procedure T_List_AsDate()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenView();
        Error(Format(Card.QDt.AsDate()));
    end;

    [Test]
    procedure T_List_AsTime()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenView();
        Error(Format(Card.QTm.AsTime()));
    end;

    [Test]
    procedure T_List_AsDateTime()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenView();
        Error(Format(Card.QDtTm.AsDateTime()));
    end;

    [Test]
    procedure P8_EditableListOpenedOnEmptyTable()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenEdit();
        Error(ObsList(Card));
    end;

    [Test]
    procedure P9_PartUnderEditableHostRowWithNoLines()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenEdit();
        Card.GoToKey('H0');
        Error(ObsPart(Card));
    end;

    [Test]
    procedure T_EditableList_AsInteger()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenEdit();
        Error(Format(Card.QInt.AsInteger()));
    end;

    [Test]
    procedure T_EditablePart_AsInteger()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenEdit();
        Card.GoToKey('H0');
        Error(Format(Card.Lines.QInt.AsInteger()));
    end;

    [Test]
    procedure T_Part_AsInteger_InitValueField()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H0');
        Error(Format(Card.Lines.QIntInit.AsInteger()));
    end;

    [Test]
    procedure T_Part_AsDecimal_InitValueField()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H0');
        Error(Format(Card.Lines.QDecInit.AsDecimal()));
    end;

    [Test]
    procedure T_Part_AsBoolean_InitValueField()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H0');
        Error(Format(Card.Lines.QBoolInit.AsBoolean()));
    end;
}
