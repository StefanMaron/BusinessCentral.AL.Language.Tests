// Probes: md:146 (RunObject / RunPageMode / RunPageOnRec / RunPageLink / RunPageView combinations the runtime refuses),
// md:152 (SourceTableView on a page handed a record by Page.RunModal).
// Refusal candidates are invoked WITHOUT a handler for the target: either BC refuses the action (error text observed) or it opens the page
// and the missing handler is the error (text observed); the contrast tests use handlers.

table 69235 "W1 Hdr"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69246 "W1 RO Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 69282 "W1 RO Plain Cu"
{
    TableNo = "W1 Row";

    trigger OnRun()
    var
        Log: Codeunit "W1 RO Log";
    begin
        Log.Add('plain cu ran, rec.id=' + Format(Rec.Id));
    end;
}

codeunit 69283 "W1 RO Single Cu"
{
    TableNo = "W1 Row";
    SingleInstance = true;

    trigger OnRun()
    var
        Log: Codeunit "W1 RO Log";
    begin
        Log.Add('single cu ran, rec.id=' + Format(Rec.Id));
    end;
}

codeunit 69284 "W1 RO Hdr Cu"
{
    TableNo = "W1 Hdr";

    trigger OnRun()
    var
        Log: Codeunit "W1 RO Log";
    begin
        Log.Add('hdr cu ran, rec.id=' + Format(Rec.Id));
    end;
}

page 69321 "W1 RO Target"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Name; Rec.Name) { }
            field(Grp; Rec.Grp) { }
        }
    }

    var
        Log: Codeunit "W1 RO Log";

    trigger OnOpenPage()
    begin
        Log.Add('target:OnOpenPage id=' + Format(Rec.Id) + ' filters=' + Rec.GetFilters());
    end;
}

page 69322 "W1 RO View Target"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";
    SourceTableView = where(Grp = const(1));

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Name; Rec.Name) { }
            field(Grp; Rec.Grp) { }
        }
    }

    var
        Log: Codeunit "W1 RO Log";

    trigger OnOpenPage()
    begin
        Log.Add('viewtarget:OnOpenPage id=' + Format(Rec.Id) + ' filters=' + Rec.GetFilters());
    end;
}

page 69323 "W1 RO No Source"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Text1; Text1) { }
        }
    }

    var
        Text1: Text[30];
        Log: Codeunit "W1 RO Log";

    trigger OnOpenPage()
    begin
        Log.Add('nosource:OnOpenPage');
    end;
}

page 69324 "W1 RO Host"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Name; Rec.Name) { }
            field(Grp; Rec.Grp) { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PlainOnRec)
            {
                RunObject = page "W1 RO Target";
                RunPageOnRec = true;
            }
            action(EditOnRec)
            {
                RunObject = page "W1 RO Target";
                RunPageMode = Edit;
                RunPageOnRec = true;
            }
            action(CreateOnRec)
            {
                RunObject = page "W1 RO Target";
                RunPageMode = Create;
                RunPageOnRec = true;
            }
            action(CreateLink)
            {
                RunObject = page "W1 RO Target";
                RunPageMode = Create;
                RunPageLink = Grp = field(Grp);
            }
            action(CreateView)
            {
                RunObject = page "W1 RO Target";
                RunPageMode = Create;
                RunPageView = where(Grp = const(1));
            }
            action(CreatePlain)
            {
                RunObject = page "W1 RO Target";
                RunPageMode = Create;
            }
            action(ViewTargetOnRec)
            {
                RunObject = page "W1 RO View Target";
                RunPageOnRec = true;
            }
            action(ViewTargetLink)
            {
                RunObject = page "W1 RO View Target";
                RunPageLink = Grp = field(Grp);
            }
            action(ViewTargetView)
            {
                RunObject = page "W1 RO View Target";
                RunPageView = where(Grp = const(2));
            }
            action(NoSourceOnRec)
            {
                RunObject = page "W1 RO No Source";
                RunPageOnRec = true;
            }
            action(CuPlain)
            {
                RunObject = codeunit "W1 RO Plain Cu";
            }
            action(CuLink)
            {
                RunObject = codeunit "W1 RO Plain Cu";
                RunPageLink = Grp = field(Grp);
            }
            action(CuView)
            {
                RunObject = codeunit "W1 RO Plain Cu";
                RunPageView = where(Grp = const(1));
            }
            action(CuSingle)
            {
                RunObject = codeunit "W1 RO Single Cu";
            }
            action(CuWrongTable)
            {
                RunObject = codeunit "W1 RO Hdr Cu";
            }
        }
    }
}

page 69325 "W1 RO Host Hdr"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Hdr";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Name; Rec.Name) { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TargetOfOtherTableOnRec)
            {
                RunObject = page "W1 RO Target";
                RunPageOnRec = true;
            }
        }
    }
}

