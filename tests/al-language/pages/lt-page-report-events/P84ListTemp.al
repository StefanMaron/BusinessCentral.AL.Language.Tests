// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 73036, list pages 73054-73055, test codeunit 73056
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: list page opened over a temporary record (Page.RunModal / Page.Run) or a real record: is there a blank new-row line after the last row (Next count, last row values)
// BC versions: 29 (27 and 28 by CI)

page 73054 "LT P84 Row List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT P84 Row";
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id)
                {
                    ApplicationArea = All;
                }
                field(NameF; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

page 73055 "LT P84 Row List RO"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT P84 Row";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id)
                {
                    ApplicationArea = All;
                }
                field(NameF; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

codeunit 73056 "LT P84 List Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Tag: Text;

    local procedure Seed(RowCount: Integer)
    var
        Row: Record "LT P84 Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to RowCount do begin
            Row.Init();
            Row.Id := i * 10;
            Row.Name := 'Row' + Format(i);
            Row.Insert();
        end;
    end;

    local procedure SeedTemp(var Temp: Record "LT P84 Row" temporary; RowCount: Integer)
    var
        i: Integer;
    begin
        Temp.Reset();
        Temp.DeleteAll();
        for i := 1 to RowCount do begin
            Temp.Init();
            Temp.Id := i * 10;
            Temp.Name := 'Row' + Format(i);
            Temp.Insert();
        end;
    end;

    local procedure Walk(var P: TestPage "LT P84 Row List")
    var
        Cnt: Integer;
        Ids: Text;
        Names: Text;
    begin
        if P.First() then
            repeat
                Cnt += 1;
                Ids += P.IdF.Value() + ',';
                Names += P.NameF.Value() + ',';
            until not P.Next();
        Observer.Observe(Tag + '_count', Format(Cnt));
        Observer.Observe(Tag + '_ids', Ids);
        Observer.Observe(Tag + '_names', Names);
        Observer.Observe(Tag + '_next_after_end', Format(P.Next()));
        Observer.Observe(Tag + '_last_id', P.IdF.Value());
        Observer.Observe(Tag + '_last_name', P.NameF.Value());
    end;

    local procedure WalkRO(var P: TestPage "LT P84 Row List RO")
    var
        Cnt: Integer;
        Ids: Text;
    begin
        if P.First() then
            repeat
                Cnt += 1;
                Ids += P.IdF.Value() + ',';
            until not P.Next();
        Observer.Observe(Tag + '_count', Format(Cnt));
        Observer.Observe(Tag + '_ids', Ids);
        Observer.Observe(Tag + '_next_after_end', Format(P.Next()));
        Observer.Observe(Tag + '_last_id', P.IdF.Value());
    end;

    [ModalPageHandler]
    procedure ListHandler(var P: TestPage "LT P84 Row List")
    begin
        Walk(P);
    end;

    [ModalPageHandler]
    procedure ListROHandler(var P: TestPage "LT P84 Row List RO")
    begin
        WalkRO(P);
    end;

    [PageHandler]
    procedure ListModelessHandler(var P: TestPage "LT P84 Row List")
    begin
        Walk(P);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_Temp_ThreeRows()
    var
        Temp: Record "LT P84 Row" temporary;
    begin
        SeedTemp(Temp, 3);
        Tag := 'temp3';
        Page.RunModal(Page::"LT P84 Row List", Temp);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_Temp_OneRow()
    var
        Temp: Record "LT P84 Row" temporary;
    begin
        SeedTemp(Temp, 1);
        Tag := 'temp1';
        Page.RunModal(Page::"LT P84 Row List", Temp);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_Temp_NoRows()
    var
        Temp: Record "LT P84 Row" temporary;
    begin
        SeedTemp(Temp, 0);
        Tag := 'temp0';
        Page.RunModal(Page::"LT P84 Row List", Temp);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_Real_ThreeRows()
    var
        Row: Record "LT P84 Row";
    begin
        Seed(3);
        Tag := 'real3';
        Page.RunModal(Page::"LT P84 Row List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_Real_OneRow()
    var
        Row: Record "LT P84 Row";
    begin
        Seed(1);
        Tag := 'real1';
        Page.RunModal(Page::"LT P84 Row List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_Real_NoRows()
    var
        Row: Record "LT P84 Row";
    begin
        Seed(0);
        Tag := 'real0';
        Page.RunModal(Page::"LT P84 Row List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListROHandler')]
    procedure RunModal_ReadOnlyList_Temp()
    var
        Temp: Record "LT P84 Row" temporary;
    begin
        SeedTemp(Temp, 3);
        Tag := 'ro_temp3';
        Page.RunModal(Page::"LT P84 Row List RO", Temp);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListROHandler')]
    procedure RunModal_ReadOnlyList_Real()
    var
        Row: Record "LT P84 Row";
    begin
        Seed(3);
        Tag := 'ro_real3';
        Page.RunModal(Page::"LT P84 Row List RO", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListModelessHandler')]
    procedure Run_Temp_ThreeRows()
    var
        Temp: Record "LT P84 Row" temporary;
    begin
        SeedTemp(Temp, 3);
        Tag := 'run_temp3';
        Page.Run(Page::"LT P84 Row List", Temp);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListModelessHandler')]
    procedure Run_Real_ThreeRows()
    var
        Row: Record "LT P84 Row";
    begin
        Seed(3);
        Tag := 'run_real3';
        Page.Run(Page::"LT P84 Row List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_Temp_Filtered()
    var
        Temp: Record "LT P84 Row" temporary;
    begin
        SeedTemp(Temp, 3);
        Temp.SetFilter(Id, '>=20');
        Tag := 'temp_filtered';
        Page.RunModal(Page::"LT P84 Row List", Temp);
        Observer.Finish();
    end;

    [Test]
    procedure TestPage_Real_OpenView()
    var
        P: TestPage "LT P84 Row List";
    begin
        Seed(3);
        Tag := 'tp_view3';
        P.OpenView();
        Walk(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TestPage_Real_OpenEdit()
    var
        P: TestPage "LT P84 Row List";
    begin
        Seed(3);
        Tag := 'tp_edit3';
        P.OpenEdit();
        Walk(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TestPage_Real_OpenNew()
    var
        P: TestPage "LT P84 Row List";
    begin
        Seed(3);
        Tag := 'tp_new3';
        P.OpenNew();
        Walk(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TestPage_Real_OpenEdit_Empty()
    var
        P: TestPage "LT P84 Row List";
    begin
        Seed(0);
        Tag := 'tp_edit0';
        P.OpenEdit();
        Walk(P);
        P.Close();
        Observer.Finish();
    end;
}
