// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT P145 Row (74920), LT P145 Log Mgt (74922), LT P145 List B (74924)
// Probe: Page.Run(Page, Rec) on a page whose SourceTableView has ORDER: sorting(Grp, Qty) order(descending) where(Qty = filter('>=2')). With no record, an empty record, a record with SetCurrentKey(Grp, Qty) and Ascending(true), a record with SetCurrentKey(Grp, Qty) and Ascending(false), and a record with its own Qty filter: filters, current key, direction and view seen in OnOpenPage, and the rows a TestPage handler reads in order.
// Object id 67097.

codeunit 67097 "LT F3 P145 Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P145 Row";
        Data: List of [Text];
        Item: Text;
        Parts: List of [Text];
        Qty: Integer;
    begin
        Row.DeleteAll();
        Data.Add('R1;A;3');
        Data.Add('R2;A;1');
        Data.Add('R3;B;2');
        Data.Add('R4;B;5');
        Data.Add('R5;C;4');
        Data.Add('R6;A;6');
        foreach Item in Data do begin
            Parts := Item.Split(';');
            Evaluate(Qty, Parts.Get(3));
            Row.Init();
            Row."No." := CopyStr(Parts.Get(1), 1, 20);
            Row.Grp := CopyStr(Parts.Get(2), 1, 10);
            Row.Qty := Qty;
            Row.Insert();
        end;
    end;

    [PageHandler]
    procedure ListBHandler(var P: TestPage "LT P145 List B")
    var
        Log: Codeunit "LT P145 Log Mgt";
        Rows: Text;
        More: Boolean;
    begin
        More := P.First();
        while More do begin
            Rows += P.NoCtl.Value() + ',';
            More := P.Next();
        end;
        Log.Add('B rows=' + Rows);
    end;

    [Test]
    [HandlerFunctions('ListBHandler')]
    procedure B_NoRecordArgument()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P145 Log Mgt";
    begin
        Seed();
        Log.Clear();
        Page.Run(Page::"LT P145 List B");
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListBHandler')]
    procedure B_EmptyRecord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P145 Log Mgt";
        Row: Record "LT P145 Row";
    begin
        Seed();
        Log.Clear();
        Page.Run(Page::"LT P145 List B", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListBHandler')]
    procedure B_RecKeyGrpQtyAscending()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P145 Log Mgt";
        Row: Record "LT P145 Row";
    begin
        Seed();
        Log.Clear();
        Row.SetCurrentKey(Grp, Qty);
        Row.Ascending(true);
        Page.Run(Page::"LT P145 List B", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListBHandler')]
    procedure B_RecKeyGrpQtyDescending()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P145 Log Mgt";
        Row: Record "LT P145 Row";
    begin
        Seed();
        Log.Clear();
        Row.SetCurrentKey(Grp, Qty);
        Row.Ascending(false);
        Page.Run(Page::"LT P145 List B", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListBHandler')]
    procedure B_RecOwnQtyFilter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P145 Log Mgt";
        Row: Record "LT P145 Row";
    begin
        Seed();
        Log.Clear();
        Row.SetFilter(Qty, '>=4');
        Page.Run(Page::"LT P145 List B", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListBHandler')]
    procedure B_RecKeyQtyOnly()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P145 Log Mgt";
        Row: Record "LT P145 Row";
    begin
        Seed();
        Log.Clear();
        Row.SetCurrentKey(Qty);
        Page.Run(Page::"LT P145 List B", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;
}
