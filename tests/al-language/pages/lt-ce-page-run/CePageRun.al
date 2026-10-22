// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal--method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-integer-table-integer-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-settableview-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-pages-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in CeObjects.al (84340 to 84364)
// Corpus issue 667 (part B), writer CE: Page.RunModal with an Enum or Option filter, OpenView of a descending list with OnFindRecord,
// Page.Run(0, Rec) and a page id that does not exist, SetTableView on a page with a SourceTableView, Page.Run and Report.Run with a
// Variant that holds a RecordRef.
// Probe: written against a local BC 29.0 service tier; every literal below is what that tier produced; 27.5 and 28.5 by the CI matrix.
// Facts (BC 29.0): Page.RunModal(Id, Rec) shows only the filtered rows for an Enum and for an Option filter, returns LookupOK, and a row
// made with New() does NOT take the filtered value (Kind and Opt stay A, also once saved). OpenView of a descending list whose
// OnFindRecord calls Rec.Find(Which) stands on Id 1 (OnFindRecord('=><') from the empty Rec finds the LAST row of the descending view),
// the same list without the trigger stands on Id 5. Page.Run(0, Rec) opens the table's LookupPageId on the record; for a table without
// one, and for a page id that does not exist, Page.Run and Page.RunModal raise AL:MetadataNotFound. SetTableView on a page with
// SourceTableView = where(Kind = const(A)) gives the intersection (Kind B: no rows; A|B: rows 1 and 3; Id 1..2: row 1).
// A Variant holding a RecordRef is accepted by Page.Run, Page.RunModal and Report.Run (the RecordRef itself does not compile:
// must-not-compile cases 1633 and 1634).

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
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rows', '[2][5]');
        Observer.Expect('new_kind', 'A');
        Observer.Expect('new_opt', 'A');
        Observer.Expect('stored', 'A/A');
        Observer.Verify();
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
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rows', '[2][5]');
        Observer.Expect('new_kind', 'A');
        Observer.Expect('new_opt', 'A');
        Observer.Expect('stored', 'A/A');
        Observer.Verify();
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
        Observer.Expect('current', '1');
        Observer.Expect('first_find', 'find(=><)=1;');
        Observer.Verify();
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
        Observer.Expect('current', '5');
        Observer.Verify();
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
        Observer.Expect('opened', 'LT CE List current=3');
        Observer.Verify();
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
        Observer.Expect('run|ok', 'No');
        Observer.Expect('run|text', 'You tried to invoke the Page object with the ID 0 from the object LT CE Page Run Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run|code', 'AL:MetadataNotFound');
        Observer.Expect('runmodal|ok', 'No');
        Observer.Expect('runmodal|text', 'You tried to invoke the Page object with the ID 0 from the object LT CE Page Run Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('runmodal|code', 'AL:MetadataNotFound');
        Observer.Verify();
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
        Observer.Expect('run|ok', 'No');
        Observer.Expect('run|text', 'You tried to invoke the Page object with the ID 84399 from the object LT CE Page Run Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run|code', 'AL:MetadataNotFound');
        Observer.Expect('runmodal|ok', 'No');
        Observer.Expect('runmodal|text', 'You tried to invoke the Page object with the ID 84399 from the object LT CE Page Run Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('runmodal|code', 'AL:MetadataNotFound');
        Observer.Expect('run_rec|ok', 'No');
        Observer.Expect('run_rec|text', 'You tried to invoke the Page object with the ID 84399 from the object LT CE Page Run Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run_rec|code', 'AL:MetadataNotFound');
        Observer.Verify();
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
        Observer.Expect('rows', 'none');
        Observer.Expect('filter', 'Kind=1 Id=');
        Observer.Verify();
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
        Observer.Expect('rows', '[1][3]');
        Observer.Expect('filter', 'Kind=A|B Id=');
        Observer.Verify();
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
        Observer.Expect('rows', '[1]');
        Observer.Expect('filter', 'Kind=0 Id=1..2');
        Observer.Verify();
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
        Observer.Expect('run|ok', 'Yes');
        Observer.Expect('run|seen', 'LT CE List current=5');
        Observer.Verify();
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
        Observer.Expect('runmodal|ok', 'Yes');
        Observer.Expect('runmodal|seen', 'LT CE List current=5');
        Observer.Verify();
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
        Observer.Expect('report|ok', 'Yes');
        Observer.Expect('report|log', 'report row 2;report row 3;');
        Observer.Verify();
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
        Observer.Expect('run|ok', 'Yes');
        Observer.Expect('run|seen', 'LT CE List current=4');
        Observer.Verify();
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
