// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 84420-84435 (CfPageObjects.al), test codeunit 84439
// Probe: written against BC on CI; every literal asserted below is what BC produced. Corpus issue 667 items 81, 85, 86, 88, 89, 90.
// Facts:
//   81: an API page whose OnInsertRecord runs Rec.Insert(true) and answers false (or true), driven by a TestPage: OpenNew, set the key and a field, Close.
//   85: a card whose OnNewRecord runs Rec.Insert(true) when "No." is blank: when the row reaches the database with TestPage OpenNew.
//   86: a FlowFilter field as a list column (page and page extension) compiles; what the TestPage shows.
//   88: a FlowField (lookup) used in a TableRelation filter and calculated in OnAfterGetCurrRecord: its value on OpenEdit, GoToRecord and OpenNew,
//       what SetValue accepts and which filter the Lookup page gets.
//   89: TestPage SetValue on an editable FlowField (Sum): which triggers run and whether a row is written.
//   90: a FlowFilter set by assignment or Validate in code, and by SetValue on a card: whether CalcFields uses it.
// BC versions: 27, 28, 29 by CI

codeunit 84439 "LT CF Page Leads"
{
    Subtype = Test;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT CF P Log";
        LookupSeen: Text;

    local procedure ApiRows(): Text
    var
        Row: Record "LT CF P Api Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += StrSubstNo('[%1/%2]', Row.Id, Row.Name);
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure DocRows(): Text
    var
        Doc: Record "LT CF P Doc";
        Result: Text;
    begin
        if Doc.FindSet() then
            repeat
                Result += StrSubstNo('[%1/%2]', Doc."No.", Doc.Description);
            until Doc.Next() = 0;
        exit(Result);
    end;

    local procedure EntryRows(): Text
    var
        Entry: Record "LT CF P Entry";
        Result: Text;
    begin
        if Entry.FindSet() then
            repeat
                Result += StrSubstNo('[%1/%2/%3]', Entry."Entry No.", Entry."Code", Entry.Amount);
            until Entry.Next() = 0;
        exit(Result);
    end;

    local procedure SeedRow()
    var
        Row: Record "LT CF P Row";
        Entry: Record "LT CF P Entry";
    begin
        Row.DeleteAll();
        Entry.DeleteAll();
        Row."Code" := 'R1';
        Row.Val := 'first';
        Row.Insert();
        Entry."Entry No." := 1;
        Entry."Code" := 'R1';
        Entry."Posting Date" := DMY2Date(10, 1, 2024);
        Entry.Amount := 10;
        Entry.Insert();
        Entry."Entry No." := 2;
        Entry."Code" := 'R1';
        Entry."Posting Date" := DMY2Date(10, 2, 2024);
        Entry.Amount := 20;
        Entry.Insert();
        Log.Reset();
    end;

    local procedure SeedLines()
    var
        Hdr: Record "LT CF P Hdr";
        Line: Record "LT CF P Line";
        Item: Record "LT CF P Item";
    begin
        Hdr.DeleteAll();
        Line.DeleteAll();
        Item.DeleteAll();
        Hdr."No." := 'H1';
        Hdr.Vendor := 'V1';
        Hdr.Insert();
        Item."Code" := 'I1';
        Item.Vendor := 'V1';
        Item.Insert();
        Item."Code" := 'I2';
        Item.Vendor := 'V2';
        Item.Insert();
        Line."Doc No." := 'H1';
        Line."Line No." := 10000;
        Line.Insert();
    end;

    // ---------- item 81 ----------

    [TryFunction]
    local procedure TryApiFalseSet(var P: TestPage "LT CF P Api False"; Id: Integer; Name: Text)
    begin
        P.id.SetValue(Id);
        P.name.SetValue(Name);
    end;

    [TryFunction]
    local procedure TryApiFalseClose(var P: TestPage "LT CF P Api False")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryApiTrueSet(var P: TestPage "LT CF P Api True"; Id: Integer; Name: Text)
    begin
        P.id.SetValue(Id);
        P.name.SetValue(Name);
    end;

    [TryFunction]
    local procedure TryApiTrueClose(var P: TestPage "LT CF P Api True")
    begin
        P.Close();
    end;

    [Test]
    procedure ApiPage_OnInsertRecordInsertsAndReturnsFalse()
    var
        Row: Record "LT CF P Api Row";
        P: TestPage "LT CF P Api False";
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        P.OpenNew();
        Observer.Observe('set ok', Format(TryApiFalseSet(P, 1, 'One')));
        Observer.ObserveError('set');
        Observer.Observe('after set log', Log.Text());
        Observer.Observe('after set rows', ApiRows());
        Observer.Observe('close ok', Format(TryApiFalseClose(P)));
        Observer.ObserveError('close');
        Observer.Observe('after close log', Log.Text());
        Observer.Observe('after close rows', ApiRows());
        Observer.Finish();
    end;

    [Test]
    procedure ApiPage_OnInsertRecordInsertsAndReturnsTrue()
    var
        Row: Record "LT CF P Api Row";
        P: TestPage "LT CF P Api True";
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        P.OpenNew();
        Observer.Observe('set ok', Format(TryApiTrueSet(P, 2, 'Two')));
        Observer.ObserveError('set');
        Observer.Observe('after set log', Log.Text());
        Observer.Observe('after set rows', ApiRows());
        Observer.Observe('close ok', Format(TryApiTrueClose(P)));
        Observer.ObserveError('close');
        Observer.Observe('after close log', Log.Text());
        Observer.Observe('after close rows', ApiRows());
        Observer.Finish();
    end;

    // ---------- item 85 ----------

    [TryFunction]
    local procedure TryOpenNewCard(var P: TestPage "LT CF P New Card")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TrySetDescription(var P: TestPage "LT CF P New Card"; Value: Text)
    begin
        P.Description.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryCloseNewCard(var P: TestPage "LT CF P New Card")
    begin
        P.Close();
    end;

    [Test]
    procedure Card_OnNewRecordInserts_OpenNewSetClose()
    var
        Doc: Record "LT CF P Doc";
        P: TestPage "LT CF P New Card";
    begin
        Doc.DeleteAll();
        Log.Reset();
        ClearLastError();
        Observer.Observe('open ok', Format(TryOpenNewCard(P)));
        Observer.ObserveError('open');
        Observer.Observe('after open log', Log.Text());
        Observer.Observe('after open rows', DocRows());
        Observer.Observe('after open no', P."No.".Value());
        Observer.Observe('set ok', Format(TrySetDescription(P, 'Hello')));
        Observer.ObserveError('set');
        Observer.Observe('after set log', Log.Text());
        Observer.Observe('after set rows', DocRows());
        Observer.Observe('close ok', Format(TryCloseNewCard(P)));
        Observer.ObserveError('close');
        Observer.Observe('after close log', Log.Text());
        Observer.Observe('after close rows', DocRows());
        Observer.Finish();
    end;

    // ---------- item 86 ----------

    [Test]
    procedure List_FlowFilterColumn_PageAndExtension()
    var
        Row: Record "LT CF P Row";
        P: TestPage "LT CF P FlowFilter List";
    begin
        SeedRow();
        P.OpenView();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('code', P."Code".Value());
        Observer.Observe('date filter', P.DateFilter.Value());
        Observer.Observe('ext date filter', P.ExtDateFilter.Value());
        Observer.Observe('amount', P.Amount.Value());
        Observer.Observe('date filter editable', Format(P.DateFilter.Editable()));
        Observer.Observe('date filter visible', Format(P.DateFilter.Visible()));
        P.Close();
        Row.SetRange("Date Filter", DMY2Date(10, 1, 2024));
        P.Trap();
        Page.Run(Page::"LT CF P FlowFilter List", Row);
        Observer.Observe('filtered first', Format(P.First()));
        Observer.Observe('filtered date filter', P.DateFilter.Value());
        Observer.Observe('filtered ext date filter', P.ExtDateFilter.Value());
        Observer.Observe('filtered amount', P.Amount.Value());
        Observer.Observe('filtered page filter', P.Filter.GetFilter("Date Filter"));
        P.Close();
        Observer.Finish();
    end;

    // ---------- item 88 ----------

    [TryFunction]
    local procedure TrySetItem(var P: TestPage "LT CF P Line Card"; Value: Text)
    begin
        P.Item.SetValue(Value);
    end;

    [Test]
    procedure FlowFieldRelation_OpenEditGoToRecord()
    var
        Line: Record "LT CF P Line";
        P: TestPage "LT CF P Line Card";
    begin
        SeedLines();
        ClearLastError();
        P.OpenEdit();
        Observer.Observe('open doc', P."Doc No.".Value());
        Observer.Observe('open vendor', P.HdrVendor.Value());
        Line.Get('H1', 10000);
        P.GoToRecord(Line);
        Observer.Observe('goto vendor', P.HdrVendor.Value());
        Observer.Observe('set other vendor item ok', Format(TrySetItem(P, 'I2')));
        Observer.ObserveError('set other vendor item');
        Observer.Observe('set same vendor item ok', Format(TrySetItem(P, 'I1')));
        Observer.ObserveError('set same vendor item');
        Observer.Observe('item value', P.Item.Value());
        P.Close();
        Line.Get('H1', 10000);
        Observer.Observe('db item', Line.Item);
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldRelation_OpenNew()
    var
        Line: Record "LT CF P Line";
        P: TestPage "LT CF P Line Card";
    begin
        SeedLines();
        ClearLastError();
        P.OpenNew();
        Observer.Observe('new vendor', P.HdrVendor.Value());
        P."Doc No.".SetValue('H1');
        P."Line No.".SetValue(20000);
        Observer.Observe('after key vendor', P.HdrVendor.Value());
        Observer.Observe('set other vendor item ok', Format(TrySetItem(P, 'I2')));
        Observer.ObserveError('set other vendor item');
        Observer.Observe('set same vendor item ok', Format(TrySetItem(P, 'I1')));
        Observer.ObserveError('set same vendor item');
        Observer.Observe('item value', P.Item.Value());
        P.Close();
        Observer.Observe('db exists', Format(Line.Get('H1', 20000)));
        Observer.Observe('db item', Line.Item);
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure ItemLookupHandler(var L: TestPage "LT CF P Item List")
    var
        Codes: Text;
    begin
        if L.First() then
            repeat
                Codes += '[' + L."Code".Value() + ']';
            until not L.Next();
        LookupSeen := StrSubstNo('filter=%1 rows=%2', L.Filter.GetFilter(Vendor), Codes);
        L.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemLookupHandler')]
    procedure FlowFieldRelation_LookupFilter()
    var
        Line: Record "LT CF P Line";
        P: TestPage "LT CF P Line Card";
    begin
        SeedLines();
        LookupSeen := '';
        P.OpenEdit();
        Line.Get('H1', 10000);
        P.GoToRecord(Line);
        P.Item.Lookup();
        Observer.Observe('lookup', LookupSeen);
        P.Close();
        Observer.Finish();
    end;

    // ---------- item 89 ----------

    [TryFunction]
    local procedure TrySetAmount(var P: TestPage "LT CF P Row Card"; Value: Decimal)
    begin
        P.Amount.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryCloseRowCard(var P: TestPage "LT CF P Row Card")
    begin
        P.Close();
    end;

    [Test]
    procedure EditableFlowField_SetValue()
    var
        Row: Record "LT CF P Row";
        P: TestPage "LT CF P Row Card";
    begin
        SeedRow();
        ClearLastError();
        P.OpenEdit();
        Row.Get('R1');
        P.GoToRecord(Row);
        Observer.Observe('amount', P.Amount.Value());
        Observer.Observe('amount editable', Format(P.Amount.Editable()));
        Log.Reset();
        Observer.Observe('set ok', Format(TrySetAmount(P, 50)));
        Observer.ObserveError('set');
        Observer.Observe('after set log', Log.Text());
        Observer.Observe('after set amount', P.Amount.Value());
        Observer.Observe('after set entries', EntryRows());
        Observer.Observe('close ok', Format(TryCloseRowCard(P)));
        Observer.ObserveError('close');
        Observer.Observe('after close log', Log.Text());
        Observer.Observe('after close entries', EntryRows());
        Row.Get('R1');
        Row.CalcFields(Amount);
        Observer.Observe('db amount', Format(Row.Amount));
        Observer.Finish();
    end;

    // ---------- item 90 ----------

    [Test]
    procedure FlowFilter_AssignValidateSetRange_InCode()
    var
        Row: Record "LT CF P Row";
    begin
        SeedRow();
        Row.Get('R1');
        Row.CalcFields(Amount);
        Observer.Observe('no filter amount', Format(Row.Amount));
        Row."Date Filter" := DMY2Date(10, 1, 2024);
        Observer.Observe('assigned value', Format(Row."Date Filter", 0, 9));
        Observer.Observe('assigned getfilter', Row.GetFilter("Date Filter"));
        Row.CalcFields(Amount);
        Observer.Observe('assigned amount', Format(Row.Amount));
        Clear(Row);
        Row.Get('R1');
        Log.Reset();
        Row.Validate("Date Filter", DMY2Date(10, 2, 2024));
        Observer.Observe('validated log', Log.Text());
        Observer.Observe('validated value', Format(Row."Date Filter", 0, 9));
        Observer.Observe('validated getfilter', Row.GetFilter("Date Filter"));
        Row.CalcFields(Amount);
        Observer.Observe('validated amount', Format(Row.Amount));
        Clear(Row);
        Row.Get('R1');
        Row.SetRange("Date Filter", DMY2Date(10, 2, 2024));
        Observer.Observe('setrange value', Format(Row."Date Filter", 0, 9));
        Row.CalcFields(Amount);
        Observer.Observe('setrange amount', Format(Row.Amount));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySetDateFilter(var P: TestPage "LT CF P Row Card"; Value: Date)
    begin
        P.DateFilter.SetValue(Value);
    end;

    [Test]
    procedure FlowFilter_SetValueOnCard()
    var
        Row: Record "LT CF P Row";
        P: TestPage "LT CF P Row Card";
    begin
        SeedRow();
        ClearLastError();
        P.OpenEdit();
        Row.Get('R1');
        P.GoToRecord(Row);
        Observer.Observe('amount', P.Amount.Value());
        Observer.Observe('date filter editable', Format(P.DateFilter.Editable()));
        Log.Reset();
        Observer.Observe('set ok', Format(TrySetDateFilter(P, DMY2Date(10, 1, 2024))));
        Observer.ObserveError('set');
        Observer.Observe('after set log', Log.Text());
        Observer.Observe('after set date filter', P.DateFilter.Value());
        Observer.Observe('after set amount', P.Amount.Value());
        Observer.Observe('after set page filter', P.Filter.GetFilter("Date Filter"));
        P.Close();
        Observer.Finish();
    end;
}
