// PROBE revision (AlRunner#5358): what a page reads when its code positions Rec after the page showed no row.
codeunit 69947 "BNR Blank Probe"
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
        Line.Init();
        Line."Header No." := 'H1';
        Line."Line No." := 10;
        Line.QTxt := 'stored';
        Line.QInt := 42;
        Line.Insert();
    end;

    local procedure DeleteLines()
    var
        Line: Record "BNR Line";
    begin
        Line.DeleteAll();
    end;

    local procedure ObsReal(var Card: TestPage "BNR Real List"): Text
    begin
        exit('hdr=[' + Card.HeaderNo.Value + '] line=[' + Card.LineNo.Value + '] txt=[' + Card.QTxt.Value + '] int=[' + Card.QInt.Value + '] asint=[' + Format(Card.QInt.AsInteger()) + ']');
    end;

    local procedure ObsTemp(var Card: TestPage "BNR Temp List"): Text
    begin
        exit('hdr=[' + Card.HeaderNo.Value + '] line=[' + Card.LineNo.Value + '] txt=[' + Card.QTxt.Value + '] int=[' + Card.QInt.Value + '] asint=[' + Format(Card.QInt.AsInteger()) + ']');
    end;

    local procedure ObsOpen(var Card: TestPage "BNR Temp Open List"): Text
    begin
        exit('hdr=[' + Card.HeaderNo.Value + '] line=[' + Card.LineNo.Value + '] txt=[' + Card.QTxt.Value + '] int=[' + Card.QInt.Value + '] asint=[' + Format(Card.QInt.AsInteger()) + ']');
    end;

    local procedure ObsGet(var Card: TestPage "BNR Get List"): Text
    begin
        exit('hdr=[' + Card.HeaderNo.Value + '] line=[' + Card.LineNo.Value + '] txt=[' + Card.QTxt.Value + '] int=[' + Card.QInt.Value + '] asint=[' + Format(Card.QInt.AsInteger()) + ']');
    end;

    local procedure ObsCard(var Card: TestPage "BNR Line Card"): Text
    begin
        exit('hdr=[' + Card.HeaderNo.Value + '] line=[' + Card.LineNo.Value + '] txt=[' + Card.QTxt.Value + '] int=[' + Card.QInt.Value + '] asint=[' + Format(Card.QInt.AsInteger()) + ']');
    end;

    [Test]
    procedure A1_TempList_InsertFind()
    var
        Card: TestPage "BNR Temp List";
        R: Text;
    begin
        Initialize();
        Card.OpenView();
        R := 'before: ' + ObsTemp(Card);
        Card.InsertFind.Invoke();
        R += ' | after: ' + ObsTemp(Card);
        Error(R);
    end;

    [Test]
    procedure A2_TempList_InsertFindUpdate()
    var
        Card: TestPage "BNR Temp List";
        R: Text;
    begin
        Initialize();
        Card.OpenView();
        R := 'before: ' + ObsTemp(Card);
        Card.InsertFindUpdate.Invoke();
        R += ' | after: ' + ObsTemp(Card);
        Error(R);
    end;

    [Test]
    procedure A3_TempList_InsertOnly()
    var
        Card: TestPage "BNR Temp List";
        R: Text;
    begin
        Initialize();
        Card.OpenView();
        R := 'before: ' + ObsTemp(Card);
        Card.InsertOnly.Invoke();
        R += ' | after: ' + ObsTemp(Card);
        Error(R);
    end;

    [Test]
    procedure A4_TempList_FieldsOnly()
    var
        Card: TestPage "BNR Temp List";
        R: Text;
    begin
        Initialize();
        Card.OpenView();
        R := 'before: ' + ObsTemp(Card);
        Card.FieldsOnly.Invoke();
        R += ' | after: ' + ObsTemp(Card);
        Error(R);
    end;

    [Test]
    procedure A5_TempList_InsertFind_ThenFirst()
    var
        Card: TestPage "BNR Temp List";
        R: Text;
    begin
        Initialize();
        Card.OpenView();
        R := 'before: ' + ObsTemp(Card);
        Card.InsertFind.Invoke();
        R += ' | after: ' + ObsTemp(Card);
        Card.First();
        R += ' | afterFirst: ' + ObsTemp(Card);
        Error(R);
    end;

    [Test]
    procedure A6_TempOpenList_InsertsInOnOpenPage()
    var
        Card: TestPage "BNR Temp Open List";
    begin
        Initialize();
        Card.OpenView();
        Error(ObsOpen(Card));
    end;

    [Test]
    procedure A7_GetList_ActionGetsAStoredRow()
    var
        Card: TestPage "BNR Get List";
        R: Text;
    begin
        Initialize();
        Card.OpenView();
        R := 'before: ' + ObsGet(Card);
        Card.GetRow.Invoke();
        R += ' | after: ' + ObsGet(Card);
        Error(R);
    end;

    [Test]
    procedure B1_Card_OpenEdit_EmptyTable()
    var
        Card: TestPage "BNR Line Card";
        Line: Record "BNR Line";
    begin
        Initialize();
        Line.DeleteAll();
        Card.OpenEdit();
        Error(ObsCard(Card));
    end;

    [Test]
    procedure B2_Card_OpenNew_EmptyTable()
    var
        Card: TestPage "BNR Line Card";
        Line: Record "BNR Line";
    begin
        Initialize();
        Line.DeleteAll();
        Card.OpenNew();
        Error(ObsCard(Card));
    end;

    [Test]
    procedure B3_Card_OpenView_EmptyTable()
    var
        Card: TestPage "BNR Line Card";
        Line: Record "BNR Line";
    begin
        Initialize();
        Line.DeleteAll();
        Card.OpenView();
        Error(ObsCard(Card));
    end;
    [Test]
    procedure A8_TempList_KeyOnlyNoInsert()
    var
        Card: TestPage "BNR Temp List";
        R: Text;
    begin
        Initialize();
        Card.OpenView();
        R := 'before: ' + ObsTemp(Card);
        Card.KeyOnly.Invoke();
        R += ' | after: ' + ObsTemp(Card);
        Error(R);
    end;

    [Test]
    procedure A9_TempList_TwoInsertsFindLast()
    var
        Card: TestPage "BNR Temp List";
        R: Text;
    begin
        Initialize();
        Card.OpenView();
        R := 'before: ' + ObsTemp(Card);
        Card.InsertTwoFindLast.Invoke();
        R += ' | after: ' + ObsTemp(Card);
        Card.First();
        R += ' | afterFirst: ' + ObsTemp(Card);
        Error(R);
    end;

    [Test]
    procedure A10_RealList_InsertFind()
    var
        Card: TestPage "BNR Real List";
        R: Text;
    begin
        Initialize();
        DeleteLines();
        Card.OpenView();
        R := 'before: ' + ObsReal(Card);
        Card.InsertFind.Invoke();
        R += ' | after: ' + ObsReal(Card);
        Error(R);
    end;

    [Test]
    procedure A11_GetList_InsertMatching()
    var
        Card: TestPage "BNR Get List";
        R: Text;
    begin
        Initialize();
        Card.OpenView();
        R := 'before: ' + ObsGet(Card);
        Card.InsertMatching.Invoke();
        R += ' | after: ' + ObsGet(Card);
        Error(R);
    end;

    [Test]
    procedure A12_List_RowInsertedByTestCodeAfterOpen()
    var
        Card: TestPage "BNR Real List";
        Line: Record "BNR Line";
        R: Text;
    begin
        Initialize();
        Line.DeleteAll();
        Card.OpenView();
        R := 'before: ' + ObsReal(Card);
        Line.Init();
        Line."Header No." := 'R';
        Line."Line No." := 9;
        Line.QTxt := 'late';
        Line.QInt := 6;
        Line.Insert();
        R += ' | afterInsert: ' + ObsReal(Card);
        Card.First();
        R += ' | afterFirst: ' + ObsReal(Card);
        Error(R);
    end;
}
