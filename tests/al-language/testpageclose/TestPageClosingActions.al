// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-overview
// Scope: in-scope
// PROBE (record-only): every test ends in Error(<observations>) so a service tier's answers are readable
// from the run log. Written by agent stma-auto-7 for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#5400.

table 69650 "TPC Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Qty; Integer) { }
        field(3; Note; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 69650 "TPC Log"
{
    SingleInstance = true;

    var
        LogText: Text;
        VetoClose: Boolean;

    procedure Reset()
    begin
        LogText := '';
        VetoClose := false;
    end;

    procedure Add(Txt: Text)
    begin
        LogText += Txt + ';';
    end;

    procedure Text(): Text
    begin
        exit(LogText);
    end;

    procedure SetVeto(NewValue: Boolean)
    begin
        VetoClose := NewValue;
    end;

    procedure Veto(): Boolean
    begin
        exit(VetoClose);
    end;
}

page 69650 "TPC Card"
{
    PageType = Card;
    SourceTable = "TPC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            field(NoteCtl; Rec.Note) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Act)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    TPCLog.Add('act');
                end;
            }
        }
    }

    var
        TPCLog: Codeunit "TPC Log";

    trigger OnOpenPage()
    begin
        TPCLog.Add('open');
    end;

    trigger OnClosePage()
    begin
        TPCLog.Add('close');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        TPCLog.Add('qcp:' + Format(CloseAction));
        exit(not TPCLog.Veto());
    end;
}

page 69651 "TPC List"
{
    PageType = List;
    SourceTable = "TPC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
                field(NoteCtl; Rec.Note) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Act)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    TPCLog.Add('act');
                end;
            }
        }
    }

    var
        TPCLog: Codeunit "TPC Log";

    trigger OnOpenPage()
    begin
        TPCLog.Add('open');
    end;

    trigger OnClosePage()
    begin
        TPCLog.Add('close');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        TPCLog.Add('qcp:' + Format(CloseAction));
        exit(not TPCLog.Veto());
    end;
}

report 69650 "TPC Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "TPC Row")
        {
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(QtyOpt; QtyOption)
                {
                    ApplicationArea = All;
                }
            }
        }

        trigger OnOpenPage()
        begin
            TPCLog.Add('open');
        end;

        trigger OnClosePage()
        begin
            TPCLog.Add('close');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            TPCLog.Add('qcp:' + Format(CloseAction));
            exit(not TPCLog.Veto());
        end;
    }

    var
        QtyOption: Integer;
        TPCLog: Codeunit "TPC Log";
}

