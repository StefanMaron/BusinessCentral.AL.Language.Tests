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

    trigger OnInsert()
    begin
        if Note = 'FAIL' then
            Error('TPC insert refused');
    end;

    trigger OnModify()
    begin
        if Note = 'FAIL' then
            Error('TPC modify refused');
    end;
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
        LogText += Txt + ',';
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
    DelayedInsert = true;
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
    DelayedInsert = true;
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

page 69652 "TPC Dialog"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; NoVar) { ApplicationArea = All; }
            field(QtyCtl; QtyVar) { ApplicationArea = All; }
            field(NoteCtl; NoteVar) { ApplicationArea = All; }
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
        NoVar: Code[20];
        QtyVar: Integer;
        NoteVar: Text[50];
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

page 69653 "TPC Saved Dialog"
{
    PageType = StandardDialog;
    SaveValues = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Remembered; RememberedVar) { ApplicationArea = All; }
        }
    }

    var
        RememberedVar: Text[50];
}

page 69654 "TPC Saved Card"
{
    PageType = Card;
    SaveValues = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Remembered; RememberedVar) { ApplicationArea = All; }
        }
    }

    var
        RememberedVar: Text[50];
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

    local procedure Short(Txt: Text): Text
    begin
        if StrPos(Txt, 'The TestPage is not open') > 0 then
            exit('NOTOPEN');
        if StrPos(Txt, 'The TestPage is already open') > 0 then
            exit('ALREADYOPEN');
        if StrPos(Txt, 'is not found on the page') > 0 then
            exit('NOTFOUND');
        exit(Txt);
    end;

    local procedure Note(Label: Text; Value: Text)
    begin
        Obs += Label + '=' + Value + ' | ';
    end;

    local procedure NoteTry(Label: Text; Ok: Boolean; Res: Text)
    begin
        if Ok then
            Note(Label, Res)
        else
            Note(Label, 'ERR:' + Short(GetLastErrorText()));
    end;

    local procedure TableState(): Text
    var
        Row: Record "TPC Row";
        Txt: Text;
    begin
        if Row.FindSet() then
            repeat
                Txt += Row."No." + ':' + Format(Row.Qty) + ',';
            until Row.Next() = 0;
        exit(Txt);
    end;

    local procedure AllOps() Ops: List of [Text]
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

    local procedure OpsChunk(Chunk: Integer; Size: Integer) Ops: List of [Text]
    var
        Every: List of [Text];
        I: Integer;
    begin
        Every := AllOps();
        for I := 1 to Every.Count() do
            if ((I - 1) div Size) = Chunk then
                Ops.Add(Every.Get(I));
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
        Res: Text;
        AfterCloser: Text;
    begin
        Seed();
        TPCLog.Reset();
        P.OpenEdit();
        NoteTry(Closer + '.closer', TryCardCloser(P, Closer, Res), Res);
        AfterCloser := TPCLog.Text();
        if Op = AllOps().Get(1) then
            Note(Closer + '.log', AfterCloser);
        NoteTry(Op, TryCardOp(P, Op, Res), Res);
        if TPCLog.Text() <> AfterCloser then
            Note(Op + '.log', TPCLog.Text());
    end;

    local procedure RunCard(Closer: Text; Chunk: Integer)
    var
        Op: Text;
    begin
        Obs := '';
        foreach Op in OpsChunk(Chunk, 8) do
            ProbeCard(Closer, Op);
        Error(Obs);
    end;

    [Test]
    procedure Probe_Card_Ok_0()
    begin
        RunCard('ok', 0);
    end;

    [Test]
    procedure Probe_Card_Ok_1()
    begin
        RunCard('ok', 1);
    end;

    [Test]
    procedure Probe_Card_Ok_2()
    begin
        RunCard('ok', 2);
    end;

    [Test]
    procedure Probe_Card_Cancel_0()
    begin
        RunCard('cancel', 0);
    end;

    [Test]
    procedure Probe_Card_Cancel_1()
    begin
        RunCard('cancel', 1);
    end;

    [Test]
    procedure Probe_Card_Cancel_2()
    begin
        RunCard('cancel', 2);
    end;

    [Test]
    procedure Probe_Card_Close_0()
    begin
        RunCard('close', 0);
    end;

    [Test]
    procedure Probe_Card_Close_1()
    begin
        RunCard('close', 1);
    end;

    [Test]
    procedure Probe_Card_Close_2()
    begin
        RunCard('close', 2);
    end;

    [Test]
    procedure Probe_Card_None_0()
    begin
        RunCard('none', 0);
    end;

    [Test]
    procedure Probe_Card_None_1()
    begin
        RunCard('none', 1);
    end;

    [Test]
    procedure Probe_Card_None_2()
    begin
        RunCard('none', 2);
    end;

    local procedure WriteCard(Closer: Text)
    var
        P: TestPage "TPC Card";
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        P.OpenEdit();
        P.QtyCtl.SetValue(5);
        NoteTry('closer', TryCardCloser(P, Closer, Res), Res);
        Note('table', TableState());
        Note('log', TPCLog.Text());
        NoteTry('reopen', TryCardOp(P, 'reopenedit', Res), Res);
        Error(Obs);
    end;

    local procedure NewRowCard(Closer: Text)
    var
        P: TestPage "TPC Card";
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        P.OpenNew();
        P.NoCtl.SetValue('N1');
        P.QtyCtl.SetValue(9);
        NoteTry('closer', TryCardCloser(P, Closer, Res), Res);
        Note('table', TableState());
        Note('log', TPCLog.Text());
        NoteTry('reopennew', TryCardOp(P, 'reopennew', Res), Res);
        NoteTry('value', TryCardOp(P, 'value', Res), Res);
        Error(Obs);
    end;

    local procedure VetoCard(Closer: Text)
    var
        P: TestPage "TPC Card";
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        TPCLog.SetVeto(true);
        P.OpenEdit();
        NoteTry('vetoed.' + Closer, TryCardCloser(P, Closer, Res), Res);
        Note('log', TPCLog.Text());
        NoteTry('value-after-veto', TryCardOp(P, 'value', Res), Res);
        NoteTry('reopen-after-veto', TryCardOp(P, 'reopenedit', Res), Res);
        TPCLog.SetVeto(false);
        NoteTry('allowed.' + Closer, TryCardCloser(P, Closer, Res), Res);
        Note('log2', TPCLog.Text());
        NoteTry('value-after-allowed', TryCardOp(P, 'value', Res), Res);
        NoteTry('reopen-after-allowed', TryCardOp(P, 'reopenedit', Res), Res);
        Error(Obs);
    end;

    local procedure TwoCard()
    var
        P1: TestPage "TPC Card";
        P2: TestPage "TPC Card";
        Res: Text;
    begin
        Seed();
        Obs := '';
        P1.OpenEdit();
        P2.OpenEdit();
        NoteTry('p1.ok', TryCardCloser(P1, 'ok', Res), Res);
        NoteTry('p2.value', TryCardOp(P2, 'value', Res), Res);
        NoteTry('p1.value', TryCardOp(P1, 'value', Res), Res);
        NoteTry('p1.reopen', TryCardOp(P1, 'reopenedit', Res), Res);
        NoteTry('p2.ok', TryCardCloser(P2, 'ok', Res), Res);
        NoteTry('p1.value2', TryCardOp(P1, 'value', Res), Res);
        NoteTry('p2.reopen', TryCardOp(P2, 'reopenedit', Res), Res);
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
    procedure Probe_Card_NewRow_OK()
    begin
        NewRowCard('ok');
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
    procedure Probe_Card_Two()
    begin
        TwoCard();
    end;

    [TryFunction]
    local procedure TrySetupCard(var P: TestPage "TPC Card"; Mode: Text)
    begin
        case Mode of
            'dup':
                begin
                    P.OpenNew();
                    P.NoCtl.SetValue('A');
                    P.QtyCtl.SetValue(9);
                end;
            'insert':
                begin
                    P.OpenNew();
                    P.NoCtl.SetValue('N2');
                    P.NoteCtl.SetValue('FAIL');
                end;
            'modify':
                begin
                    P.OpenEdit();
                    P.NoteCtl.SetValue('FAIL');
                end;
        end;
    end;

    local procedure RefuseCard(Mode: Text; Closer: Text)
    var
        P: TestPage "TPC Card";
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        NoteTry('setup', TrySetupCard(P, Mode), 'done');
        NoteTry(Closer + '.closer', TryCardCloser(P, Closer, Res), Res);
        NoteTry('valerr', TryCardOp(P, 'valerrcount', Res), Res);
        NoteTry('value', TryCardOp(P, 'value', Res), Res);
        Note('log', TPCLog.Text());
        Note('table', TableState());
        NoteTry('reopen1', TryCardOp(P, 'reopenedit', Res), Res);
        NoteTry('close', TryCardOp(P, 'close', Res), Res);
        NoteTry('reopen2', TryCardOp(P, 'reopenedit', Res), Res);
        Note('table2', TableState());
        Note('log2', TPCLog.Text());
        Error(Obs);
    end;

    [Test]
    procedure Probe_Card_RefuseDup_Ok()
    begin
        RefuseCard('dup', 'ok');
    end;

    [Test]
    procedure Probe_Card_RefuseDup_Close()
    begin
        RefuseCard('dup', 'close');
    end;

    [Test]
    procedure Probe_Card_RefuseInsert_Ok()
    begin
        RefuseCard('insert', 'ok');
    end;

    [Test]
    procedure Probe_Card_RefuseInsert_Close()
    begin
        RefuseCard('insert', 'close');
    end;

    [Test]
    procedure Probe_Card_RefuseModify_Ok()
    begin
        RefuseCard('modify', 'ok');
    end;

    [Test]
    procedure Probe_Card_RefuseModify_Close()
    begin
        RefuseCard('modify', 'close');
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
        Res: Text;
        AfterCloser: Text;
    begin
        Seed();
        TPCLog.Reset();
        P.OpenEdit();
        NoteTry(Closer + '.closer', TryListCloser(P, Closer, Res), Res);
        AfterCloser := TPCLog.Text();
        if Op = AllOps().Get(1) then
            Note(Closer + '.log', AfterCloser);
        NoteTry(Op, TryListOp(P, Op, Res), Res);
        if TPCLog.Text() <> AfterCloser then
            Note(Op + '.log', TPCLog.Text());
    end;

    local procedure RunList(Closer: Text; Chunk: Integer)
    var
        Op: Text;
    begin
        Obs := '';
        foreach Op in OpsChunk(Chunk, 8) do
            ProbeList(Closer, Op);
        Error(Obs);
    end;

    [Test]
    procedure Probe_List_Ok_0()
    begin
        RunList('ok', 0);
    end;

    [Test]
    procedure Probe_List_Ok_1()
    begin
        RunList('ok', 1);
    end;

    [Test]
    procedure Probe_List_Ok_2()
    begin
        RunList('ok', 2);
    end;

    [Test]
    procedure Probe_List_Cancel_0()
    begin
        RunList('cancel', 0);
    end;

    [Test]
    procedure Probe_List_Cancel_1()
    begin
        RunList('cancel', 1);
    end;

    [Test]
    procedure Probe_List_Cancel_2()
    begin
        RunList('cancel', 2);
    end;

    [Test]
    procedure Probe_List_Close_0()
    begin
        RunList('close', 0);
    end;

    [Test]
    procedure Probe_List_Close_1()
    begin
        RunList('close', 1);
    end;

    [Test]
    procedure Probe_List_Close_2()
    begin
        RunList('close', 2);
    end;

    [Test]
    procedure Probe_List_None_0()
    begin
        RunList('none', 0);
    end;

    [Test]
    procedure Probe_List_None_1()
    begin
        RunList('none', 1);
    end;

    [Test]
    procedure Probe_List_None_2()
    begin
        RunList('none', 2);
    end;

    local procedure WriteList(Closer: Text)
    var
        P: TestPage "TPC List";
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        P.OpenEdit();
        P.QtyCtl.SetValue(5);
        NoteTry('closer', TryListCloser(P, Closer, Res), Res);
        Note('table', TableState());
        Note('log', TPCLog.Text());
        NoteTry('reopen', TryListOp(P, 'reopenedit', Res), Res);
        Error(Obs);
    end;

    local procedure NewRowList(Closer: Text)
    var
        P: TestPage "TPC List";
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        P.OpenNew();
        P.NoCtl.SetValue('N1');
        P.QtyCtl.SetValue(9);
        NoteTry('closer', TryListCloser(P, Closer, Res), Res);
        Note('table', TableState());
        Note('log', TPCLog.Text());
        NoteTry('reopennew', TryListOp(P, 'reopennew', Res), Res);
        NoteTry('value', TryListOp(P, 'value', Res), Res);
        Error(Obs);
    end;

    local procedure VetoList(Closer: Text)
    var
        P: TestPage "TPC List";
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        TPCLog.SetVeto(true);
        P.OpenEdit();
        NoteTry('vetoed.' + Closer, TryListCloser(P, Closer, Res), Res);
        Note('log', TPCLog.Text());
        NoteTry('value-after-veto', TryListOp(P, 'value', Res), Res);
        NoteTry('reopen-after-veto', TryListOp(P, 'reopenedit', Res), Res);
        TPCLog.SetVeto(false);
        NoteTry('allowed.' + Closer, TryListCloser(P, Closer, Res), Res);
        Note('log2', TPCLog.Text());
        NoteTry('value-after-allowed', TryListOp(P, 'value', Res), Res);
        NoteTry('reopen-after-allowed', TryListOp(P, 'reopenedit', Res), Res);
        Error(Obs);
    end;

    local procedure TwoList()
    var
        P1: TestPage "TPC List";
        P2: TestPage "TPC List";
        Res: Text;
    begin
        Seed();
        Obs := '';
        P1.OpenEdit();
        P2.OpenEdit();
        NoteTry('p1.ok', TryListCloser(P1, 'ok', Res), Res);
        NoteTry('p2.value', TryListOp(P2, 'value', Res), Res);
        NoteTry('p1.value', TryListOp(P1, 'value', Res), Res);
        NoteTry('p1.reopen', TryListOp(P1, 'reopenedit', Res), Res);
        NoteTry('p2.ok', TryListCloser(P2, 'ok', Res), Res);
        NoteTry('p1.value2', TryListOp(P1, 'value', Res), Res);
        NoteTry('p2.reopen', TryListOp(P2, 'reopenedit', Res), Res);
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
    procedure Probe_List_NewRow_OK()
    begin
        NewRowList('ok');
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
    procedure Probe_List_Two()
    begin
        TwoList();
    end;

    [TryFunction]
    local procedure TrySetupList(var P: TestPage "TPC List"; Mode: Text)
    begin
        case Mode of
            'dup':
                begin
                    P.OpenNew();
                    P.NoCtl.SetValue('A');
                    P.QtyCtl.SetValue(9);
                end;
            'insert':
                begin
                    P.OpenNew();
                    P.NoCtl.SetValue('N2');
                    P.NoteCtl.SetValue('FAIL');
                end;
            'modify':
                begin
                    P.OpenEdit();
                    P.NoteCtl.SetValue('FAIL');
                end;
        end;
    end;

    local procedure RefuseList(Mode: Text; Closer: Text)
    var
        P: TestPage "TPC List";
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        NoteTry('setup', TrySetupList(P, Mode), 'done');
        NoteTry(Closer + '.closer', TryListCloser(P, Closer, Res), Res);
        NoteTry('valerr', TryListOp(P, 'valerrcount', Res), Res);
        NoteTry('value', TryListOp(P, 'value', Res), Res);
        Note('log', TPCLog.Text());
        Note('table', TableState());
        NoteTry('reopen1', TryListOp(P, 'reopenedit', Res), Res);
        NoteTry('close', TryListOp(P, 'close', Res), Res);
        NoteTry('reopen2', TryListOp(P, 'reopenedit', Res), Res);
        Note('table2', TableState());
        Note('log2', TPCLog.Text());
        Error(Obs);
    end;

    [Test]
    procedure Probe_List_RefuseDup_Ok()
    begin
        RefuseList('dup', 'ok');
    end;

    [Test]
    procedure Probe_List_RefuseDup_Close()
    begin
        RefuseList('dup', 'close');
    end;

    [Test]
    procedure Probe_List_RefuseInsert_Ok()
    begin
        RefuseList('insert', 'ok');
    end;

    [Test]
    procedure Probe_List_RefuseInsert_Close()
    begin
        RefuseList('insert', 'close');
    end;

    [Test]
    procedure Probe_List_RefuseModify_Ok()
    begin
        RefuseList('modify', 'ok');
    end;

    [Test]
    procedure Probe_List_RefuseModify_Close()
    begin
        RefuseList('modify', 'close');
    end;

    // ---- Dialog ----

    [TryFunction]
    local procedure TryDialogCloser(var P: TestPage "TPC Dialog"; Closer: Text; var Res: Text)
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
    local procedure TryDialogOp(var P: TestPage "TPC Dialog"; Op: Text; var Res: Text)
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

    local procedure ProbeDialog(Closer: Text; Op: Text)
    var
        P: TestPage "TPC Dialog";
        Res: Text;
        AfterCloser: Text;
    begin
        Seed();
        TPCLog.Reset();
        P.OpenEdit();
        NoteTry(Closer + '.closer', TryDialogCloser(P, Closer, Res), Res);
        AfterCloser := TPCLog.Text();
        if Op = AllOps().Get(1) then
            Note(Closer + '.log', AfterCloser);
        NoteTry(Op, TryDialogOp(P, Op, Res), Res);
        if TPCLog.Text() <> AfterCloser then
            Note(Op + '.log', TPCLog.Text());
    end;

    local procedure RunDialog(Closer: Text; Chunk: Integer)
    var
        Op: Text;
    begin
        Obs := '';
        foreach Op in OpsChunk(Chunk, 8) do
            ProbeDialog(Closer, Op);
        Error(Obs);
    end;

    [Test]
    procedure Probe_Dialog_Ok_0()
    begin
        RunDialog('ok', 0);
    end;

    [Test]
    procedure Probe_Dialog_Ok_1()
    begin
        RunDialog('ok', 1);
    end;

    [Test]
    procedure Probe_Dialog_Ok_2()
    begin
        RunDialog('ok', 2);
    end;

    [Test]
    procedure Probe_Dialog_Cancel_0()
    begin
        RunDialog('cancel', 0);
    end;

    [Test]
    procedure Probe_Dialog_Cancel_1()
    begin
        RunDialog('cancel', 1);
    end;

    [Test]
    procedure Probe_Dialog_Cancel_2()
    begin
        RunDialog('cancel', 2);
    end;

    [Test]
    procedure Probe_Dialog_Close_0()
    begin
        RunDialog('close', 0);
    end;

    [Test]
    procedure Probe_Dialog_Close_1()
    begin
        RunDialog('close', 1);
    end;

    [Test]
    procedure Probe_Dialog_Close_2()
    begin
        RunDialog('close', 2);
    end;

    [Test]
    procedure Probe_Dialog_None_0()
    begin
        RunDialog('none', 0);
    end;

    [Test]
    procedure Probe_Dialog_None_1()
    begin
        RunDialog('none', 1);
    end;

    [Test]
    procedure Probe_Dialog_None_2()
    begin
        RunDialog('none', 2);
    end;

    local procedure WriteDialog(Closer: Text)
    var
        P: TestPage "TPC Dialog";
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        P.OpenEdit();
        P.QtyCtl.SetValue(5);
        NoteTry('closer', TryDialogCloser(P, Closer, Res), Res);
        Note('table', TableState());
        Note('log', TPCLog.Text());
        NoteTry('reopen', TryDialogOp(P, 'reopenedit', Res), Res);
        Error(Obs);
    end;

    local procedure NewRowDialog(Closer: Text)
    var
        P: TestPage "TPC Dialog";
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        P.OpenNew();
        P.NoCtl.SetValue('N1');
        P.QtyCtl.SetValue(9);
        NoteTry('closer', TryDialogCloser(P, Closer, Res), Res);
        Note('table', TableState());
        Note('log', TPCLog.Text());
        NoteTry('reopennew', TryDialogOp(P, 'reopennew', Res), Res);
        NoteTry('value', TryDialogOp(P, 'value', Res), Res);
        Error(Obs);
    end;

    local procedure VetoDialog(Closer: Text)
    var
        P: TestPage "TPC Dialog";
        Res: Text;
    begin
        Seed();
        Obs := '';
        TPCLog.Reset();
        TPCLog.SetVeto(true);
        P.OpenEdit();
        NoteTry('vetoed.' + Closer, TryDialogCloser(P, Closer, Res), Res);
        Note('log', TPCLog.Text());
        NoteTry('value-after-veto', TryDialogOp(P, 'value', Res), Res);
        NoteTry('reopen-after-veto', TryDialogOp(P, 'reopenedit', Res), Res);
        TPCLog.SetVeto(false);
        NoteTry('allowed.' + Closer, TryDialogCloser(P, Closer, Res), Res);
        Note('log2', TPCLog.Text());
        NoteTry('value-after-allowed', TryDialogOp(P, 'value', Res), Res);
        NoteTry('reopen-after-allowed', TryDialogOp(P, 'reopenedit', Res), Res);
        Error(Obs);
    end;

    local procedure TwoDialog()
    var
        P1: TestPage "TPC Dialog";
        P2: TestPage "TPC Dialog";
        Res: Text;
    begin
        Seed();
        Obs := '';
        P1.OpenEdit();
        P2.OpenEdit();
        NoteTry('p1.ok', TryDialogCloser(P1, 'ok', Res), Res);
        NoteTry('p2.value', TryDialogOp(P2, 'value', Res), Res);
        NoteTry('p1.value', TryDialogOp(P1, 'value', Res), Res);
        NoteTry('p1.reopen', TryDialogOp(P1, 'reopenedit', Res), Res);
        NoteTry('p2.ok', TryDialogCloser(P2, 'ok', Res), Res);
        NoteTry('p1.value2', TryDialogOp(P1, 'value', Res), Res);
        NoteTry('p2.reopen', TryDialogOp(P2, 'reopenedit', Res), Res);
        Error(Obs);
    end;

    [Test]
    procedure Probe_Dialog_Write_OK()
    begin
        WriteDialog('ok');
    end;

    [Test]
    procedure Probe_Dialog_Write_Cancel()
    begin
        WriteDialog('cancel');
    end;

    [Test]
    procedure Probe_Dialog_Write_Close()
    begin
        WriteDialog('close');
    end;

    [Test]
    procedure Probe_Dialog_NewRow_OK()
    begin
        NewRowDialog('ok');
    end;

    [Test]
    procedure Probe_Dialog_Veto_OK()
    begin
        VetoDialog('ok');
    end;

    [Test]
    procedure Probe_Dialog_Veto_Close()
    begin
        VetoDialog('close');
    end;

    [Test]
    procedure Probe_Dialog_Two()
    begin
        TwoDialog();
    end;

    // ---- handler: Card ----

    [ModalPageHandler]
    procedure CardHandler(var P: TestPage "TPC Card")
    var
        Res: Text;
        AfterCloser: Text;
    begin
        NoteTry(HandlerCloser + '.closer', TryCardCloser(P, HandlerCloser, Res), Res);
        AfterCloser := TPCLog.Text();
        NoteTry(HandlerOp, TryCardOp(P, HandlerOp, Res), Res);
        if TPCLog.Text() <> AfterCloser then
            Note(HandlerOp + '.log', TPCLog.Text());
    end;

    [TryFunction]
    local procedure TryRunCard(var Result: Action)
    var
        Row: Record "TPC Row";
    begin
        Row.FindFirst();
        Result := Page.RunModal(Page::"TPC Card", Row);
    end;

    local procedure RunHandlerCard(Closer: Text; Chunk: Integer)
    var
        Result: Action;
        Op: Text;
    begin
        Obs := '';
        foreach Op in OpsChunk(Chunk, 4) do begin
            Seed();
            TPCLog.Reset();
            HandlerCloser := Closer;
            HandlerOp := Op;
            NoteTry('RunModal', TryRunCard(Result), Format(Result));
            Note('log-end', TPCLog.Text());
        end;
        Error(Obs);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Ok_0()
    begin
        RunHandlerCard('ok', 0);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Ok_1()
    begin
        RunHandlerCard('ok', 1);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Ok_2()
    begin
        RunHandlerCard('ok', 2);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Ok_3()
    begin
        RunHandlerCard('ok', 3);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Ok_4()
    begin
        RunHandlerCard('ok', 4);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Ok_5()
    begin
        RunHandlerCard('ok', 5);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Cancel_0()
    begin
        RunHandlerCard('cancel', 0);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Cancel_1()
    begin
        RunHandlerCard('cancel', 1);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Cancel_2()
    begin
        RunHandlerCard('cancel', 2);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Cancel_3()
    begin
        RunHandlerCard('cancel', 3);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Cancel_4()
    begin
        RunHandlerCard('cancel', 4);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Cancel_5()
    begin
        RunHandlerCard('cancel', 5);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Close_0()
    begin
        RunHandlerCard('close', 0);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Close_1()
    begin
        RunHandlerCard('close', 1);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Close_2()
    begin
        RunHandlerCard('close', 2);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Close_3()
    begin
        RunHandlerCard('close', 3);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Close_4()
    begin
        RunHandlerCard('close', 4);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_Close_5()
    begin
        RunHandlerCard('close', 5);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_None_0()
    begin
        RunHandlerCard('none', 0);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_None_1()
    begin
        RunHandlerCard('none', 1);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_None_2()
    begin
        RunHandlerCard('none', 2);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_None_3()
    begin
        RunHandlerCard('none', 3);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_None_4()
    begin
        RunHandlerCard('none', 4);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Probe_HandlerCard_None_5()
    begin
        RunHandlerCard('none', 5);
    end;

    // ---- handler: List ----

    [ModalPageHandler]
    procedure ListHandler(var P: TestPage "TPC List")
    var
        Res: Text;
        AfterCloser: Text;
    begin
        NoteTry(HandlerCloser + '.closer', TryListCloser(P, HandlerCloser, Res), Res);
        AfterCloser := TPCLog.Text();
        NoteTry(HandlerOp, TryListOp(P, HandlerOp, Res), Res);
        if TPCLog.Text() <> AfterCloser then
            Note(HandlerOp + '.log', TPCLog.Text());
    end;

    [TryFunction]
    local procedure TryRunList(var Result: Action)
    var
        ListPage: Page "TPC List";
    begin
        Result := ListPage.RunModal();
    end;

    local procedure RunHandlerList(Closer: Text; Chunk: Integer)
    var
        Result: Action;
        Op: Text;
    begin
        Obs := '';
        foreach Op in OpsChunk(Chunk, 4) do begin
            Seed();
            TPCLog.Reset();
            HandlerCloser := Closer;
            HandlerOp := Op;
            NoteTry('RunModal', TryRunList(Result), Format(Result));
            Note('log-end', TPCLog.Text());
        end;
        Error(Obs);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Ok_0()
    begin
        RunHandlerList('ok', 0);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Ok_1()
    begin
        RunHandlerList('ok', 1);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Ok_2()
    begin
        RunHandlerList('ok', 2);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Ok_3()
    begin
        RunHandlerList('ok', 3);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Ok_4()
    begin
        RunHandlerList('ok', 4);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Ok_5()
    begin
        RunHandlerList('ok', 5);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Cancel_0()
    begin
        RunHandlerList('cancel', 0);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Cancel_1()
    begin
        RunHandlerList('cancel', 1);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Cancel_2()
    begin
        RunHandlerList('cancel', 2);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Cancel_3()
    begin
        RunHandlerList('cancel', 3);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Cancel_4()
    begin
        RunHandlerList('cancel', 4);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Cancel_5()
    begin
        RunHandlerList('cancel', 5);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Close_0()
    begin
        RunHandlerList('close', 0);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Close_1()
    begin
        RunHandlerList('close', 1);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Close_2()
    begin
        RunHandlerList('close', 2);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Close_3()
    begin
        RunHandlerList('close', 3);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Close_4()
    begin
        RunHandlerList('close', 4);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_Close_5()
    begin
        RunHandlerList('close', 5);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_None_0()
    begin
        RunHandlerList('none', 0);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_None_1()
    begin
        RunHandlerList('none', 1);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_None_2()
    begin
        RunHandlerList('none', 2);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_None_3()
    begin
        RunHandlerList('none', 3);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_None_4()
    begin
        RunHandlerList('none', 4);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Probe_HandlerList_None_5()
    begin
        RunHandlerList('none', 5);
    end;

    // ---- handler: Lookup ----

    [ModalPageHandler]
    procedure LookupHandler(var P: TestPage "TPC List")
    var
        Res: Text;
        AfterCloser: Text;
    begin
        NoteTry(HandlerCloser + '.closer', TryListCloser(P, HandlerCloser, Res), Res);
        AfterCloser := TPCLog.Text();
        NoteTry(HandlerOp, TryListOp(P, HandlerOp, Res), Res);
        if TPCLog.Text() <> AfterCloser then
            Note(HandlerOp + '.log', TPCLog.Text());
    end;

    [TryFunction]
    local procedure TryRunLookup(var Result: Action)
    var
        ListPage: Page "TPC List";
    begin
        ListPage.LookupMode(true);
        Result := ListPage.RunModal();
    end;

    local procedure RunHandlerLookup(Closer: Text; Chunk: Integer)
    var
        Result: Action;
        Op: Text;
    begin
        Obs := '';
        foreach Op in OpsChunk(Chunk, 4) do begin
            Seed();
            TPCLog.Reset();
            HandlerCloser := Closer;
            HandlerOp := Op;
            NoteTry('RunModal', TryRunLookup(Result), Format(Result));
            Note('log-end', TPCLog.Text());
        end;
        Error(Obs);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Ok_0()
    begin
        RunHandlerLookup('ok', 0);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Ok_1()
    begin
        RunHandlerLookup('ok', 1);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Ok_2()
    begin
        RunHandlerLookup('ok', 2);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Ok_3()
    begin
        RunHandlerLookup('ok', 3);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Ok_4()
    begin
        RunHandlerLookup('ok', 4);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Ok_5()
    begin
        RunHandlerLookup('ok', 5);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Cancel_0()
    begin
        RunHandlerLookup('cancel', 0);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Cancel_1()
    begin
        RunHandlerLookup('cancel', 1);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Cancel_2()
    begin
        RunHandlerLookup('cancel', 2);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Cancel_3()
    begin
        RunHandlerLookup('cancel', 3);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Cancel_4()
    begin
        RunHandlerLookup('cancel', 4);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Cancel_5()
    begin
        RunHandlerLookup('cancel', 5);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Close_0()
    begin
        RunHandlerLookup('close', 0);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Close_1()
    begin
        RunHandlerLookup('close', 1);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Close_2()
    begin
        RunHandlerLookup('close', 2);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Close_3()
    begin
        RunHandlerLookup('close', 3);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Close_4()
    begin
        RunHandlerLookup('close', 4);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_Close_5()
    begin
        RunHandlerLookup('close', 5);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_None_0()
    begin
        RunHandlerLookup('none', 0);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_None_1()
    begin
        RunHandlerLookup('none', 1);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_None_2()
    begin
        RunHandlerLookup('none', 2);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_None_3()
    begin
        RunHandlerLookup('none', 3);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_None_4()
    begin
        RunHandlerLookup('none', 4);
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure Probe_HandlerLookup_None_5()
    begin
        RunHandlerLookup('none', 5);
    end;

    // ---- handler: Dialog ----

    [ModalPageHandler]
    procedure DialogHandler(var P: TestPage "TPC Dialog")
    var
        Res: Text;
        AfterCloser: Text;
    begin
        NoteTry(HandlerCloser + '.closer', TryDialogCloser(P, HandlerCloser, Res), Res);
        AfterCloser := TPCLog.Text();
        NoteTry(HandlerOp, TryDialogOp(P, HandlerOp, Res), Res);
        if TPCLog.Text() <> AfterCloser then
            Note(HandlerOp + '.log', TPCLog.Text());
    end;

    [TryFunction]
    local procedure TryRunDialog(var Result: Action)
    begin
        Result := Page.RunModal(Page::"TPC Dialog");
    end;

    local procedure RunHandlerDialog(Closer: Text; Chunk: Integer)
    var
        Result: Action;
        Op: Text;
    begin
        Obs := '';
        foreach Op in OpsChunk(Chunk, 4) do begin
            Seed();
            TPCLog.Reset();
            HandlerCloser := Closer;
            HandlerOp := Op;
            NoteTry('RunModal', TryRunDialog(Result), Format(Result));
            Note('log-end', TPCLog.Text());
        end;
        Error(Obs);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Ok_0()
    begin
        RunHandlerDialog('ok', 0);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Ok_1()
    begin
        RunHandlerDialog('ok', 1);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Ok_2()
    begin
        RunHandlerDialog('ok', 2);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Ok_3()
    begin
        RunHandlerDialog('ok', 3);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Ok_4()
    begin
        RunHandlerDialog('ok', 4);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Ok_5()
    begin
        RunHandlerDialog('ok', 5);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Cancel_0()
    begin
        RunHandlerDialog('cancel', 0);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Cancel_1()
    begin
        RunHandlerDialog('cancel', 1);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Cancel_2()
    begin
        RunHandlerDialog('cancel', 2);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Cancel_3()
    begin
        RunHandlerDialog('cancel', 3);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Cancel_4()
    begin
        RunHandlerDialog('cancel', 4);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Cancel_5()
    begin
        RunHandlerDialog('cancel', 5);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Close_0()
    begin
        RunHandlerDialog('close', 0);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Close_1()
    begin
        RunHandlerDialog('close', 1);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Close_2()
    begin
        RunHandlerDialog('close', 2);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Close_3()
    begin
        RunHandlerDialog('close', 3);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Close_4()
    begin
        RunHandlerDialog('close', 4);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_Close_5()
    begin
        RunHandlerDialog('close', 5);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_None_0()
    begin
        RunHandlerDialog('none', 0);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_None_1()
    begin
        RunHandlerDialog('none', 1);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_None_2()
    begin
        RunHandlerDialog('none', 2);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_None_3()
    begin
        RunHandlerDialog('none', 3);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_None_4()
    begin
        RunHandlerDialog('none', 4);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Probe_HandlerDialog_None_5()
    begin
        RunHandlerDialog('none', 5);
    end;

    // ---- a request page ----

    [TryFunction]
    local procedure TryReqCloser(var R: TestRequestPage "TPC Report"; Closer: Text; var Res: Text)
    begin
        case Closer of
            'ok': R.OK().Invoke();
            'cancel': R.Cancel().Invoke();
            'none': ;
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
        Res: Text;
        AfterCloser: Text;
    begin
        NoteTry(HandlerCloser + '.closer', TryReqCloser(R, HandlerCloser, Res), Res);
        AfterCloser := TPCLog.Text();
        NoteTry(HandlerOp, TryReqOp(R, HandlerOp, Res), Res);
        if TPCLog.Text() <> AfterCloser then
            Note(HandlerOp + '.log', TPCLog.Text());
    end;

    [TryFunction]
    local procedure TryRunRequest(var Params: Text)
    begin
        Params := Report.RunRequestPage(Report::"TPC Report");
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
            NoteTry('RunRequestPage', TryRunRequest(Params), Format(StrLen(Params) > 0));
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
    procedure Probe_Request_Ok()
    begin
        RunRequest('ok');
    end;

    [Test]
    [HandlerFunctions('ReqHandler')]
    procedure Probe_Request_Cancel()
    begin
        RunRequest('cancel');
    end;

    [Test]
    [HandlerFunctions('ReqHandler')]
    procedure Probe_Request_None()
    begin
        RunRequest('none');
    end;

    // ---- SaveValues: what a reopen shows after each closing action ----

    local procedure SavedDialogProbe(Closer: Text)
    var
        P: TestPage "TPC Saved Dialog";
        Res: Text;
        Ok: Boolean;
    begin
        Obs := '';
        P.OpenEdit();
        P.Remembered.SetValue('typed');
        case Closer of
            'ok': Ok := TrySavedDialogOK(P);
            'cancel': Ok := TrySavedDialogCancel(P);
            'close': Ok := TrySavedDialogClose(P);
        end;
        NoteTry('closer', Ok, 'done');
        NoteTry('reopen', TrySavedDialogReopen(P, Res), Res);
        Error(Obs);
    end;

    [TryFunction]
    local procedure TrySavedDialogOK(var P: TestPage "TPC Saved Dialog")
    begin
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure TrySavedDialogCancel(var P: TestPage "TPC Saved Dialog")
    begin
        P.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TrySavedDialogClose(var P: TestPage "TPC Saved Dialog")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TrySavedDialogReopen(var P: TestPage "TPC Saved Dialog"; var Res: Text)
    begin
        P.OpenEdit();
        Res := P.Remembered.Value();
    end;

    local procedure SavedCardProbe(Closer: Text)
    var
        P: TestPage "TPC Saved Card";
        Res: Text;
        Ok: Boolean;
    begin
        Obs := '';
        P.OpenEdit();
        P.Remembered.SetValue('typed');
        case Closer of
            'ok': Ok := TrySavedCardOK(P);
            'close': Ok := TrySavedCardClose(P);
        end;
        NoteTry('closer', Ok, 'done');
        NoteTry('reopen', TrySavedCardReopen(P, Res), Res);
        Error(Obs);
    end;

    [TryFunction]
    local procedure TrySavedCardOK(var P: TestPage "TPC Saved Card")
    begin
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure TrySavedCardClose(var P: TestPage "TPC Saved Card")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TrySavedCardReopen(var P: TestPage "TPC Saved Card"; var Res: Text)
    begin
        P.OpenEdit();
        Res := P.Remembered.Value();
    end;

    [Test]
    procedure Probe_SavedDialog_Ok()
    begin
        SavedDialogProbe('ok');
    end;

    [Test]
    procedure Probe_SavedDialog_Cancel()
    begin
        SavedDialogProbe('cancel');
    end;

    [Test]
    procedure Probe_SavedDialog_Close()
    begin
        SavedDialogProbe('close');
    end;

    [Test]
    procedure Probe_SavedCard_Ok()
    begin
        SavedCardProbe('ok');
    end;

    [Test]
    procedure Probe_SavedCard_Close()
    begin
        SavedCardProbe('close');
    end;
}
