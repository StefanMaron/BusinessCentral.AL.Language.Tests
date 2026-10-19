// Probe md:13: a page extension adds actions to implicit action areas and promoted categories of a page that declares no actions.

page 69264 "W1 No Actions Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }
}

codeunit 69242 "W1 Area Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

pageextension 69265 "W1 No Actions Ext" extends "W1 No Actions Card"
{
    actions
    {
        addfirst(Navigation)
        {
            action(NavFirst)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "W1 Area Log";
                begin
                    Log.Add('NavFirst');
                end;
            }
        }
        addlast(Creation)
        {
            action(CreLast)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "W1 Area Log";
                begin
                    Log.Add('CreLast');
                end;
            }
        }
        addlast(Reporting)
        {
            action(RepLast)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "W1 Area Log";
                begin
                    Log.Add('RepLast');
                end;
            }
        }
        addfirst(Processing)
        {
            action(ProcFirst)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "W1 Area Log";
                begin
                    Log.Add('ProcFirst');
                end;
            }
        }
        addlast(Prompting)
        {
            action(PromptLast)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "W1 Area Log";
                begin
                    Log.Add('PromptLast');
                end;
            }
        }
    }
}

codeunit 69300 "W1 Area Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "W1 Area Log";

    local procedure SeedRows()
    var
        Row: Record "W1 Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Insert();
    end;

    [Test]
    procedure ExtensionActions_InImplicitAreas_Run()
    var
        Pg: TestPage "W1 No Actions Card";
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows();
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('open_log', Log.Take());
        Observer.Observe('NavFirst_visible', Format(Pg.NavFirst.Visible()));
        Pg.NavFirst.Invoke();
        Pg.CreLast.Invoke();
        Pg.RepLast.Invoke();
        Pg.ProcFirst.Invoke();
        Pg.PromptLast.Invoke();
        Observer.Observe('invoked', Log.Take());
        Pg.Close();
        Observer.Expect('open_log', '');
        Observer.Expect('NavFirst_visible', 'Yes');
        Observer.Expect('invoked', 'NavFirst;CreLast;RepLast;ProcFirst;PromptLast;');
        Observer.Verify();
    end;
}
