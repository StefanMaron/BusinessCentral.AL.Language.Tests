// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 88260 - 88265 (writer RM)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: an action that deletes every row of the source table through another record variable (with and without CurrPage.Update(false))
//   on a page that shows one stored row: a Worksheet without the new-row line (InsertAllowed = false, the shape of page 5510 "Production
//   Journal"), the same Worksheet opened for viewing and run modally, a List without the new-row line, and a Worksheet with the new-row line.
//   What the page shows afterwards (the control value, First/Last/Next), which triggers ran (log), and whether the table is empty.
//   Log: R:<line> = OnAfterGetRecord, C:<line> = OnAfterGetCurrRecord, N:<line> = OnNewRecord, Q = OnQueryClosePage, X = OnClosePage.
// Source: al-runner issue 5752 (a partner app posts a Production Journal from a ModalPageHandler).
// BC versions: 27, 28, 29

table 88260 "LT RM Ws Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

page 88261 "LT RM Ws NoNew"
{
    PageType = Worksheet;
    SourceTable = "LT RM Ws Line";
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(LineNoCtl; Rec."Line No.") { }
                field(DescriptionCtl; Rec.Description) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteAllUpdate)
            {
                Caption = 'Delete All Lines and Update';

                trigger OnAction()
                var
                    Line: Record "LT RM Ws Line";
                begin
                    Line.DeleteAll();
                    CurrPage.Update(false);
                end;
            }
            action(DeleteAllNoUpdate)
            {
                Caption = 'Delete All Lines';

                trigger OnAction()
                var
                    Line: Record "LT RM Ws Line";
                begin
                    Line.DeleteAll();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Format(Rec."Line No."));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('Q');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('X');
    end;

    var
        Log: Codeunit "LT RM Ws Log";
}

page 88262 "LT RM List NoNew"
{
    PageType = List;
    SourceTable = "LT RM Ws Line";
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(LineNoCtl; Rec."Line No.") { }
                field(DescriptionCtl; Rec.Description) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteAllUpdate)
            {
                Caption = 'Delete All Lines and Update';

                trigger OnAction()
                var
                    Line: Record "LT RM Ws Line";
                begin
                    Line.DeleteAll();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Format(Rec."Line No."));
    end;

    trigger OnClosePage()
    begin
        Log.Add('X');
    end;

    var
        Log: Codeunit "LT RM Ws Log";
}

page 88263 "LT RM Ws WithNew"
{
    PageType = Worksheet;
    SourceTable = "LT RM Ws Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(LineNoCtl; Rec."Line No.") { }
                field(DescriptionCtl; Rec.Description) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteAllUpdate)
            {
                Caption = 'Delete All Lines and Update';

                trigger OnAction()
                var
                    Line: Record "LT RM Ws Line";
                begin
                    Line.DeleteAll();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Format(Rec."Line No."));
    end;

    trigger OnClosePage()
    begin
        Log.Add('X');
    end;

    var
        Log: Codeunit "LT RM Ws Log";
}

codeunit 88264 "LT RM Ws Log"
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

