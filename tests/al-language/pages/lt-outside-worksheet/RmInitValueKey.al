// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 88277 - 88282 (writer RM)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a page opened without a record whose SourceTableView sorts by a secondary key (SortOrder), over a table whose primary key
//   ("Group Code", Kind, "Line No.") has an InitValue on Kind (B): Rec stands on the primary key ('', B, 0), which no row has, when the page
//   opens; OnOpenPage does not touch Rec. Which row the page opens on, which triggers ran (log: R:<line> = OnAfterGetRecord,
//   C:<line> = OnAfterGetCurrRecord), and where Next and GoToRecord go. List ascending and descending, Card; OpenEdit, OpenView, Page.Run,
//   Page.RunModal; and the same List when a row with the primary key ('', B, 0) exists.
//   Rows of group G: (A,1,SortOrder 20) (B,2,10) (C,3,30) (A,4,-5). Ascending view order: 4, 2, 1, 3.
// Source: al-runner issue 5760.
// BC versions: 27, 28, 29

table 88277 "LT RM Init Key Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Group Code"; Code[20]) { }
        field(2; Kind; Option)
        {
            OptionMembers = A,B,C;
            InitValue = B;
        }
        field(3; "Line No."; Integer) { }
        field(4; SortOrder; Integer) { }
    }

    keys
    {
        key(PK; "Group Code", Kind, "Line No.") { Clustered = true; }
        key(BySortOrder; SortOrder) { }
    }
}

page 88278 "LT RM Init Key List"
{
    PageType = List;
    SourceTable = "LT RM Init Key Line";
    SourceTableView = sorting(SortOrder) order(ascending);
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNoCtl; Rec."Line No.") { }
                field(SortOrderCtl; Rec.SortOrder) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Opened := true;
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    var
        Log: Codeunit "LT RM Init Key Log";
        Opened: Boolean;
}

page 88279 "LT RM Init Key List Desc"
{
    PageType = List;
    SourceTable = "LT RM Init Key Line";
    SourceTableView = sorting(SortOrder) order(descending);
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNoCtl; Rec."Line No.") { }
                field(SortOrderCtl; Rec.SortOrder) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Opened := true;
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    var
        Log: Codeunit "LT RM Init Key Log";
        Opened: Boolean;
}

page 88280 "LT RM Init Key Card"
{
    PageType = Card;
    SourceTable = "LT RM Init Key Line";
    SourceTableView = sorting(SortOrder) order(ascending);
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(LineNoCtl; Rec."Line No.") { }
            field(SortOrderCtl; Rec.SortOrder) { }
        }
    }

    trigger OnOpenPage()
    begin
        Opened := true;
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    var
        Log: Codeunit "LT RM Init Key Log";
        Opened: Boolean;
}

codeunit 88281 "LT RM Init Key Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

codeunit 88282 "LT RM Init Key Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RM Init Key Log";

    local procedure Seed(WithInitRow: Boolean)
    var
        Line: Record "LT RM Init Key Line";
    begin
        Line.DeleteAll();
        InsertLine('G', Line.Kind::A, 1, 20);
        InsertLine('G', Line.Kind::B, 2, 10);
        InsertLine('G', Line.Kind::C, 3, 30);
        InsertLine('G', Line.Kind::A, 4, -5);
        if WithInitRow then
            InsertLine('', Line.Kind::B, 0, 15);
        Log.Reset();
    end;

    local procedure InsertLine(GroupCode: Code[20]; Kind: Option; LineNo: Integer; SortOrder: Integer)
    var
        Line: Record "LT RM Init Key Line";
    begin
        Line."Group Code" := GroupCode;
        Line.Kind := Kind;
        Line."Line No." := LineNo;
        Line.SortOrder := SortOrder;
        Line.Insert();
    end;

    local procedure ObserveList(var Lines: TestPage "LT RM Init Key List")
    var
        Line: Record "LT RM Init Key Line";
    begin
        Observer.Observe('open', Lines.LineNoCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(Lines.Next()) + '|' + Lines.LineNoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Line.Get('G', Line.Kind::C, 3);
        Lines.GoToRecord(Line);
        Observer.Observe('goto', Lines.LineNoCtl.Value());
        Observer.Observe('goto log', Log.Take());
        Observer.Observe('first', Format(Lines.First()) + '|' + Lines.LineNoCtl.Value());
    end;

    [Test]
    procedure RM_List_OpenEdit()
    var
        Lines: TestPage "LT RM Init Key List";
    begin
        Seed(false);
        Lines.OpenEdit();
        ObserveList(Lines);
        Lines.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RM_List_OpenView()
    var
        Lines: TestPage "LT RM Init Key List";
    begin
        Seed(false);
        Lines.OpenView();
        ObserveList(Lines);
        Lines.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RM_List_PageRun()
    var
        Lines: TestPage "LT RM Init Key List";
    begin
        Seed(false);
        Lines.Trap();
        Page.Run(Page::"LT RM Init Key List");
        ObserveList(Lines);
        Lines.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListModalHandler')]
    procedure RM_List_RunModal()
    begin
        Seed(false);
        Page.RunModal(Page::"LT RM Init Key List");
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure ListModalHandler(var Lines: TestPage "LT RM Init Key List")
    begin
        ObserveList(Lines);
    end;

    [Test]
    procedure RM_List_OpenEdit_InitKeyRowExists()
    var
        Lines: TestPage "LT RM Init Key List";
    begin
        Seed(true);
        Lines.OpenEdit();
        ObserveList(Lines);
        Lines.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RM_ListDesc_OpenEdit()
    var
        Lines: TestPage "LT RM Init Key List Desc";
    begin
        Seed(false);
        Lines.OpenEdit();
        Observer.Observe('open', Lines.LineNoCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(Lines.Next()) + '|' + Lines.LineNoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Lines.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RM_Card_OpenEdit()
    var
        Card: TestPage "LT RM Init Key Card";
    begin
        Seed(false);
        Card.OpenEdit();
        Observer.Observe('open', Card.LineNoCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(Card.Next()) + '|' + Card.LineNoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardModalHandler')]
    procedure RM_Card_RunModal()
    begin
        Seed(false);
        Page.RunModal(Page::"LT RM Init Key Card");
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure CardModalHandler(var Card: TestPage "LT RM Init Key Card")
    begin
        Observer.Observe('open', Card.LineNoCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(Card.Next()) + '|' + Card.LineNoCtl.Value());
    end;
}
