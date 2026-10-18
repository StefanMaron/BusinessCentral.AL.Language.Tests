// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 79400-79403, log codeunit 79404, pages 79410-79416 (AnObjects.al)
// Settles corpus issue 640 (TestPage behavior, part 1), items 1, 2, 8, 10, 11, 14, 15, 16 and 19.
// Facts: SetValue of a Decimal with three decimals outside MinValue/MaxValue of a page variable control (text, code, value afterwards);
// how often and in which order a part's rows are read when the host opens (const and field() SubPageLink, 1 and 5 rows);
// Date control SetValue of 't', 'today', 'workdate', 'W', 'T'; Clear of a TestPage over a part page; OnFindRecord/OnNextRecord/OnAfterGetRecord
// after an action deletes the current row; the start row and result of a TableRelation lookup; Lookup with no lookup page and no handler;
// Duration SetValue of '-' and '1,5 hours'; the caption of a table field whose CaptionClass is 'X,Y'.

codeunit 79450 "LT AN TestPage Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LookupStart: Text;
        LookupPick: Code[20];

    local procedure Seed()
    var
        Row: Record "LT AN Row";
        Related: Record "LT AN Related";
        Pageless: Record "LT AN Pageless";
        Line: Record "LT AN Line";
        i: Integer;
    begin
        Row.DeleteAll();
        Related.DeleteAll();
        Pageless.DeleteAll();
        Line.DeleteAll();
        Row."Code" := 'FIVE';
        Row.Insert();
        Row."Code" := 'ONE';
        Row.Insert();
        for i := 1 to 5 do begin
            Related."Code" := 'R' + Format(i);
            Related.Name := 'Related ' + Format(i);
            Related.Insert();
        end;
        Pageless."Code" := 'PL-A';
        Pageless.Insert();
        Line.Doc := 'ONE';
        Line."Line No." := 10;
        Line.Insert();
        for i := 1 to 5 do begin
            Line.Doc := 'FIVE';
            Line."Line No." := i * 10;
            Line.Insert();
        end;
    end;

    local procedure OpenCard(var P: TestPage "LT AN Card")
    var
        Row: Record "LT AN Row";
    begin
        Row.Get('ONE');
        P.OpenEdit();
        P.GoToRecord(Row);
    end;

    [TryFunction]
    local procedure TrySetDec(var P: TestPage "LT AN Card"; V: Decimal)
    begin
        P.DecVar.SetValue(V);
    end;

    [TryFunction]
    local procedure TrySetDate(var P: TestPage "LT AN Card"; V: Text)
    begin
        P.DateVar.SetValue(V);
    end;

    [TryFunction]
    local procedure TrySetDur(var P: TestPage "LT AN Card"; V: Text)
    begin
        P.DurVar.SetValue(V);
    end;

    // ---- item 1: Decimal with more than two decimals outside the bounds of a page variable control (MinValue 2, MaxValue 5) ----

    local procedure Dec(var Observer: Codeunit "Probe Observer"; var P: TestPage "LT AN Card"; Name: Text; V: Decimal)
    begin
        P.DecVar.SetValue(3);
        if TrySetDec(P, V) then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
        Observer.Observe(Name + '.after', P.DecVar.Value());
    end;

    [Test]
    procedure An01_DecimalBounds_MoreThanTwoDecimals()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AN Card";
    begin
        Seed();
        OpenCard(P);
        Dec(Observer, P, 'below1.234', 1.234);
        Dec(Observer, P, 'below1.996', 1.996);
        Dec(Observer, P, 'above5.004', 5.004);
        Dec(Observer, P, 'above5.006', 5.006);
        Dec(Observer, P, 'inside3.456', 3.456);
        P.Close();
        Observer.Finish();
    end;

    // ---- item 2: how the part's rows are read when the host opens ----

    local procedure RunHost(PageId: Integer; HostCode: Code[20])
    var
        Row: Record "LT AN Row";
    begin
        Row.Get(HostCode);
        Page.Run(PageId, Row);
    end;

    [Test]
    procedure An02_Part_ConstLink_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AN Log";
        Host: TestPage "LT AN Host Const One";
    begin
        Seed();
        Log.Take();
        Host.Trap();
        RunHost(Page::"LT AN Host Const One", 'ONE');
        Observer.Observe('open', Log.Take());
        Observer.Observe('partRow', Host.Lines."Line No.".Value());
        Host.Close();
        Observer.Observe('close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure An02_Part_ConstLink_FiveRows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AN Log";
        Host: TestPage "LT AN Host Const Five";
    begin
        Seed();
        Log.Take();
        Host.Trap();
        RunHost(Page::"LT AN Host Const Five", 'ONE');
        Observer.Observe('open', Log.Take());
        Observer.Observe('partRow', Host.Lines."Line No.".Value());
        Host.Close();
        Observer.Observe('close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure An02_Part_FieldLink_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AN Log";
        Host: TestPage "LT AN Host Field";
    begin
        Seed();
        Log.Take();
        Host.Trap();
        RunHost(Page::"LT AN Host Field", 'ONE');
        Observer.Observe('open', Log.Take());
        Observer.Observe('partRow', Host.Lines."Line No.".Value());
        Host.Close();
        Observer.Observe('close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure An02_Part_FieldLink_FiveRows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AN Log";
        Host: TestPage "LT AN Host Field";
    begin
        Seed();
        Log.Take();
        Host.Trap();
        RunHost(Page::"LT AN Host Field", 'FIVE');
        Observer.Observe('open', Log.Take());
        Observer.Observe('partRow', Host.Lines."Line No.".Value());
        Host.Close();
        Observer.Observe('close', Log.Take());
        Observer.Finish();
    end;

    // ---- item 8: Date control SetValue of the date shorthands, WorkDate 5 March 2026 ----

    local procedure DateShort(var Observer: Codeunit "Probe Observer"; var P: TestPage "LT AN Card"; V: Text)
    var
        D: Date;
    begin
        P.DateVar.SetValue(DMY2Date(1, 1, 2020));
        if not TrySetDate(P, V) then begin
            Observer.ObserveError('[' + V + ']');
            Observer.Observe('[' + V + '].after', P.DateVar.Value());
            exit;
        end;
        D := P.DateVar.AsDate();
        // Today is not asserted as a date (the run date changes); the probe records whether the control holds Today.
        if D = Today() then
            Observer.Observe('[' + V + ']', 'Today')
        else
            Observer.Observe('[' + V + ']', Format(D, 0, 9) + ' shows=' + P.DateVar.Value());
    end;

    [Test]
    procedure An08_DateShorthands()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AN Card";
        Saved: Date;
    begin
        Seed();
        Saved := WorkDate();
        WorkDate(DMY2Date(5, 3, 2026));
        OpenCard(P);
        DateShort(Observer, P, 't');
        DateShort(Observer, P, 'T');
        DateShort(Observer, P, 'today');
        DateShort(Observer, P, 'TODAY');
        DateShort(Observer, P, 'workdate');
        DateShort(Observer, P, 'w');
        DateShort(Observer, P, 'W');
        P.Close();
        WorkDate(Saved);
        Observer.Finish();
    end;

    // ---- item 10: Clear of a TestPage over a part page ----

    [TryFunction]
    local procedure TryClearPart(var TP: TestPage "LT AN Part")
    begin
        Clear(TP);
    end;

    [TryFunction]
    local procedure TryOpenEditPart(var TP: TestPage "LT AN Part")
    begin
        TP.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenViewPart(var TP: TestPage "LT AN Part")
    begin
        TP.OpenView();
    end;

    [TryFunction]
    local procedure TryClosePart(var TP: TestPage "LT AN Part")
    begin
        TP.Close();
    end;

    local procedure Step(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    var
        Log: Codeunit "LT AN Log";
    begin
        if Ok then
            Observer.Observe(Name, 'ok log=' + Log.Take())
        else begin
            Observer.ObserveError(Name);
            Observer.Observe(Name + '.log', Log.Take());
        end;
    end;

    [Test]
    procedure An10_ClearPartTestPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AN Log";
        TP: TestPage "LT AN Part";
    begin
        Seed();
        Log.Take();
        Step(Observer, 'clearNeverOpened', TryClearPart(TP));
        Step(Observer, 'openView', TryOpenViewPart(TP));
        Step(Observer, 'clearOpen', TryClearPart(TP));
        Step(Observer, 'closeAfterClearOpen', TryClosePart(TP));
        Step(Observer, 'openEditAfterClearOpen', TryOpenEditPart(TP));
        Step(Observer, 'close', TryClosePart(TP));
        Step(Observer, 'clearClosed', TryClearPart(TP));
        Step(Observer, 'openEditAfterClearClosed', TryOpenEditPart(TP));
        Step(Observer, 'closeAgain', TryClosePart(TP));
        Observer.Finish();
    end;

    // ---- item 11: an action deletes the current row of a list with OnFindRecord / OnNextRecord ----

    local procedure SeedList(Codes: List of [Code[20]])
    var
        Row: Record "LT AN Row";
        C: Code[20];
    begin
        Row.DeleteAll();
        foreach C in Codes do begin
            Row."Code" := C;
            Row.Insert();
        end;
    end;

    local procedure DeleteAt(var Observer: Codeunit "Probe Observer"; Target: Code[20])
    var
        Log: Codeunit "LT AN Log";
        Row: Record "LT AN Row";
        P: TestPage "LT AN Find List";
    begin
        Log.Take();
        P.OpenEdit();
        Observer.Observe('open', Log.Take());
        P.GoToKey(Target);
        Observer.Observe('goto', Log.Take());
        P.DeleteCurrent.Invoke();
        Observer.Observe('delete', Log.Take());
        Observer.Observe('cursor', P."Code".Value());
        Observer.Observe('stored', Format(Row.Get(Target)));
        Observer.Observe('count', Format(Row.Count()));
        if P.Next() then
            Observer.Observe('next', 'Yes ' + P."Code".Value())
        else
            Observer.Observe('next', 'No ' + P."Code".Value());
        Observer.Observe('nextLog', Log.Take());
        P.Close();
        Observer.Observe('closeLog', Log.Take());
    end;

    [Test]
    procedure An11_DeleteMiddleRow()
    var
        Observer: Codeunit "Probe Observer";
        Codes: List of [Code[20]];
    begin
        Codes.AddRange('A', 'B', 'C', 'D', 'E');
        SeedList(Codes);
        DeleteAt(Observer, 'C');
        Observer.Finish();
    end;

    [Test]
    procedure An11_DeleteOnlyRow()
    var
        Observer: Codeunit "Probe Observer";
        Codes: List of [Code[20]];
    begin
        Codes.Add('A');
        SeedList(Codes);
        DeleteAt(Observer, 'A');
        Observer.Finish();
    end;

    [Test]
    procedure An11_DeleteInLongView()
    var
        Observer: Codeunit "Probe Observer";
        Codes: List of [Code[20]];
        i: Integer;
    begin
        for i := 1 to 60 do
            Codes.Add('R' + Format(i, 0, '<Integer,2><Filler Character,0>'));
        SeedList(Codes);
        DeleteAt(Observer, 'R30');
        Observer.Finish();
    end;

    // ---- item 14: TableRelation lookup (no triggers), blank field and a field with a value ----

    [ModalPageHandler]
    procedure RelatedPick(var Modal: TestPage "LT AN Related List")
    begin
        LookupStart := Modal."Code".Value();
        Modal.GoToKey(LookupPick);
        Modal.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('RelatedPick')]
    procedure An14_RelationLookup_BlankField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AN Row";
        P: TestPage "LT AN Card";
    begin
        Seed();
        OpenCard(P);
        LookupStart := '<handler not run>';
        LookupPick := 'R3';
        P.Rel.Lookup();
        Observer.Observe('startRow', LookupStart);
        Observer.Observe('after', P.Rel.Value());
        P.Close();
        Row.Get('ONE');
        Observer.Observe('stored', Row.Rel);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RelatedPick')]
    procedure An14_RelationLookup_FieldWithValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AN Row";
        P: TestPage "LT AN Card";
    begin
        Seed();
        Row.Get('ONE');
        Row.Rel := 'R2';
        Row.Modify();
        OpenCard(P);
        LookupStart := '<handler not run>';
        LookupPick := 'R4';
        P.Rel.Lookup();
        Observer.Observe('startRow', LookupStart);
        Observer.Observe('after', P.Rel.Value());
        P.Close();
        Row.Get('ONE');
        Observer.Observe('stored', Row.Rel);
        Observer.Finish();
    end;

    // ---- item 15: Lookup on a relation to a table with no LookupPageId / DrillDownPageId and no handler ----

    [Test]
    procedure An15_RelationLookup_NoPage_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
        Pageless: Record "LT AN Pageless";
        Related: Record "LT AN Related";
        P: TestPage "LT AN Card";
    begin
        Seed();
        Commit();
        Pageless."Code" := 'PL-UNCOMMITTED';
        Pageless.Insert();
        Related."Code" := 'R-UNCOMMITTED';
        Related.Insert();
        OpenCard(P);
        P.NoPg.SetValue('PL-A');
        asserterror P.NoPg.Lookup();
        Observer.ObserveError('lookup');
        Observer.Observe('value', P.NoPg.Value());
        P.Close();
        Observer.Observe('pagelessRowSurvives', Format(Pageless.Get('PL-UNCOMMITTED')));
        Observer.Observe('relatedRowSurvives', Format(Related.Get('R-UNCOMMITTED')));
        Observer.Finish();
    end;

    // ---- item 16: Duration control SetValue ----

    local procedure Dur(var Observer: Codeunit "Probe Observer"; var P: TestPage "LT AN Card"; Name: Text; V: Text)
    begin
        P.DurVar.SetValue('2 hours');
        if TrySetDur(P, V) then
            Observer.Observe(Name, 'in=[' + V + '] shows=[' + P.DurVar.Value() + ']')
        else begin
            Observer.ObserveError(Name);
            Observer.Observe(Name + '.after', P.DurVar.Value());
        end;
    end;

    [Test]
    procedure An16_DurationSpellings()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AN Card";
    begin
        Seed();
        OpenCard(P);
        Dur(Observer, P, 'dash', '-');
        Dur(Observer, P, 'commaHours', '1,5 hours');
        Dur(Observer, P, 'commaOnly', '1,5');
        P.Close();
        Observer.Finish();
    end;

    // ---- item 19: CaptionClass 'X,Y' (non-numeric area, no subscriber) on a table field ----

    [Test]
    procedure An19_TableFieldCaptionClass_NonNumericArea()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AN Row";
        RecRef: RecordRef;
        P: TestPage "LT AN Card";
    begin
        Seed();
        Observer.Observe('fieldCaption', Row.FieldCaption(Cap));
        RecRef.Open(Database::"LT AN Row");
        Observer.Observe('fieldRefCaption', RecRef.Field(5).Caption());
        OpenCard(P);
        Observer.Observe('testPageCaption', P.Cap.Caption());
        P.Close();
        Observer.Finish();
    end;
}
