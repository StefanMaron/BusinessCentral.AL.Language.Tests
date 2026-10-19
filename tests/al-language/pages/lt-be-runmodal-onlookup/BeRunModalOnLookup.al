// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-integer-table-fieldref-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT BE Log (codeunit 81150); tables 81153-81154, pages 81154-81155, test codeunit 81162
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: Page.RunModal(PageId, Rec) on a plain list page (no Editable property) called from
//   (a) a table field's OnLookup trigger, reached through TestPage <field>.Lookup() on a list page opened with OpenEdit,
//   (b) the same, the list page opened with Trap + Page.Run(id, Rec) (the shape of Microsoft's T001_LookupItemUnitOfMeasure, codeunits 134123/134198),
//   (c) a page field's OnLookup trigger, reached through Lookup(),
//   (d) a page action's OnAction, reached through Invoke(),
//   (e) test code directly (only CurrPage.LookupMode and the action; the rows are pinned in handlers/TestPageModalNewRowLine_Tests.al).
//   The modal page records CurrPage.LookupMode in OnOpenPage. Its handler walks from First() until Next() answers false (one row per filter
//   value, like Microsoft's item with one unit of measure, and two rows for comparison), then Last() and Next(), then First() and OK().
//   Afterwards: the action RunModal returned and the field value after the lookup.
// Corpus issue: StefanMaron/BusinessCentral.AL.Language.Tests#660 item 3.
// BC versions: all (CI)

table 81153 "LT BE Lk Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Grp; Code[10]) { }
        field(2; "Code"; Code[10]) { }
        field(3; Qty; Integer) { }
    }

    keys { key(PK; Grp, "Code") { Clustered = true; } }
}

