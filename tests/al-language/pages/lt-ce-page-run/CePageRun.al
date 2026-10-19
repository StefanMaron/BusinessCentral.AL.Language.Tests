// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal--method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-integer-table-integer-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-settableview-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-pages-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in CeObjects.al (84340 to 84359)
// Corpus issue 667 (part B), writer CE: Page.RunModal with an Enum or Option filter, OpenView of a descending list with OnFindRecord,
// Page.Run(0, Rec) and a page id that does not exist, SetTableView on a page with a SourceTableView, Page.Run and Report.Run with a
// Variant that holds a RecordRef.

report 84350 "LT CE Rows Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT CE Row")
        {
            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT CE Log";
            begin
                Log.Add('report row ' + Format(Row.Id));
            end;
        }
    }
}

codeunit 84362 "LT CE Page Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seen: Text;
        NewKind: Text;
        NewOpt: Text;
        FilterSeen: Text;

    local procedure Seed()
    var
        Row: Record "LT CE Row";
        Plain: Record "LT CE Plain Row";
    begin
        Row.DeleteAll();
        Plain.DeleteAll();
        AddRow(1, "LT CE Kind"::A);
        AddRow(2, "LT CE Kind"::B);
        AddRow(3, "LT CE Kind"::A);
        AddRow(4, "LT CE Kind"::C);
        AddRow(5, "LT CE Kind"::B);
        Plain.Id := 1;
        Plain.Insert();
        Seen := '';
        NewKind := '';
        NewOpt := '';
        FilterSeen := '';
    end;

    local procedure AddRow(Id: Integer; Kind: Enum "LT CE Kind")
    var
        Row: Record "LT CE Row";
    begin
        Row.Id := Id;
        Row.Kind := Kind;
        Row.Opt := Kind.AsInteger();
        Row.Name := 'row ' + Format(Id);
        Row.Insert();
    end;

    local procedure Stored(Id: Integer): Text
    var
        Row: Record "LT CE Row";
    begin
        if not Row.Get(Id) then
            exit('missing');
        exit(Format(Row.Kind) + '/' + Format(Row.Opt));
    end;

    // ---- RunModal with an Enum filter against an Option filter ----

    [Test]
    [HandlerFunctions('NewRowHandler')]
    procedure RunModal_EnumFilter_RowsAndNewRowDefault()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CE Row";
    begin
        Seed();
        Row.SetRange(Kind, "LT CE Kind"::B);
        Observer.Observe('action', Format(Page.RunModal(Page::"LT CE List", Row)));
        Observer.Observe('rows', Seen);
        Observer.Observe('new_kind', NewKind);
        Observer.Observe('new_opt', NewOpt);
        Observer.Observe('stored', Stored(90));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('NewRowHandler')]
    procedure RunModal_OptionFilter_RowsAndNewRowDefault()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CE Row";
    begin
        Seed();
        Row.SetRange(Opt, Row.Opt::B);
        Observer.Observe('action', Format(Page.RunModal(Page::"LT CE List", Row)));
        Observer.Observe('rows', Seen);
        Observer.Observe('new_kind', NewKind);
        Observer.Observe('new_opt', NewOpt);
        Observer.Observe('stored', Stored(90));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure NewRowHandler(var L: TestPage "LT CE List")
    begin
        Seen := WalkIds(L);
        L.New();
        L.Id.SetValue(90);
        NewKind := L.Kind.Value();
        NewOpt := L.Opt.Value();
        L.OK().Invoke();
    end;

    local procedure WalkIds(var L: TestPage "LT CE List") Ids: Text
    begin
        if not L.First() then
            exit('none');
        repeat
            Ids += '[' + L.Id.Value() + ']';
        until not L.Next();
    end;

    // ---- OpenView of a descending list, with and without OnFindRecord ----

    [Test]
    procedure OpenView_DescendingWithOnFindRecord_CurrentRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT CE Log";
        L: TestPage "LT CE Desc Find List";
    begin
        Seed();
        Log.Take();
        L.OpenView();
        Observer.Observe('current', L.Id.Value());
        Observer.Observe('first_find', CopyStr(Log.Take(), 1, 40));
        L.Close();
        Observer.Finish();
    end;

    [Test]
    procedure OpenView_DescendingPlain_CurrentRow()
    var
        Observer: Codeunit "Probe Observer";
        L: TestPage "LT CE Desc Plain List";
    begin
        Seed();
        L.OpenView();
        Observer.Observe('current', L.Id.Value());
        L.Close();
        Observer.Finish();
    end;

    // ---- Page.Run(0, Rec) and a page that does not exist ----

    [Test]
    [HandlerFunctions('ListPageHandler')]
    procedure PageRun_Zero_OpensTheLookupPage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CE Row";
    begin
        Seed();
        Row.Get(3);
        Page.Run(0, Row);
        Observer.Observe('opened', Seen);
        Observer.Finish();
    end;

    [Test]
    procedure PageRun_Zero_TableWithoutLookupPage()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Record "LT CE Plain Row";
    begin
        Seed();
        Plain.FindFirst();
        Observer.Observe('run|ok', Format(TryRunZero(Plain, false)));
        Observer.ObserveError('run');
        Observer.Observe('runmodal|ok', Format(TryRunZero(Plain, true)));
        Observer.ObserveError('runmodal');
        Observer.Finish();
    end;

    [Test]
    procedure PageRun_PageThatDoesNotExist()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CE Row";
    begin
        Seed();
        Observer.Observe('run|ok', Format(TryRunId(84399, false, false, Row)));
        Observer.ObserveError('run');
        Observer.Observe('runmodal|ok', Format(TryRunId(84399, true, false, Row)));
        Observer.ObserveError('runmodal');
        Row.Get(1);
        Observer.Observe('run_rec|ok', Format(TryRunId(84399, false, true, Row)));
        Observer.ObserveError('run_rec');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryRunZero(var Plain: Record "LT CE Plain Row"; Modal: Boolean)
    begin
        if Modal then
            Page.RunModal(0, Plain)
        else
            Page.Run(0, Plain);
    end;

    [TryFunction]
    local procedure TryRunId(PageId: Integer; Modal: Boolean; WithRec: Boolean; var Row: Record "LT CE Row")
    begin
        case true of
            Modal:
                Page.RunModal(PageId);
            WithRec:
                Page.Run(PageId, Row);
            else
                Page.Run(PageId);
        end;
    end;

    [PageHandler]
    procedure ListPageHandler(var L: TestPage "LT CE List")
    begin
        Seen := 'LT CE List current=' + L.Id.Value();
    end;

    // ---- SetTableView on a page with SourceTableView = where(Kind = const(A)) ----

    [Test]
    [HandlerFunctions('ViewHandler')]
    procedure SetTableView_ConflictingFilterOnTheSameField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CE Row";
        Pg: Page "LT CE View List";
    begin
        Seed();
        Row.SetRange(Kind, "LT CE Kind"::B);
        Pg.SetTableView(Row);
        Pg.RunModal();
        Observer.Observe('rows', Seen);
        Observer.Observe('filter', FilterSeen);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ViewHandler')]
    procedure SetTableView_WiderFilterOnTheSameField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CE Row";
        Pg: Page "LT CE View List";
    begin
        Seed();
        Row.SetFilter(Kind, '%1|%2', "LT CE Kind"::A, "LT CE Kind"::B);
        Pg.SetTableView(Row);
        Pg.RunModal();
        Observer.Observe('rows', Seen);
        Observer.Observe('filter', FilterSeen);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ViewHandler')]
    procedure SetTableView_FilterOnAnotherField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CE Row";
        Pg: Page "LT CE View List";
    begin
        Seed();
        Row.SetRange(Id, 1, 2);
        Pg.SetTableView(Row);
        Pg.RunModal();
        Observer.Observe('rows', Seen);
        Observer.Observe('filter', FilterSeen);
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure ViewHandler(var L: TestPage "LT CE View List")
    begin
        FilterSeen := 'Kind=' + L.Filter.GetFilter(Kind) + ' Id=' + L.Filter.GetFilter(Id);
        if not L.First() then begin
            Seen := 'none';
            exit;
        end;
        repeat
            Seen += '[' + L.Id.Value() + ']';
        until not L.Next();
    end;

    // ---- Page.Run, Page.RunModal and Report.Run with a Variant ----

    [Test]
    [HandlerFunctions('ListPageHandler')]
    procedure PageRun_VariantHoldingRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        V: Variant;
    begin
        Seed();
        RecRef.Open(Database::"LT CE Row");
        RecRef.FindLast();
        V := RecRef;
        Observer.Observe('run|ok', Format(TryRunVariant(V, 0)));
        if Seen = '' then
            Observer.ObserveError('run');
        Observer.Observe('run|seen', Seen);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListModalHandler')]
    procedure PageRunModal_VariantHoldingRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        V: Variant;
    begin
        Seed();
        RecRef.Open(Database::"LT CE Row");
        RecRef.FindLast();
        V := RecRef;
        Observer.Observe('runmodal|ok', Format(TryRunVariant(V, 1)));
        if Seen = '' then
            Observer.ObserveError('runmodal');
        Observer.Observe('runmodal|seen', Seen);
        Observer.Finish();
    end;

    [Test]
    procedure ReportRun_VariantHoldingRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT CE Log";
        RecRef: RecordRef;
        IdRef: FieldRef;
        V: Variant;
        Ok: Boolean;
    begin
        Seed();
        RecRef.Open(Database::"LT CE Row");
        IdRef := RecRef.Field(1);
        IdRef.SetRange(2, 3);
        V := RecRef;
        Log.Take();
        Ok := TryRunVariant(V, 2);
        Observer.Observe('report|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('report');
        Observer.Observe('report|log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListPageHandler')]
    procedure PageRun_VariantHoldingRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CE Row";
        V: Variant;
    begin
        Seed();
        Row.Get(4);
        V := Row;
        Observer.Observe('run|ok', Format(TryRunVariant(V, 0)));
        if Seen = '' then
            Observer.ObserveError('run');
        Observer.Observe('run|seen', Seen);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryRunVariant(var V: Variant; Mode: Integer)
    begin
        case Mode of
            0:
                Page.Run(Page::"LT CE List", V);
            1:
                Page.RunModal(Page::"LT CE List", V);
            2:
                Report.Run(Report::"LT CE Rows Report", false, false, V);
        end;
    end;

    [ModalPageHandler]
    procedure ListModalHandler(var L: TestPage "LT CE List")
    begin
        Seen := 'LT CE List current=' + L.Id.Value();
    end;
}
