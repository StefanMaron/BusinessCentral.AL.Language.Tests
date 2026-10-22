// Probe md:13, second half: promoted categories on a page that declares no actions. If the compiler refuses these, that refusal is the finding
// (see the manifest); the file is split from W1ActionAreas.al for that reason.

page 69266 "W1 No Actions Card 2"
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

codeunit 69243 "W1 Promoted Log"
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

pageextension 69267 "W1 No Actions Ext 2" extends "W1 No Actions Card 2"
{
    actions
    {
        addlast(Processing)
        {
            action(PromoA)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "W1 Promoted Log";
                begin
                    Log.Add('PromoA');
                end;
            }
            action(PromoB)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "W1 Promoted Log";
                begin
                    Log.Add('PromoB');
                end;
            }
            action(PromoC)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "W1 Promoted Log";
                begin
                    Log.Add('PromoC');
                end;
            }
        }
        addafter(Category_New)
        {
            group(Category_W1AfterNew)
            {
                actionref(PromoARef; PromoA) { }
            }
        }
        addafter(Category_Report)
        {
            group(Category_W1AfterReport)
            {
                actionref(PromoBRef; PromoB) { }
            }
        }
        addafter(Category_Process)
        {
            group(Category_W1AfterProcess)
            {
                actionref(PromoCRef; PromoC) { }
            }
        }
    }
}

codeunit 69301 "W1 Promoted Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "W1 Promoted Log";

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
    procedure ExtensionGroups_AfterImplicitCategories()
    var
        Pg: TestPage "W1 No Actions Card 2";
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows();
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('open_log', Log.Take());
        Pg.PromoA.Invoke();
        Pg.PromoB.Invoke();
        Pg.PromoC.Invoke();
        Observer.Observe('actions_invoked', Log.Take());
        Pg.PromoARef.Invoke();
        Pg.PromoBRef.Invoke();
        Pg.PromoCRef.Invoke();
        Observer.Observe('refs_invoked', Log.Take());
        Pg.Close();
        Observer.Expect('open_log', '');
        Observer.Expect('actions_invoked', 'PromoA;PromoB;PromoC;');
        Observer.Expect('refs_invoked', 'PromoA;PromoB;PromoC;');
        Observer.Verify();
    end;
}