table 81154 "LT BE Lk Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; TableLk; Code[10])
        {
            trigger OnLookup()
            var
                Row: Record "LT BE Lk Row";
                Log: Codeunit "LT BE Log";
                Act: Action;
            begin
                Row.SetRange(Grp, Rec.Grp);
                Act := Page.RunModal(Page::"LT BE Lk List", Row);
                Log.Add('action=' + Format(Act));
                if Act = Action::LookupOK then
                    Rec.Validate(TableLk, Row."Code");
            end;
        }
        field(4; PageLk; Code[10]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 81154 "LT BE Lk List"
{
    PageType = List;
    SourceTable = "LT BE Lk Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT BE Log";
    begin
        Log.Add('lookupMode=' + Format(CurrPage.LookupMode));
    end;
}

page 81155 "LT BE Lk Doc List"
{
    PageType = List;
    SourceTable = "LT BE Lk Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(TableLk; Rec.TableLk) { ApplicationArea = All; }
                field(PageLk; Rec.PageLk)
                {
                    ApplicationArea = All;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Row: Record "LT BE Lk Row";
                        Act: Action;
                    begin
                        Row.SetRange(Grp, Rec.Grp);
                        Act := Page.RunModal(Page::"LT BE Lk List", Row);
                        Log.Add('action=' + Format(Act));
                        if Act = Action::LookupOK then begin
                            Text := Row."Code";
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PickRow)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Row: Record "LT BE Lk Row";
                    Act: Action;
                begin
                    Row.SetRange(Grp, Rec.Grp);
                    Act := Page.RunModal(Page::"LT BE Lk List", Row);
                    Log.Add('action=' + Format(Act));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT BE Log";
}

codeunit 81162 "LT BE RunModal OnLookup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT BE Log";

    // Group G1 has one row (U1), group G2 two rows (U2, U3). Doc 1 is in G1, doc 2 in G2.
    local procedure Seed()
    var
        Row: Record "LT BE Lk Row";
        Doc: Record "LT BE Lk Doc";
    begin
        Row.DeleteAll();
        Doc.DeleteAll();
        AddRow('G1', 'U1', 1);
        AddRow('G2', 'U2', 2);
        AddRow('G2', 'U3', 3);
        AddRow('G3', 'U4', 4);
        AddDoc(1, 'G1');
        AddDoc(2, 'G2');
        Log.Take();
    end;

    local procedure AddRow(Group: Code[10]; RowCode: Code[10]; Qty: Integer)
    var
        Row: Record "LT BE Lk Row";
    begin
        Row.Init();
        Row.Grp := Group;
        Row."Code" := RowCode;
        Row.Qty := Qty;
        Row.Insert();
    end;

    local procedure AddDoc(Id: Integer; Group: Code[10])
    var
        Doc: Record "LT BE Lk Doc";
    begin
        Doc.Init();
        Doc.Id := Id;
        Doc.Grp := Group;
        Doc.Insert();
    end;

    local procedure OpenAt(var TP: TestPage "LT BE Lk Doc List"; Id: Integer)
    var
        Doc: Record "LT BE Lk Doc";
    begin
        TP.OpenEdit();
        Doc.Get(Id);
        TP.GoToRecord(Doc);
    end;

    local procedure StoredTableLk(Id: Integer): Text
    var
        Doc: Record "LT BE Lk Doc";
    begin
        Doc.Get(Id);
        exit(Doc.TableLk);
    end;

    // a: table field OnLookup, host opened with OpenEdit.
    local procedure TableLookupCase(var Observer: Codeunit "Probe Observer"; Id: Integer)
    var
        TP: TestPage "LT BE Lk Doc List";
    begin
        Seed();
        OpenAt(TP, Id);
        TP.TableLk.Lookup();
        Observer.Observe('log', Log.Take());
        Observer.Observe('value', TP.TableLk.Value());
        TP.Close();
        Observer.Observe('stored', StoredTableLk(Id));
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure TableOnLookup_OneRow_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TableLookupCase(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure TableOnLookup_TwoRows_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TableLookupCase(Observer, 2);
        Observer.Finish();
    end;

    // b: table field OnLookup, host opened with Trap + Page.Run(id, Rec).
    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure TableOnLookup_OneRow_TrapPageRun()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "LT BE Lk Doc";
        TP: TestPage "LT BE Lk Doc List";
    begin
        Seed();
        Doc.Get(1);
        TP.Trap();
        Page.Run(Page::"LT BE Lk Doc List", Doc);
        Observer.Observe('at', TP.Id.Value());
        TP.TableLk.Lookup();
        Observer.Observe('log', Log.Take());
        Observer.Observe('value', TP.TableLk.Value());
        TP.Close();
        Observer.Observe('stored', StoredTableLk(1));
        Observer.Finish();
    end;

    // c: page field OnLookup.
    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure PageOnLookup_OneRow_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT BE Lk Doc List";
    begin
        Seed();
        OpenAt(TP, 1);
        TP.PageLk.Lookup();
        Observer.Observe('log', Log.Take());
        Observer.Observe('value', TP.PageLk.Value());
        TP.Close();
        Observer.Finish();
    end;

    // d: page action.
    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure ActionRunModal_OneRow_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT BE Lk Doc List";
    begin
        Seed();
        OpenAt(TP, 1);
        TP.PickRow.Invoke();
        Observer.Observe('log', Log.Take());
        TP.Close();
        Observer.Finish();
    end;

    // e: test code directly.
    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure DirectRunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row";
        Act: Action;
    begin
        Seed();
        Row.SetRange(Grp, 'G1');
        Act := Page.RunModal(Page::"LT BE Lk List", Row);
        Log.Add('action=' + Format(Act));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure WalkHandler(var LkList: TestPage "LT BE Lk List")
    var
        Seen: Text;
        Steps: Integer;
    begin
        Log.Add('editable=' + Format(LkList.Editable()));
        Log.Add('firstValue=' + LkList."Code".Value());
        repeat
            Seen += '[' + LkList."Code".Value() + ']';
            Steps += 1;
        until (not LkList.Next()) or (Steps > 5);
        Log.Add('rows=' + Seen);
        Log.Add('last=' + Format(LkList.Last()));
        Log.Add('atLast=' + LkList."Code".Value());
        Log.Add('nextAfterLast=' + Format(LkList.Next()));
        Log.Add('afterNext=' + LkList."Code".Value());
        LkList.First();
        Log.Add('backAtFirst=' + LkList."Code".Value());
        LkList.OK().Invoke();
    end;
}