page 69326 "W1 SrcView List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";
    SourceTableView = where(Grp = filter(1 | 2));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Grp; Rec.Grp) { }
            }
        }
    }
}

codeunit 69305 "W1 RunObject Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "W1 RO Log";

    local procedure Seed()
    var
        Row: Record "W1 Row";
        Hdr: Record "W1 Hdr";
        i: Integer;
    begin
        Row.DeleteAll();
        Hdr.DeleteAll();
        for i := 1 to 6 do begin
            Row.Init();
            Row.Id := i;
            Row.Name := 'n' + Format(i);
            Row.Grp := (i + 1) div 2;
            Row.Insert();
        end;
        Hdr.Id := 1;
        Hdr.Insert();
        Log.Take();
    end;

    [TryFunction]
    local procedure TryAction(var Host: TestPage "W1 RO Host"; ActionName: Text)
    begin
        case ActionName of
            'CreateOnRec':
                Host.CreateOnRec.Invoke();
            'CreateLink':
                Host.CreateLink.Invoke();
            'CreateView':
                Host.CreateView.Invoke();
            'ViewTargetOnRec':
                Host.ViewTargetOnRec.Invoke();
            'ViewTargetLink':
                Host.ViewTargetLink.Invoke();
            'ViewTargetView':
                Host.ViewTargetView.Invoke();
            'NoSourceOnRec':
                Host.NoSourceOnRec.Invoke();
            'CuPlain':
                Host.CuPlain.Invoke();
            'CuLink':
                Host.CuLink.Invoke();
            'CuView':
                Host.CuView.Invoke();
            'CuSingle':
                Host.CuSingle.Invoke();
            'CuWrongTable':
                Host.CuWrongTable.Invoke();
            'PlainOnRec':
                Host.PlainOnRec.Invoke();
            'CreatePlain':
                Host.CreatePlain.Invoke();
            'EditOnRec':
                Host.EditOnRec.Invoke();
        end;
    end;

    local procedure Attempt(var Observer: Codeunit "Probe Observer"; var Host: TestPage "W1 RO Host"; ActionName: Text)
    begin
        Log.Take();
        if TryAction(Host, ActionName) then
            Observer.Observe(ActionName + '|result', 'ok, log=' + Log.Take())
        else begin
            Observer.ObserveError(ActionName);
            Observer.Observe(ActionName + '|log', Log.Take());
        end;
    end;

    // The three Create combinations (all without a handler for the target).
    [Test]
    procedure Create_WithOnRec_Link_View()
    var
        Host: TestPage "W1 RO Host";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Host.OpenView();
        Host.GoToKey(3);
        Attempt(Observer, Host, 'CreateOnRec');
        Attempt(Observer, Host, 'CreateLink');
        Attempt(Observer, Host, 'CreateView');
        Attempt(Observer, Host, 'CreatePlain');
        Host.Close();
        Observer.Expect('CreateOnRec|result', 'ok, log=target:OnOpenPage id=3 filters=;');
        Observer.Expect('CreateLink|result', 'ok, log=target:OnOpenPage id=0 filters=Grp: 2;');
        Observer.Expect('CreateView|result', 'ok, log=target:OnOpenPage id=0 filters=;');
        Observer.Expect('CreatePlain|result', 'ok, log=target:OnOpenPage id=0 filters=;');
        Observer.Verify();
    end;

    // Target page with a SourceTableView, and a target without a source table.
    [Test]
    procedure TargetWithSourceTableView_OrNoSourceTable()
    var
        Host: TestPage "W1 RO Host";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Host.OpenView();
        Host.GoToKey(3);
        Attempt(Observer, Host, 'ViewTargetOnRec');
        Attempt(Observer, Host, 'ViewTargetLink');
        Attempt(Observer, Host, 'ViewTargetView');
        Attempt(Observer, Host, 'NoSourceOnRec');
        Host.Close();
        Observer.Expect('ViewTargetOnRec|result', 'ok, log=viewtarget:OnOpenPage id=3 filters=;');
        Observer.Expect('ViewTargetLink|result', 'ok, log=viewtarget:OnOpenPage id=0 filters=Grp: 2;');
        Observer.Expect('ViewTargetView|result', 'ok, log=viewtarget:OnOpenPage id=0 filters=;');
        Observer.Expect('NoSourceOnRec|result', 'ok, log=nosource:OnOpenPage;');
        Observer.Verify();
    end;

    // Codeunit targets.
    [Test]
    procedure CodeunitTargets()
    var
        Host: TestPage "W1 RO Host";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Host.OpenView();
        Host.GoToKey(3);
        Attempt(Observer, Host, 'CuPlain');
        Attempt(Observer, Host, 'CuLink');
        Attempt(Observer, Host, 'CuView');
        Attempt(Observer, Host, 'CuSingle');
        Attempt(Observer, Host, 'CuWrongTable');
        Host.Close();
        Observer.Expect('CuPlain|result', 'ok, log=plain cu ran, rec.id=3;');
        Observer.Expect('CuLink|result', 'ok, log=plain cu ran, rec.id=3;');
        Observer.Expect('CuView|result', 'ok, log=plain cu ran, rec.id=3;');
        Observer.Expect('CuSingle|result', 'ok, log=single cu ran, rec.id=3;');
        Observer.Expect('CuWrongTable|text', 'Record(69232) is not compatible with Codeunit.Run(Record(69235)).');
        Observer.Expect('CuWrongTable|code', 'TestWrapped:InvalidType');
        Observer.Expect('CuWrongTable|log', '');
        Observer.Verify();
    end;

    [PageHandler]
    procedure TargetHandler(var Pg: TestPage "W1 RO Target")
    begin
        Log.Add('handler: id=' + Pg.Id.Value() + ' grp=' + Pg.Grp.Value());
        Pg.Close();
    end;

    // RunPageOnRec from a host row that is not stored (a new row of the host), and the stored-row contrast.
    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure PlainOnRec_FromNewUnsavedHostRow()
    var
        Host: TestPage "W1 RO Host";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Host.OpenNew();
        Host.Id.SetValue(77);
        Attempt(Observer, Host, 'PlainOnRec');
        Host.Close();
        Observer.Expect('PlainOnRec|result', 'ok, log=target:OnOpenPage id=77 filters=;handler: id=77 grp=0;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure PlainOnRec_FromStoredHostRow_Contrast()
    var
        Host: TestPage "W1 RO Host";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Host.OpenView();
        Host.GoToKey(3);
        Attempt(Observer, Host, 'PlainOnRec');
        Attempt(Observer, Host, 'EditOnRec');
        Host.Close();
        Observer.Expect('PlainOnRec|result', 'ok, log=target:OnOpenPage id=3 filters=;handler: id=3 grp=2;');
        Observer.Expect('EditOnRec|result', 'ok, log=target:OnOpenPage id=3 filters=;handler: id=3 grp=2;');
        Observer.Verify();
    end;

    // RunPageOnRec on a host over another table than the target.
    [Test]
    procedure OnRec_HostOverAnotherTable()
    var
        Host: TestPage "W1 RO Host Hdr";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Host.OpenView();
        Log.Take();
        asserterror Host.TargetOfOtherTableOnRec.Invoke();
        Observer.ObserveError('other_table');
        Observer.Observe('log', Log.Take());
        Host.Close();
        Observer.Expect('other_table|text', 'A RecordID from table ''W1 Hdr'' cannot be used with a record from table ''W1 Row''.');
        Observer.Expect('other_table|code', 'TestWrapped:CSide');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    // ---------- md:152: SourceTableView on the page, record with a filter handed over by Page.RunModal ----------

    [ModalPageHandler]
    procedure WalkHandler(var Pg: TestPage "W1 SrcView List")
    var
        Seq: Text;
    begin
        if Pg.First() then
            repeat
                Seq += Pg.Id.Value() + ' ';
            until not Pg.Next();
        Log.Add('rows=' + Seq);
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure SourceTableView_PlusRecordFilterOnTheSameField()
    var
        Filtered: Record "W1 Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Filtered.SetFilter(Grp, '2|3');
        Page.RunModal(Page::"W1 SrcView List", Filtered);
        Observer.Observe('view_grp_1_or_2__rec_grp_2_or_3', Log.Take());
        Observer.Expect('view_grp_1_or_2__rec_grp_2_or_3', 'rows=3 4 ;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure SourceTableView_PlusRecordFilterOnAnotherField()
    var
        Filtered: Record "W1 Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Filtered.SetRange(Id, 2, 5);
        Page.RunModal(Page::"W1 SrcView List", Filtered);
        Observer.Observe('view_grp_1_or_2__rec_id_2_to_5', Log.Take());
        Observer.Expect('view_grp_1_or_2__rec_id_2_to_5', 'rows=2 3 4 ;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure SourceTableView_RecordWithoutFilter()
    var
        Filtered: Record "W1 Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Page.RunModal(Page::"W1 SrcView List", Filtered);
        Observer.Observe('view_grp_1_or_2__rec_no_filter', Log.Take());
        Filtered.Get(5);
        Page.RunModal(Page::"W1 SrcView List", Filtered);
        Observer.Observe('view_grp_1_or_2__rec_positioned_on_5_no_filter', Log.Take());
        Observer.Expect('view_grp_1_or_2__rec_no_filter', 'rows=1 2 3 4 ;');
        Observer.Expect('view_grp_1_or_2__rec_positioned_on_5_no_filter', 'rows=1 2 3 4 ;');
        Observer.Verify();
    end;
}
