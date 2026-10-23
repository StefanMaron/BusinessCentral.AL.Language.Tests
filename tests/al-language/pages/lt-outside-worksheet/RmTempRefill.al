// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetabletemporary-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 88266 - 88269 (writer RM)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a Worksheet over a temporary source (Insert/Modify/DeleteAllowed false, the shape of page 5530 "Item Availability by Event") that
//   empties and refills Rec (Reset, DeleteAll, insert numbered from 1, FindFirst) from a filter field's OnValidate and from an action, with
//   and without CurrPage.Update(false). It holds 27 rows (A1..A25 B1 B2), more than the client reads at once; the filter B leaves two rows.
//   What the page shows afterwards (the current row, the rows First/Next read, where Next/Previous go from the row the client stood on),
//   and which triggers ran (log: R:<name> = OnAfterGetRecord, C:<name> = OnAfterGetCurrRecord).
// Source: al-runner issues 5779 (filter OnValidate refill) and 5780 (action refill after the client stood past row 20).
// BC versions: 27, 28, 29

table 88266 "LT RM Refill Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Group Code"; Code[10]) { }
        field(3; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

page 88267 "LT RM Refill Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT RM Refill Row";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(GroupFilter; GroupFilter)
                {
                    Caption = 'Group Filter';

                    trigger OnValidate()
                    begin
                        Refill();
                    end;
                }
            }
            repeater(Lines)
            {
                Editable = false;
                field(Name; NameText) { Caption = 'Name'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Recalculate)
            {
                Caption = 'Recalculate';

                trigger OnAction()
                begin
                    Refill();
                end;
            }
            action(RecalculateAndUpdate)
            {
                Caption = 'Recalculate and Update';

                trigger OnAction()
                begin
                    Refill();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Refill();
    end;

    trigger OnAfterGetRecord()
    begin
        NameText := Rec.Name;
        Log.Add('R:' + Rec.Name);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsGroupA := Rec."Group Code" = 'A';
        Log.Add('C:' + Rec.Name);
    end;

    var
        Log: Codeunit "LT RM Refill Log";
        GroupFilter: Text;
        NameText: Text;
        IsGroupA: Boolean;

    local procedure Refill()
    var
        EntryNo: Integer;
        RowNo: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        for RowNo := 1 to 25 do
            AddRow(EntryNo, 'A', StrSubstNo('A%1', RowNo));
        AddRow(EntryNo, 'B', 'B1');
        AddRow(EntryNo, 'B', 'B2');
        if Rec.FindFirst() then;
    end;

    local procedure AddRow(var EntryNo: Integer; GroupCode: Code[10]; NewName: Text[50])
    begin
        if (GroupFilter <> '') and (GroupFilter <> GroupCode) then
            exit;
        EntryNo += 1;
        Rec.Init();
        Rec."Entry No." := EntryNo;
        Rec."Group Code" := GroupCode;
        Rec.Name := NewName;
        Rec.Insert();
    end;
}

codeunit 88268 "LT RM Refill Log"
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

codeunit 88269 "LT RM Refill Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RM Refill Log";

    local procedure OpenByRun(var Ws: TestPage "LT RM Refill Worksheet")
    var
        WsPage: Page "LT RM Refill Worksheet";
    begin
        Log.Reset();
        Ws.Trap();
        WsPage.Run();
    end;

    local procedure GoToRow(var Ws: TestPage "LT RM Refill Worksheet"; RowNo: Integer)
    var
        I: Integer;
    begin
        Ws.First();
        for I := 2 to RowNo do
            Ws.Next();
    end;

    local procedure ReadRows(var Ws: TestPage "LT RM Refill Worksheet") Rows: Text
    begin
        if Ws.First() then
            repeat
                if Rows <> '' then
                    Rows += ' ';
                Rows += Ws.Name.Value();
            until not Ws.Next();
    end;

    local procedure CountRows(var Ws: TestPage "LT RM Refill Worksheet") RowCount: Integer
    begin
        if Ws.First() then
            repeat
                RowCount += 1;
            until not Ws.Next();
    end;

    [Test]
    procedure RM_Filter_B_FromOpen()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        Observer.Observe('open shown', Ws.Name.Value());
        Log.Take();
        Ws.GroupFilter.SetValue('B');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('shown after filter', Ws.Name.Value());
        Observer.Observe('rows', ReadRows(Ws));
        Ws.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RM_Filter_B_OpenEdit()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        Log.Reset();
        Ws.OpenEdit();
        Log.Take();
        Ws.GroupFilter.SetValue('B');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('shown after filter', Ws.Name.Value());
        Observer.Observe('rows', ReadRows(Ws));
        Ws.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RM_Filter_B_FromRow23()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        GoToRow(Ws, 23);
        Observer.Observe('before', Ws.Name.Value());
        Log.Take();
        Ws.GroupFilter.SetValue('B');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('shown after filter', Ws.Name.Value());
        Observer.Observe('next', Format(Ws.Next()) + '|' + Ws.Name.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('rows', ReadRows(Ws));
        Ws.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RM_Filter_B_FromRow2_Previous()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        GoToRow(Ws, 2);
        Log.Take();
        Ws.GroupFilter.SetValue('B');
        Observer.Observe('shown after filter', Ws.Name.Value());
        Observer.Observe('previous', Format(Ws.Previous()) + '|' + Ws.Name.Value());
        Observer.Observe('next', Format(Ws.Next()) + '|' + Ws.Name.Value());
        Observer.Observe('next2', Format(Ws.Next()) + '|' + Ws.Name.Value());
        Observer.Observe('moves log', Log.Take());
        Ws.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RM_Filter_BThenCleared()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        Ws.GroupFilter.SetValue('B');
        Log.Take();
        Ws.GroupFilter.SetValue('');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('shown after clear', Ws.Name.Value());
        Observer.Observe('row count', Format(CountRows(Ws)));
        Observer.Observe('last', Format(Ws.Last()) + '|' + Ws.Name.Value());
        Ws.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RM_Action_Recalculate_FromRow23()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        GoToRow(Ws, 23);
        Observer.Observe('before', Ws.Name.Value());
        Log.Take();
        Ws.Recalculate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.Name.Value());
        Observer.Observe('rows', ReadRows(Ws));
        Ws.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RM_Action_Recalculate_FromRow23_Next()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        GoToRow(Ws, 23);
        Ws.Recalculate.Invoke();
        Log.Take();
        Observer.Observe('next', Format(Ws.Next()) + '|' + Ws.Name.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(Ws.Previous()) + '|' + Ws.Name.Value());
        Observer.Observe('previous2', Format(Ws.Previous()) + '|' + Ws.Name.Value());
        Observer.Observe('previous log', Log.Take());
        Ws.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RM_Action_RecalculateAndUpdate_FromRow23()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        GoToRow(Ws, 23);
        Log.Take();
        Ws.RecalculateAndUpdate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.Name.Value());
        Observer.Observe('next', Format(Ws.Next()) + '|' + Ws.Name.Value());
        Observer.Observe('rows', ReadRows(Ws));
        Ws.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RM_Action_Recalculate_FromRow2()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        GoToRow(Ws, 2);
        Log.Take();
        Ws.Recalculate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.Name.Value());
        Observer.Observe('next', Format(Ws.Next()) + '|' + Ws.Name.Value());
        Ws.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RM_Action_Recalculate_AfterFilterB()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        Ws.GroupFilter.SetValue('B');
        GoToRow(Ws, 2);
        Log.Take();
        Ws.Recalculate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.Name.Value());
        Observer.Observe('rows', ReadRows(Ws));
        Ws.Close();
        Observer.Finish();
    end;
}