codeunit 88265 "LT RM Ws Gone Row Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RM Ws Log";

    local procedure InsertOneLine()
    var
        Line: Record "LT RM Ws Line";
    begin
        Line.DeleteAll();
        Line."Line No." := 10000;
        Line.Description := 'Only line';
        Line.Insert();
        Log.Reset();
    end;

    local procedure LineCount(): Text
    var
        Line: Record "LT RM Ws Line";
    begin
        exit(Format(Line.Count()));
    end;

    [Test]
    procedure RM_Ws_OpenEdit_DeleteAllUpdate()
    var
        Ws: TestPage "LT RM Ws NoNew";
    begin
        InsertOneLine();
        Ws.OpenEdit();
        Observer.Observe('open shown', Ws.LineNoCtl.Value());
        Observer.Observe('open log', Log.Take());
        Ws.DeleteAllUpdate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.LineNoCtl.Value() + '|' + Ws.DescriptionCtl.Value());
        Observer.Observe('count', LineCount());
        Observer.Observe('first', Format(Ws.First()));
        Observer.Observe('first log', Log.Take());
        Observer.Observe('last', Format(Ws.Last()));
        Observer.Observe('next', Format(Ws.Next()));
        Observer.Observe('moves log', Log.Take());
        Ws.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('count after close', LineCount());
        Observer.Finish();
    end;

    [Test]
    procedure RM_Ws_OpenEdit_DeleteAllNoUpdate()
    var
        Ws: TestPage "LT RM Ws NoNew";
    begin
        InsertOneLine();
        Ws.OpenEdit();
        Log.Take();
        Ws.DeleteAllNoUpdate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.LineNoCtl.Value() + '|' + Ws.DescriptionCtl.Value());
        Observer.Observe('count', LineCount());
        Observer.Observe('first', Format(Ws.First()));
        Observer.Observe('first log', Log.Take());
        Ws.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure RM_Ws_OpenEdit_DeleteAllUpdate_Twice()
    var
        Ws: TestPage "LT RM Ws NoNew";
    begin
        InsertOneLine();
        Ws.OpenEdit();
        Log.Take();
        Ws.DeleteAllUpdate.Invoke();
        Log.Take();
        Ws.DeleteAllUpdate.Invoke();
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('shown after second action', Ws.LineNoCtl.Value());
        Ws.Close();
        Observer.Observe('count', LineCount());
        Observer.Finish();
    end;

    [Test]
    procedure RM_Ws_OpenView_DeleteAllUpdate()
    var
        Ws: TestPage "LT RM Ws NoNew";
    begin
        InsertOneLine();
        Ws.OpenView();
        Log.Take();
        Ws.DeleteAllUpdate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.LineNoCtl.Value() + '|' + Ws.DescriptionCtl.Value());
        Observer.Observe('count', LineCount());
        Observer.Observe('first', Format(Ws.First()));
        Ws.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DeleteAllUpdateHandler')]
    procedure RM_Ws_RunModal_DeleteAllUpdate()
    var
        Result: Action;
    begin
        InsertOneLine();
        Result := Page.RunModal(Page::"LT RM Ws NoNew");
        Observer.Observe('runmodal result', Format(Result));
        Observer.Observe('after runmodal log', Log.Take());
        Observer.Observe('count', LineCount());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure DeleteAllUpdateHandler(var Ws: TestPage "LT RM Ws NoNew")
    begin
        Observer.Observe('handler first', Format(Ws.First()));
        Observer.Observe('handler open log', Log.Take());
        Ws.DeleteAllUpdate.Invoke();
        Observer.Observe('handler action log', Log.Take());
        Observer.Observe('handler shown', Ws.LineNoCtl.Value());
        Observer.Observe('handler first after', Format(Ws.First()));
    end;

    [Test]
    [HandlerFunctions('DeleteAllUpdateOkHandler')]
    procedure RM_Ws_RunModal_DeleteAllUpdate_OK()
    var
        Result: Action;
    begin
        InsertOneLine();
        Result := Page.RunModal(Page::"LT RM Ws NoNew");
        Observer.Observe('runmodal result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Observe('count', LineCount());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure DeleteAllUpdateOkHandler(var Ws: TestPage "LT RM Ws NoNew")
    begin
        Ws.First();
        Ws.DeleteAllUpdate.Invoke();
        Ws.OK().Invoke();
    end;

    [Test]
    procedure RM_ListNoNew_OpenEdit_DeleteAllUpdate()
    var
        List: TestPage "LT RM List NoNew";
    begin
        InsertOneLine();
        List.OpenEdit();
        Log.Take();
        List.DeleteAllUpdate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', List.LineNoCtl.Value() + '|' + List.DescriptionCtl.Value());
        Observer.Observe('count', LineCount());
        Observer.Observe('first', Format(List.First()));
        List.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure RM_WsWithNew_OpenEdit_DeleteAllUpdate()
    var
        Ws: TestPage "LT RM Ws WithNew";
    begin
        InsertOneLine();
        Ws.OpenEdit();
        Log.Take();
        Ws.DeleteAllUpdate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.LineNoCtl.Value() + '|' + Ws.DescriptionCtl.Value());
        Observer.Observe('count', LineCount());
        Observer.Observe('first', Format(Ws.First()));
        Ws.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('count after close', LineCount());
        Observer.Finish();
    end;
}
