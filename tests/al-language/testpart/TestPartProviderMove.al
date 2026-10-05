// PROBE (draft): records what a Provider-linked part reads after its Provider moves, without the
// part being moved itself. Each test ends in Error(<observations>) so one run prints every reading.
codeunit 69143 "PVD Provider Move Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Header: Record "PVD Header";
        Line: Record "PVD Line";
        Detail: Record "PVD Detail";
    begin
        Detail.DeleteAll();
        Line.DeleteAll();
        Header.DeleteAll();

        Header.Init();
        Header."No." := 'H1';
        Header."Line No." := 1;
        Header.Insert();
        Header.Init();
        Header."No." := 'H2';
        Header."Line No." := 1;
        Header.Insert();

        InsertLine('H1', 10);
        InsertLine('H1', 20);
        InsertDetail(1, 10, 'ten');
        InsertDetail(2, 20, 'twenty');
        InsertDetail(3, 1, 'decoy');
    end;

    local procedure InsertLine(HeaderNo: Code[20]; LineNo: Integer)
    var
        Line: Record "PVD Line";
    begin
        Line.Init();
        Line."Header No." := HeaderNo;
        Line."Line No." := LineNo;
        Line.Insert();
    end;

    local procedure InsertDetail(EntryNo: Integer; LineRef: Integer; Info: Text[30])
    var
        Detail: Record "PVD Detail";
    begin
        Detail.Init();
        Detail."Entry No." := EntryNo;
        Detail."Line Ref" := LineRef;
        Detail.Info := Info;
        Detail.Insert();
    end;

    // A TryFunction, not asserterror: an error caught by asserterror rolls the test's writes back.
    [TryFunction]
    local procedure TryReadInfo(var Card: TestPage "PVD Header Card"; var Result: Text)
    begin
        Result := Card.Detail.Info.Value;
    end;

    [TryFunction]
    local procedure TryReadLineNo(var Card: TestPage "PVD Header Card"; var Result: Text)
    begin
        Result := Card.Lines.LineNo.Value;
    end;

    [TryFunction]
    local procedure TryFirstThenRead(var Card: TestPage "PVD Header Card"; var Result: Text)
    var
        Found: Boolean;
    begin
        Found := Card.Detail.First();
        Result := StrSubstNo('first=%1 v=%2', Found, Card.Detail.Info.Value);
    end;

    local procedure ReadInfo(var Card: TestPage "PVD Header Card"): Text
    var
        Result: Text;
    begin
        if TryReadInfo(Card, Result) then
            exit('[' + Result + ']');
        exit('[ERR ' + GetLastErrorText + ']');
    end;

    local procedure ReadLineNo(var Card: TestPage "PVD Header Card"): Text
    var
        Result: Text;
    begin
        if TryReadLineNo(Card, Result) then
            exit('[' + Result + ']');
        exit('[ERR ' + GetLastErrorText + ']');
    end;

    local procedure ReadDetailAfterFirst(var Card: TestPage "PVD Header Card"): Text
    var
        Result: Text;
    begin
        if TryFirstThenRead(Card, Result) then
            exit('[' + Result + ']');
        exit('[ERR ' + GetLastErrorText + ']');
    end;

    [Test]
    procedure Probe_ProviderMoves_DependentNotMoved()
    var
        Card: TestPage "PVD Header Card";
        Obs: Text;
    begin
        Initialize();
        Card.OpenView();
        Card.GoToKey('H1');
        Obs += 'A0 detail=' + ReadInfo(Card) + ' lines=' + ReadLineNo(Card);
        Card.Lines.First();
        Obs += ' | A1 afterLinesFirst detail=' + ReadInfo(Card) + ' lines=' + ReadLineNo(Card);
        Card.Lines.Next();
        Obs += ' | A2 afterLinesNext detail=' + ReadInfo(Card) + ' lines=' + ReadLineNo(Card);
        Obs += ' | A3 detailFirst=' + ReadDetailAfterFirst(Card);
        Card.Lines.Previous();
        Obs += ' | A4 afterLinesPrevious detail=' + ReadInfo(Card) + ' lines=' + ReadLineNo(Card);
        Obs += ' | A5 detailFirst=' + ReadDetailAfterFirst(Card);
        Error(Obs);
    end;

    [Test]
    procedure Probe_ProviderNextWithoutFirst_DependentNotMoved()
    var
        Card: TestPage "PVD Header Card";
        Obs: Text;
    begin
        Initialize();
        Card.OpenView();
        Card.GoToKey('H1');
        Obs += 'B0 detail=' + ReadInfo(Card) + ' lines=' + ReadLineNo(Card);
        Card.Lines.Next();
        Obs += ' | B1 afterLinesNext detail=' + ReadInfo(Card) + ' lines=' + ReadLineNo(Card);
        Error(Obs);
    end;

    [Test]
    procedure Probe_HostMovesToEmptyProvider_DependentNotMoved()
    var
        Card: TestPage "PVD Header Card";
        Obs: Text;
    begin
        Initialize();
        Card.OpenView();
        Card.GoToKey('H1');
        Obs += 'C0 detail=' + ReadInfo(Card) + ' lines=' + ReadLineNo(Card);
        Card.GoToKey('H2');
        Obs += ' | C1 afterHostH2 detail=' + ReadInfo(Card) + ' lines=' + ReadLineNo(Card);
        Obs += ' | C2 detailFirst=' + ReadDetailAfterFirst(Card);
        Obs += ' | C3 detail=' + ReadInfo(Card);
        Card.GoToKey('H1');
        Obs += ' | C4 backToH1 detail=' + ReadInfo(Card) + ' lines=' + ReadLineNo(Card);
        Error(Obs);
    end;

    [Test]
    procedure Probe_NoProviderPart_ContrastOnHostMove()
    var
        Card: TestPage "PVD Header Card";
        Obs: Text;
    begin
        Initialize();
        Card.OpenView();
        Card.GoToKey('H1');
        Obs += 'D0 lines=' + ReadLineNo(Card);
        Card.GoToKey('H2');
        Obs += ' | D1 afterHostH2 lines=' + ReadLineNo(Card);
        Card.GoToKey('H1');
        Obs += ' | D2 backToH1 lines=' + ReadLineNo(Card);
        Error(Obs);
    end;

    [Test]
    procedure Probe_ReadBeforeAnyNavigation()
    var
        Card: TestPage "PVD Header Card";
        Obs: Text;
    begin
        Initialize();
        Card.OpenView();
        Obs += 'E0 afterOpen detail=' + ReadInfo(Card) + ' lines=' + ReadLineNo(Card);
        Error(Obs);
    end;
}
