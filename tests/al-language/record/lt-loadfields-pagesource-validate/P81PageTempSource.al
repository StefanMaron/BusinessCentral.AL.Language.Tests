// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 70307, pages 70308 and 70309, codeunit 70310
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: running a page with a temporary record as source (Page.RunModal(Id, TempRec), Page.Run(Id, TempRec), SetTableView, SetRecord): which rows the page shows and what it writes back to the temporary record and to the table
// BC versions: 29 (27 and 28 by CI)

table 70307 "LT P81 PG Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

page 70308 "LT P81 PG List"
{
    PageType = List;
    SourceTable = "LT P81 PG Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { }
                field(Name; Rec.Name) { }
                field(Qty; Rec.Qty) { }
            }
        }
    }
}

page 70309 "LT P81 PG TempList"
{
    PageType = List;
    SourceTable = "LT P81 PG Row";
    SourceTableTemporary = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { }
                field(Name; Rec.Name) { }
                field(Qty; Rec.Qty) { }
            }
        }
    }
}

codeunit 70310 "LT P81 Page Temp Source"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed(var Temp: Record "LT P81 PG Row" temporary)
    var
        Row: Record "LT P81 PG Row";
    begin
        Row.DeleteAll();
        Row.Code := 'D1';
        Row.Name := 'db-one';
        Row.Qty := 10;
        Row.Insert();
        Row.Code := 'D2';
        Row.Name := 'db-two';
        Row.Qty := 20;
        Row.Insert();
        Temp.DeleteAll();
        Temp.Code := 'T1';
        Temp.Name := 'temp-one';
        Temp.Qty := 1;
        Temp.Insert();
        Temp.Code := 'T2';
        Temp.Name := 'temp-two';
        Temp.Qty := 2;
        Temp.Insert();
        Temp.Code := 'T3';
        Temp.Name := 'temp-three';
        Temp.Qty := 3;
        Temp.Insert();
        Temp.FindFirst();
    end;

    local procedure ObserveRows(var P: TestPage "LT P81 PG List"; Prefix: Text)
    var
        n: Integer;
    begin
        if P.First() then
            repeat
                n += 1;
                Observer.Observe(Prefix + '_row' + Format(n), P.Code.Value() + '|' + P.Name.Value() + '|' + P.Qty.Value());
            until not P.Next();
        Observer.Observe(Prefix + '_rows', Format(n));
    end;

    local procedure ObserveDb(Prefix: Text)
    var
        Row: Record "LT P81 PG Row";
    begin
        Observer.Observe(Prefix + '_db_count', Format(Row.Count()));
        Observer.Observe(Prefix + '_db_has_t1', Format(Row.Get('T1')));
    end;

    [ModalPageHandler]
    procedure ReadRowsHandler(var P: TestPage "LT P81 PG List")
    begin
        ObserveRows(P, 'page');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditFirstHandler(var P: TestPage "LT P81 PG List")
    begin
        P.First();
        Observer.Observe('page_first_before', P.Code.Value() + '|' + P.Name.Value());
        P.Name.SetValue('edited');
        P.Qty.SetValue(42);
        ObserveRows(P, 'page');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewRowHandler(var P: TestPage "LT P81 PG List")
    begin
        P.New();
        P.Code.SetValue('N1');
        P.Name.SetValue('new-row');
        P.Qty.SetValue(5);
        ObserveRows(P, 'page');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelAfterEditHandler(var P: TestPage "LT P81 PG List")
    begin
        P.First();
        P.Name.SetValue('edited-cancel');
        P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure CurrentRowHandler(var P: TestPage "LT P81 PG List")
    begin
        Observer.Observe('page_current', P.Code.Value() + '|' + P.Name.Value());
        ObserveRows(P, 'page');
        P.OK().Invoke();
    end;

    [PageHandler]
    procedure NonModalHandler(var P: TestPage "LT P81 PG List")
    begin
        ObserveRows(P, 'page');
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure RunModal_TempRecord_ShowsTempRows()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Result: Action;
    begin
        Seed(Temp);
        Result := Page.RunModal(Page::"LT P81 PG List", Temp);
        Observer.Observe('result', Format(Result));
        Observer.Observe('temp_count', Format(Temp.Count()));
        ObserveDb('a');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('EditFirstHandler')]
    procedure RunModal_TempRecord_EditWritesToTemp()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Page.RunModal(Page::"LT P81 PG List", Temp);
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Observe('temp_t1_found', Format(Temp.Get('T1')));
        Observer.Observe('temp_t1_name', Temp.Name);
        Observer.Observe('temp_t1_qty', Format(Temp.Qty));
        Row.Get('D1');
        Observer.Observe('db_d1_name', Row.Name);
        ObserveDb('a');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('NewRowHandler')]
    procedure RunModal_TempRecord_NewRow()
    var
        Temp: Record "LT P81 PG Row" temporary;
    begin
        Seed(Temp);
        Page.RunModal(Page::"LT P81 PG List", Temp);
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Observe('temp_n1_found', Format(Temp.Get('N1')));
        Observer.Observe('temp_n1_name', Temp.Name);
        ObserveDb('a');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CancelAfterEditHandler')]
    procedure RunModal_TempRecord_CancelAfterEdit()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Result: Action;
    begin
        Seed(Temp);
        Result := Page.RunModal(Page::"LT P81 PG List", Temp);
        Observer.Observe('result', Format(Result));
        Observer.Observe('temp_t1_found', Format(Temp.Get('T1')));
        Observer.Observe('temp_t1_name', Temp.Name);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure RunModal_TempRecord_WithFilter()
    var
        Temp: Record "LT P81 PG Row" temporary;
    begin
        Seed(Temp);
        Temp.SetFilter(Qty, '>=2');
        Page.RunModal(Page::"LT P81 PG List", Temp);
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Observe('temp_filters', Temp.GetFilters());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure RunModal_NonTempRecord_ShowsDbRows()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Row.FindFirst();
        Page.RunModal(Page::"LT P81 PG List", Row);
        Observer.Observe('row_code', Row.Code);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PageVar_SetTableView_TempRecord()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Pg: Page "LT P81 PG List";
    begin
        Seed(Temp);
        Temp.SetRange(Qty, 2, 3);
        Pg.SetTableView(Temp);
        Pg.RunModal();
        Observer.Observe('temp_count', Format(Temp.Count()));
        ObserveDb('a');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PageVar_SetTableView_NonTempFilter()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
        Pg: Page "LT P81 PG List";
    begin
        Seed(Temp);
        Row.SetRange(Qty, 20);
        Pg.SetTableView(Row);
        Pg.RunModal();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CurrentRowHandler')]
    procedure PageVar_SetRecord_TempRecord()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Pg: Page "LT P81 PG List";
    begin
        Seed(Temp);
        Temp.Get('T2');
        Pg.SetRecord(Temp);
        Pg.RunModal();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CurrentRowHandler')]
    procedure PageVar_SetRecord_NonTempRecord()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
        Pg: Page "LT P81 PG List";
    begin
        Seed(Temp);
        Row.Get('D2');
        Pg.SetRecord(Row);
        Pg.RunModal();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CurrentRowHandler')]
    procedure PageVar_SetRecord_ThenSetTableView_Temp()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Pg: Page "LT P81 PG List";
    begin
        Seed(Temp);
        Temp.Get('T3');
        Pg.SetRecord(Temp);
        Temp.SetFilter(Qty, '<=2');
        Pg.SetTableView(Temp);
        Pg.RunModal();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('NonModalHandler')]
    procedure PageRun_TempRecord_NonModal()
    var
        Temp: Record "LT P81 PG Row" temporary;
    begin
        Seed(Temp);
        Page.Run(Page::"LT P81 PG List", Temp);
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure TempListHandler(var P: TestPage "LT P81 PG TempList")
    var
        n: Integer;
    begin
        if P.First() then
            repeat
                n += 1;
                Observer.Observe('page_row' + Format(n), P.Code.Value() + '|' + P.Name.Value());
            until not P.Next();
        Observer.Observe('page_rows', Format(n));
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure TempListNewHandler(var P: TestPage "LT P81 PG TempList")
    begin
        P.New();
        P.Code.SetValue('PN');
        P.Name.SetValue('page-new');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('TempListHandler')]
    procedure SourceTableTemporaryPage_ShowsNoDbRows()
    var
        Temp: Record "LT P81 PG Row" temporary;
    begin
        Seed(Temp);
        Page.RunModal(Page::"LT P81 PG TempList");
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TempListHandler')]
    procedure SourceTableTemporaryPage_GivenRecord()
    var
        Temp: Record "LT P81 PG Row" temporary;
    begin
        Seed(Temp);
        Page.RunModal(Page::"LT P81 PG TempList", Temp);
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TempListNewHandler')]
    procedure SourceTableTemporaryPage_NewRow_NotInDb()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Page.RunModal(Page::"LT P81 PG TempList");
        Observer.Observe('db_count', Format(Row.Count()));
        Observer.Observe('db_has_pn', Format(Row.Get('PN')));
        Observer.Observe('temp_has_pn', Format(Temp.Get('PN')));
        Observer.Finish();
    end;
}