codeunit 69651 "TPC Closing Action Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TPCLog: Codeunit "TPC Log";
        Obs: Text;
        HandlerCloser: Text;
        HandlerOp: Text;

    local procedure Seed()
    var
        Row: Record "TPC Row";
    begin
        Row.DeleteAll();
        Row.Init(); Row."No." := 'A'; Row.Qty := 1; Row.Insert();
        Row.Init(); Row."No." := 'B'; Row.Qty := 2; Row.Insert();
        Row.Init(); Row."No." := 'C'; Row.Qty := 3; Row.Insert();
        Commit();
    end;

    local procedure Note(Label: Text; Value: Text)
    begin
        Obs += Label + '=' + Value + ' | ';
    end;

    local procedure NoteTry(Label: Text; Ok: Boolean; Res: Text)
    begin
        if Ok then
            Note(Label, 'ok:' + Res)
        else
            Note(Label, 'ERR:' + GetLastErrorText());
    end;

    local procedure TableState(): Text
    var
        Row: Record "TPC Row";
        Txt: Text;
    begin
        if Row.FindSet() then
            repeat
                Txt += Row."No." + ':' + Format(Row.Qty) + ':' + Row.Note + ',';
            until Row.Next() = 0;
        exit(Txt);
    end;

    // ---- Card ----

    [TryFunction]
    local procedure TryCardCloser(var P: TestPage "TPC Card"; Closer: Text; var Res: Text)
    begin
        case Closer of
            'ok': P.OK().Invoke();
            'cancel': P.Cancel().Invoke();
            'close': P.Close();
            'none': ;
        end;
        Res := 'done';
    end;

    [TryFunction]
    local procedure TryCardOp(var P: TestPage "TPC Card"; Op: Text; var Res: Text)
    var
        B: Boolean;
    begin
        case Op of
            'value': Res := P.NoCtl.Value();
            'asinteger': Res := Format(P.QtyCtl.AsInteger());
            'caption': Res := P.Caption();
            'editable': Res := Format(P.Editable());
            'fieldeditable': Res := Format(P.QtyCtl.Editable());
            'first': Res := Format(P.First());
            'last': Res := Format(P.Last());
            'next': Res := Format(P.Next());
            'prev': Res := Format(P.Previous());
            'gotokey': Res := Format(P.GoToKey('B'));
            'valerrcount': Res := Format(P.ValidationErrorCount());
            'setvalue': begin P.QtyCtl.SetValue(77); Res := 'set'; end;
            'assertequals': begin P.NoCtl.AssertEquals('A'); Res := 'equal'; end;
            'action': begin P.Act.Invoke(); Res := 'invoked'; end;
            'actionenabled': Res := Format(P.Act.Enabled());
            'close': begin P.Close(); Res := 'closed'; end;
            'ok': begin P.OK().Invoke(); Res := 'ok-invoked'; end;
            'cancel': begin P.Cancel().Invoke(); Res := 'cancel-invoked'; end;
            'reopenedit': begin P.OpenEdit(); Res := P.NoCtl.Value() + '/' + Format(P.QtyCtl.AsInteger()); end;
            'reopenview': begin P.OpenView(); Res := P.NoCtl.Value() + '/' + Format(P.QtyCtl.AsInteger()); end;
            'reopennew': begin P.OpenNew(); Res := '[' + P.NoCtl.Value() + ']'; end;
        end;
    end;

    local procedure ProbeCard(Closer: Text; Op: Text)
    var
        P: TestPage "TPC Card";
        CloserOk: Boolean;
        OpOk: Boolean;
        Res: Text;
    begin
        Seed();
        TPCLog.Reset();
        P.OpenEdit();
        CloserOk := TryCardCloser(P, Closer, Res);
        Note(Closer + '.closer', Res);
        if not CloserOk then
            Note(Closer + '.closer', 'ERR:' + GetLastErrorText());
        Note(Closer + '.log', TPCLog.Text());
        OpOk := TryCardOp(P, Op, Res);
        NoteTry(Closer + '>' + Op, OpOk, Res);
        Note(Closer + '>' + Op + '.log', TPCLog.Text());
    end;

    local procedure RunCard(Closer: Text)
    var
        Ops: List of [Text];
        Op: Text;
    begin
        Obs := '';
        foreach Op in CardOps() do
            ProbeCard(Closer, Op);
        Error(Obs);
    end;

    local procedure CardOps() Ops: List of [Text]
    begin
        Ops.Add('value');
        Ops.Add('asinteger');
        Ops.Add('caption');
        Ops.Add('editable');
        Ops.Add('fieldeditable');
        Ops.Add('first');
        Ops.Add('last');
        Ops.Add('next');
        Ops.Add('prev');
        Ops.Add('gotokey');
        Ops.Add('valerrcount');
        Ops.Add('setvalue');
        Ops.Add('assertequals');
        Ops.Add('action');
        Ops.Add('actionenabled');
        Ops.Add('close');
        Ops.Add('ok');
        Ops.Add('cancel');
        Ops.Add('reopenedit');
        Ops.Add('reopenview');
        Ops.Add('reopennew');

    end;

    [Test]
    procedure Probe_Card_AfterOK()
    begin
        RunCard('ok');
    end;

    [Test]
    procedure Probe_Card_AfterCancel()
    begin
        RunCard('cancel');
    end;

    [Test]
    procedure Probe_Card_AfterClose()
    begin
        RunCard('close');
    end;

    [Test]
    procedure Probe_Card_StillOpen()
    begin
        RunCard('none');
    end;

    local procedure WriteCard(Closer: Text)
    var
        P: TestPage "TPC Card";
        Ok: Boolean;
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        P.OpenEdit();
        P.QtyCtl.SetValue(5);
        Ok := TryCardCloser(P, Closer, Res);
        NoteTry('closer', Ok, Res);
        Note('table', TableState());
        Note('log', TPCLog.Text());
        Ok := TryCardOp(P, 'reopenedit', Res);
        NoteTry('reopen', Ok, Res);
        Error(Obs);
    end;

    local procedure NewRowCard(Closer: Text)
    var
        P: TestPage "TPC Card";
        Ok: Boolean;
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        P.OpenNew();
        P.NoCtl.SetValue('N1');
        P.QtyCtl.SetValue(9);
        Ok := TryCardCloser(P, Closer, Res);
        NoteTry('closer', Ok, Res);
        Note('table', TableState());
        Note('log', TPCLog.Text());
        Ok := TryCardOp(P, 'reopennew', Res);
        NoteTry('reopennew', Ok, Res);
        Ok := TryCardOp(P, 'value', Res);
        NoteTry('value', Ok, Res);
        Error(Obs);
    end;

    local procedure VetoCard(Closer: Text)
    var
        P: TestPage "TPC Card";
        Ok: Boolean;
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        TPCLog.SetVeto(true);
        P.OpenEdit();
        Ok := TryCardCloser(P, Closer, Res);
        NoteTry('vetoed.' + Closer, Ok, Res);
        Note('log', TPCLog.Text());
        Ok := TryCardOp(P, 'value', Res);
        NoteTry('value-after-veto', Ok, Res);
        Ok := TryCardOp(P, 'reopenedit', Res);
        NoteTry('reopen-after-veto', Ok, Res);
        TPCLog.SetVeto(false);
        Ok := TryCardCloser(P, Closer, Res);
        NoteTry('allowed.' + Closer, Ok, Res);
        Note('log2', TPCLog.Text());
        Ok := TryCardOp(P, 'value', Res);
        NoteTry('value-after-allowed', Ok, Res);
        Ok := TryCardOp(P, 'reopenedit', Res);
        NoteTry('reopen-after-allowed', Ok, Res);
        Error(Obs);
    end;

    local procedure TwoCard()
    var
        P1: TestPage "TPC Card";
        P2: TestPage "TPC Card";
        Ok: Boolean;
        Res: Text;
    begin
        Seed();
        Obs := '';
        P1.OpenEdit();
        P2.OpenEdit();
        Ok := TryCardCloser(P1, 'ok', Res);
        NoteTry('p1.ok', Ok, Res);
        Ok := TryCardOp(P2, 'value', Res);
        NoteTry('p2.value', Ok, Res);
        Ok := TryCardOp(P1, 'value', Res);
        NoteTry('p1.value', Ok, Res);
        Ok := TryCardOp(P1, 'reopenedit', Res);
        NoteTry('p1.reopen', Ok, Res);
        Ok := TryCardCloser(P2, 'ok', Res);
        NoteTry('p2.ok', Ok, Res);
        Ok := TryCardOp(P1, 'value', Res);
        NoteTry('p1.value2', Ok, Res);
        Ok := TryCardOp(P2, 'reopenedit', Res);
        NoteTry('p2.reopen', Ok, Res);
        Error(Obs);
    end;

    [Test]
    procedure Probe_Card_Write_OK()
    begin
        WriteCard('ok');
    end;

    [Test]
    procedure Probe_Card_Write_Cancel()
    begin
        WriteCard('cancel');
    end;

    [Test]
    procedure Probe_Card_Write_Close()
    begin
        WriteCard('close');
    end;

    [Test]
    procedure Probe_Card_Write_None()
    begin
        WriteCard('none');
    end;

    [Test]
    procedure Probe_Card_NewRow_OK()
    begin
        NewRowCard('ok');
    end;

    [Test]
    procedure Probe_Card_NewRow_Close()
    begin
        NewRowCard('close');
    end;

    [Test]
    procedure Probe_Card_Veto_OK()
    begin
        VetoCard('ok');
    end;

    [Test]
    procedure Probe_Card_Veto_Close()
    begin
        VetoCard('close');
    end;

    [Test]
    procedure Probe_Card_TwoVariables()
    begin
        TwoCard();
    end;

    // ---- List ----

    [TryFunction]
    local procedure TryListCloser(var P: TestPage "TPC List"; Closer: Text; var Res: Text)
    begin
        case Closer of
            'ok': P.OK().Invoke();
            'cancel': P.Cancel().Invoke();
            'close': P.Close();
            'none': ;
        end;
        Res := 'done';
    end;

    [TryFunction]
    local procedure TryListOp(var P: TestPage "TPC List"; Op: Text; var Res: Text)
    var
        B: Boolean;
    begin
        case Op of
            'value': Res := P.NoCtl.Value();
            'asinteger': Res := Format(P.QtyCtl.AsInteger());
            'caption': Res := P.Caption();
            'editable': Res := Format(P.Editable());
            'fieldeditable': Res := Format(P.QtyCtl.Editable());
            'first': Res := Format(P.First());
            'last': Res := Format(P.Last());
            'next': Res := Format(P.Next());
            'prev': Res := Format(P.Previous());
            'gotokey': Res := Format(P.GoToKey('B'));
            'valerrcount': Res := Format(P.ValidationErrorCount());
            'setvalue': begin P.QtyCtl.SetValue(77); Res := 'set'; end;
            'assertequals': begin P.NoCtl.AssertEquals('A'); Res := 'equal'; end;
            'action': begin P.Act.Invoke(); Res := 'invoked'; end;
            'actionenabled': Res := Format(P.Act.Enabled());
            'close': begin P.Close(); Res := 'closed'; end;
            'ok': begin P.OK().Invoke(); Res := 'ok-invoked'; end;
            'cancel': begin P.Cancel().Invoke(); Res := 'cancel-invoked'; end;
            'reopenedit': begin P.OpenEdit(); Res := P.NoCtl.Value() + '/' + Format(P.QtyCtl.AsInteger()); end;
            'reopenview': begin P.OpenView(); Res := P.NoCtl.Value() + '/' + Format(P.QtyCtl.AsInteger()); end;
            'reopennew': begin P.OpenNew(); Res := '[' + P.NoCtl.Value() + ']'; end;
            'new': begin P.New(); Res := 'new-row'; end;
        end;
    end;

    local procedure ProbeList(Closer: Text; Op: Text)
    var
        P: TestPage "TPC List";
        CloserOk: Boolean;
        OpOk: Boolean;
        Res: Text;
    begin
        Seed();
        TPCLog.Reset();
        P.OpenEdit();
        CloserOk := TryListCloser(P, Closer, Res);
        Note(Closer + '.closer', Res);
        if not CloserOk then
            Note(Closer + '.closer', 'ERR:' + GetLastErrorText());
        Note(Closer + '.log', TPCLog.Text());
        OpOk := TryListOp(P, Op, Res);
        NoteTry(Closer + '>' + Op, OpOk, Res);
        Note(Closer + '>' + Op + '.log', TPCLog.Text());
    end;

    local procedure RunList(Closer: Text)
    var
        Ops: List of [Text];
        Op: Text;
    begin
        Obs := '';
        foreach Op in ListOps() do
            ProbeList(Closer, Op);
        Error(Obs);
    end;

    local procedure ListOps() Ops: List of [Text]
    begin
        Ops.Add('value');
        Ops.Add('asinteger');
        Ops.Add('caption');
        Ops.Add('editable');
        Ops.Add('fieldeditable');
        Ops.Add('first');
        Ops.Add('last');
        Ops.Add('next');
        Ops.Add('prev');
        Ops.Add('gotokey');
        Ops.Add('valerrcount');
        Ops.Add('setvalue');
        Ops.Add('assertequals');
        Ops.Add('action');
        Ops.Add('actionenabled');
        Ops.Add('close');
        Ops.Add('ok');
        Ops.Add('cancel');
        Ops.Add('reopenedit');
        Ops.Add('reopenview');
        Ops.Add('reopennew');
