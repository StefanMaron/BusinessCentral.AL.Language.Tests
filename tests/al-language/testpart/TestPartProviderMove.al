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

        Header.Init();
        Header."No." := 'H3';
        Header."Line No." := 1;
        Header.Insert();
        Header.Init();
        Header."No." := 'H4';
        Header."Line No." := 1;
        Header.Insert();

        InsertLine('H1', 10);
        InsertLine('H1', 20);
        InsertLine('H3', 30);
        InsertLine('H3', 40);
        InsertLine('H3', 50);
        InsertLine('H4', 60);
        InsertDetail(1, 10, 'ten');
        InsertDetail(2, 20, 'twenty');
        InsertDetail(3, 1, 'decoy');
        InsertDetail(4, 30, 'thirty');
        InsertDetail(5, 40, 'forty');
        InsertDetail(6, 50, 'fifty');
        InsertDetail(7, 60, 'sixty');
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

    // d = what the dependent part's Info reads, l = what the Provider's LineNo reads, f = First().
    local procedure R(var Card: TestPage "PVD Header Card"): Text
    begin
        exit(' d=' + ReadInfo(Card) + ' l=' + ReadLineNo(Card));
    end;

    local procedure Open(var Card: TestPage "PVD Header Card")
    begin
        Initialize();
        Card.OpenView();
    end;

    [Test]
    procedure Probe_A_ProviderFirstNextPrevious()
    var
        Card: TestPage "PVD Header Card";
        Obs: Text;
    begin
        Open(Card);
        Card.GoToKey('H1');
        Obs += 'A0' + R(Card);
        Card.Lines.First();
        Obs += ' |A1' + R(Card);
        Card.Lines.Next();
        Obs += ' |A2' + R(Card);
        Card.Lines.Previous();
        Obs += ' |A3' + R(Card);
        Error(Obs);
    end;

    [Test]
    procedure Probe_B_ProviderNextWithoutFirst()
    var
        Card: TestPage "PVD Header Card";
        Obs: Text;
    begin
        Open(Card);
        Card.GoToKey('H1');
        Obs += 'B0' + R(Card);
        Card.Lines.Next();
        Obs += ' |B1' + R(Card);
        Card.Lines.Next();
        Obs += ' |B2' + R(Card);
        Card.Lines.Last();
        Obs += ' |B3' + R(Card);
        Error(Obs);
    end;

    [Test]
    procedure Probe_C_DependentFirstAndNextAfterProviderMove()
    var
        Card: TestPage "PVD Header Card";
        Obs: Text;
    begin
        Open(Card);
        Card.GoToKey('H3');
        Card.Lines.First();
        Obs += 'C0' + R(Card);
        Card.Lines.Next();
        Obs += ' |C1' + R(Card);
        Obs += ' |C2 detNext=' + Format(Card.Detail.Next()) + R(Card);
        Obs += ' |C3 detFirst=' + Format(Card.Detail.First()) + R(Card);
        Error(Obs);
    end;

    [Test]
    procedure Probe_D_HostMovesToEmptyProvider()
    var
        Card: TestPage "PVD Header Card";
        Obs: Text;
    begin
        Open(Card);
        Card.GoToKey('H1');
        Obs += 'D0' + R(Card);
        Card.GoToKey('H2');
        Obs += ' |D1' + R(Card);
        Obs += ' |D2 detFirst=' + Format(Card.Detail.First()) + R(Card);
        Obs += ' |D3 linesFirst=' + Format(Card.Lines.First()) + R(Card);
        Error(Obs);
    end;

    [Test]
    procedure Probe_E_HostBackFromEmptyProvider()
    var
        Card: TestPage "PVD Header Card";
        Obs: Text;
    begin
        Open(Card);
        Card.GoToKey('H1');
        Card.GoToKey('H2');
        Card.GoToKey('H1');
        Obs += 'E0' + R(Card);
        Card.Lines.First();
        Obs += ' |E1' + R(Card);
        Error(Obs);
    end;

    [Test]
    procedure Probe_F_HostMovesBetweenNonEmptyProviders()
    var
        Card: TestPage "PVD Header Card";
        Obs: Text;
    begin
        Open(Card);
        Card.GoToKey('H1');
        Obs += 'F0' + R(Card);
        Card.GoToKey('H3');
        Obs += ' |F1' + R(Card);
        Card.GoToKey('H4');
        Obs += ' |F2' + R(Card);
        Card.GoToKey('H1');
        Obs += ' |F3' + R(Card);
        Error(Obs);
    end;

    [Test]
    procedure Probe_G_HostMovesAfterProviderStoodOnSecondRow()
    var
        Card: TestPage "PVD Header Card";
        Obs: Text;
    begin
        Open(Card);
        Card.GoToKey('H3');
        Card.Lines.First();
        Card.Lines.Next();
        Obs += 'G0' + R(Card);
        Card.GoToKey('H1');
        Obs += ' |G1' + R(Card);
        Card.GoToKey('H3');
        Obs += ' |G2' + R(Card);
        Error(Obs);
    end;

    [Test]
    procedure Probe_H_ReadBeforeAnyNavigation()
    var
        Card: TestPage "PVD Header Card";
        Obs: Text;
    begin
        Open(Card);
        Obs += 'H0' + R(Card);
        Error(Obs);
    end;

    [Test]
    procedure Probe_I_HostMovesToEmptyThenToNonEmpty()
    var
        Card: TestPage "PVD Header Card";
        Obs: Text;
    begin
        Open(Card);
        Card.GoToKey('H2');
        Obs += 'I0' + R(Card);
        Card.GoToKey('H3');
        Obs += ' |I1' + R(Card);
        Card.GoToKey('H2');
        Obs += ' |I2' + R(Card);
        Card.GoToKey('H4');
        Obs += ' |I3' + R(Card);
        Error(Obs);
    end;
}