Ops.Add('new');
    end;

    [Test]
    procedure Probe_List_AfterOK()
    begin
        RunList('ok');
    end;

    [Test]
    procedure Probe_List_AfterCancel()
    begin
        RunList('cancel');
    end;

    [Test]
    procedure Probe_List_AfterClose()
    begin
        RunList('close');
    end;

    [Test]
    procedure Probe_List_StillOpen()
    begin
        RunList('none');
    end;

    local procedure WriteList(Closer: Text)
    var
        P: TestPage "TPC List";
        Ok: Boolean;
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        P.OpenEdit();
        P.QtyCtl.SetValue(5);
        Ok := TryListCloser(P, Closer, Res);
        NoteTry('closer', Ok, Res);
        Note('table', TableState());
        Note('log', TPCLog.Text());
        Ok := TryListOp(P, 'reopenedit', Res);
        NoteTry('reopen', Ok, Res);
        Error(Obs);
    end;

    local procedure NewRowList(Closer: Text)
    var
        P: TestPage "TPC List";
        Ok: Boolean;
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        P.OpenNew();
        P.NoCtl.SetValue('N1');
        P.QtyCtl.SetValue(9);
        Ok := TryListCloser(P, Closer, Res);
        NoteTry('closer', Ok, Res);
        Note('table', TableState());
        Note('log', TPCLog.Text());
        Ok := TryListOp(P, 'reopennew', Res);
        NoteTry('reopennew', Ok, Res);
        Ok := TryListOp(P, 'value', Res);
        NoteTry('value', Ok, Res);
        Error(Obs);
    end;

    local procedure VetoList(Closer: Text)
    var
        P: TestPage "TPC List";
        Ok: Boolean;
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        TPCLog.SetVeto(true);
        P.OpenEdit();
        Ok := TryListCloser(P, Closer, Res);
        NoteTry('vetoed.' + Closer, Ok, Res);
        Note('log', TPCLog.Text());
        Ok := TryListOp(P, 'value', Res);
        NoteTry('value-after-veto', Ok, Res);
        Ok := TryListOp(P, 'reopenedit', Res);
        NoteTry('reopen-after-veto', Ok, Res);
        TPCLog.SetVeto(false);
        Ok := TryListCloser(P, Closer, Res);
        NoteTry('allowed.' + Closer, Ok, Res);
        Note('log2', TPCLog.Text());
        Ok := TryListOp(P, 'value', Res);
        NoteTry('value-after-allowed', Ok, Res);
        Ok := TryListOp(P, 'reopenedit', Res);
        NoteTry('reopen-after-allowed', Ok, Res);
        Error(Obs);
    end;

    local procedure TwoList()
    var
        P1: TestPage "TPC List";
        P2: TestPage "TPC List";
        Ok: Boolean;
        Res: Text;
    begin
        Seed();
        Obs := '';
        P1.OpenEdit();
        P2.OpenEdit();
        Ok := TryListCloser(P1, 'ok', Res);
        NoteTry('p1.ok', Ok, Res);
        Ok := TryListOp(P2, 'value', Res);
        NoteTry('p2.value', Ok, Res);
        Ok := TryListOp(P1, 'value', Res);
        NoteTry('p1.value', Ok, Res);
        Ok := TryListOp(P1, 'reopenedit', Res);
        NoteTry('p1.reopen', Ok, Res);
        Ok := TryListCloser(P2, 'ok', Res);
        NoteTry('p2.ok', Ok, Res);
        Ok := TryListOp(P1, 'value', Res);
        NoteTry('p1.value2', Ok, Res);
        Ok := TryListOp(P2, 'reopenedit', Res);
        NoteTry('p2.reopen', Ok, Res);
        Error(Obs);
    end;

    [Test]
    procedure Probe_List_Write_OK()
    begin
        WriteList('ok');
    end;

    [Test]
    procedure Probe_List_Write_Cancel()
    begin
        WriteList('cancel');
    end;

    [Test]
    procedure Probe_List_Write_Close()
    begin
        WriteList('close');
    end;

    [Test]
    procedure Probe_List_Write_None()
    begin
        WriteList('none');
    end;

    [Test]
    procedure Probe_List_NewRow_OK()
    begin
        NewRowList('ok');
    end;

    [Test]
    procedure Probe_List_NewRow_Close()
    begin
        NewRowList('close');
    end;

    [Test]
    procedure Probe_List_Veto_OK()
    begin
        VetoList('ok');
    end;

    [Test]
    procedure Probe_List_Veto_Close()
    begin
        VetoList('close');
    end;

    [Test]
    procedure Probe_List_TwoVariables()
    begin
        TwoList();
    end;

    // ---- pages handed to a handler ----

    [ModalPageHandler]
    procedure CardHandler(var P: TestPage "TPC Card")
    var
        Ok: Boolean;
        Res: Text;
    begin
        Ok := TryCardCloser(P, HandlerCloser, Res);
        NoteTry('closer', Ok, Res);
        Note('log', TPCLog.Text());
        Ok := TryCardOp(P, HandlerOp, Res);
        NoteTry(HandlerCloser + '>' + HandlerOp, Ok, Res);
    end;

    [ModalPageHandler]
    procedure ListHandler(var P: TestPage "TPC List")
    var
        Ok: Boolean;
        Res: Text;
    begin
        Ok := TryListCloser(P, HandlerCloser, Res);
        NoteTry('closer', Ok, Res);
        Note('log', TPCLog.Text());
        Ok := TryListOp(P, HandlerOp, Res);
        NoteTry(HandlerCloser + '>' + HandlerOp, Ok, Res);
    end;

    local procedure RunHandlerCard(Closer: Text)
    var
        Row: Record "TPC Row";
        Result: Action;
        Op: Text;
    begin
        Obs := '';
        foreach Op in CardOps() do begin
            Seed();
            TPCLog.Reset();
            HandlerCloser := Closer;
            HandlerOp := Op;
            Row.FindFirst();
            Result := Page.RunModal(Page::"TPC Card", Row);
            Note(Closer + '>' + Op + '.result', Format(Result));
            Note('log-end', TPCLog.Text());
        end;
        Error(Obs);
    end;

    local procedure RunHandlerList(Closer: Text; Lookup: Boolean)
    var
        ListPage: Page "TPC List";
        Result: Action;
        Op: Text;
    begin
        Obs := '';
        foreach Op in ListOps() do begin
            Seed();
            TPCLog.Reset();
            HandlerCloser := Closer;
            HandlerOp := Op;
            Clear(ListPage);
            ListPage.LookupMode(Lookup);
            Result := ListPage.RunModal();
            Note(Closer + '>' + Op + '.result', Format(Result));
            Note('log-end', TPCLog.Text());
        end;
        Error(Obs);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_AfterOK()
    begin
        RunHandlerCard('ok');
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_AfterCancel()
    begin
        RunHandlerCard('cancel');
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_AfterClose()
    begin
        RunHandlerCard('close');
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_AfterOK()
    begin
        RunHandlerList('ok', false);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_AfterCancel()
    begin
        RunHandlerList('cancel', false);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerLookup_AfterOK()
    begin
        RunHandlerList('ok', true);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerLookup_AfterCancel()
    begin
        RunHandlerList('cancel', true);
    end;

    // ---- a request page ----

    [TryFunction]
    local procedure TryReqCloser(var R: TestRequestPage "TPC Report"; Closer: Text; var Res: Text)
    begin
        case Closer of
            'ok': R.OK().Invoke();
            'cancel': R.Cancel().Invoke();
        end;
        Res := 'done';
    end;

    [TryFunction]
    local procedure TryReqOp(var R: TestRequestPage "TPC Report"; Op: Text; var Res: Text)
    begin
        case Op of
            'value': Res := R.QtyOpt.Value();
            'setvalue': begin R.QtyOpt.SetValue(5); Res := 'set'; end;
            'ok': begin R.OK().Invoke(); Res := 'ok-invoked'; end;
            'cancel': begin R.Cancel().Invoke(); Res := 'cancel-invoked'; end;
            'caption': Res := R.Caption();
        end;
    end;

    [RequestPageHandler]
    procedure ReqHandler(var R: TestRequestPage "TPC Report")
    var
        Ok: Boolean;
        Res: Text;
    begin
        Ok := TryReqCloser(R, HandlerCloser, Res);
        NoteTry('closer', Ok, Res);
        Note('log', TPCLog.Text());
        Ok := TryReqOp(R, HandlerOp, Res);
        NoteTry(HandlerCloser + '>' + HandlerOp, Ok, Res);
    end;

    local procedure RunRequest(Closer: Text)
    var
        Op: Text;
        Params: Text;
    begin
        Obs := '';
        foreach Op in ReqOps() do begin
            TPCLog.Reset();
            HandlerCloser := Closer;
            HandlerOp := Op;
            Params := Report.RunRequestPage(Report::"TPC Report");
            Note(Closer + '>' + Op + '.params', Format(StrLen(Params) > 0));
            Note('log-end', TPCLog.Text());
        end;
        Error(Obs);
    end;

    local procedure ReqOps() Ops: List of [Text]
    begin
        Ops.Add('value');
        Ops.Add('setvalue');
        Ops.Add('ok');
        Ops.Add('cancel');
        Ops.Add('caption');
    end;

    [Test]
    [HandlerFunctions('ReqHandler')]
    procedure Probe_Request_AfterOK()
    begin
        RunRequest('ok');
    end;

    [Test]
    [HandlerFunctions('ReqHandler')]
    procedure Probe_Request_AfterCancel()
    begin
        RunRequest('cancel');
    end;
}
