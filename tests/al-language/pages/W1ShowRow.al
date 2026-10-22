// Probe md:100: a page that showed no row, and an action that leaves Rec on a row the action stored.
// The stored-list case is pinned by the corpus (BNR Blank Part Tests); this adds a card, an insert through another variable,
// a filtered list with a row the filter admits and one it hides, and an editable list.

page 69270 "W1 Show List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
                field(Grp; Rec.Grp) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InsertPositioned)
            {
                trigger OnAction()
                begin
                    Rec.Init();
                    Rec.Id := 5;
                    Rec.Name := 'positioned';
                    Rec.Insert();
                end;
            }
            action(InsertOtherVar)
            {
                trigger OnAction()
                var
                    Other: Record "W1 Row";
                begin
                    Other.Init();
                    Other.Id := 6;
                    Other.Name := 'other';
                    Other.Insert();
                end;
            }
            action(InsertOtherVarThenGet)
            {
                trigger OnAction()
                var
                    Other: Record "W1 Row";
                begin
                    Other.Init();
                    Other.Id := 7;
                    Other.Name := 'otherget';
                    Other.Insert();
                    Rec.Get(7);
                end;
            }
        }
    }
}

page 69271 "W1 Show Filtered List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";
    SourceTableView = where(Grp = const(1));

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
                field(Grp; Rec.Grp) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InsertAdmitted)
            {
                trigger OnAction()
                begin
                    Rec.Init();
                    Rec.Id := 8;
                    Rec.Name := 'admitted';
                    Rec.Grp := 1;
                    Rec.Insert();
                end;
            }
            action(InsertHidden)
            {
                trigger OnAction()
                begin
                    Rec.Init();
                    Rec.Id := 9;
                    Rec.Name := 'hidden';
                    Rec.Grp := 2;
                    Rec.Insert();
                end;
            }
        }
    }
}

page 69272 "W1 Show Card"
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
            field(Name; Rec.Name) { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InsertPositioned)
            {
                trigger OnAction()
                begin
                    Rec.Init();
                    Rec.Id := 5;
                    Rec.Name := 'positioned';
                    Rec.Insert();
                end;
            }
            action(InsertOtherVar)
            {
                trigger OnAction()
                var
                    Other: Record "W1 Row";
                begin
                    Other.Init();
                    Other.Id := 6;
                    Other.Name := 'other';
                    Other.Insert();
                end;
            }
        }
    }
}

codeunit 69303 "W1 Show Row Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Empty()
    var
        Row: Record "W1 Row";
    begin
        Row.DeleteAll();
    end;

    [Test]
    procedure List_ViewOpen_InsertPositioned()
    var
        Pg: TestPage "W1 Show List";
        Observer: Codeunit "Probe Observer";
    begin
        Empty();
        Pg.OpenView();
        Observer.Observe('id_before', Pg.Id.Value());
        Pg.InsertPositioned.Invoke();
        Observer.Observe('id_after', Pg.Id.Value());
        Observer.Observe('name_after', Pg.Name.Value());
        Observer.Observe('first', Format(Pg.First()));
        Observer.Observe('id_after_first', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('id_before', '');
        Observer.Expect('id_after', '5');
        Observer.Expect('name_after', 'positioned');
        Observer.Expect('first', 'Yes');
        Observer.Expect('id_after_first', '5');
        Observer.Verify();
    end;

    [Test]
    procedure List_EditOpen_InsertPositioned()
    var
        Pg: TestPage "W1 Show List";
        Observer: Codeunit "Probe Observer";
    begin
        Empty();
        Pg.OpenEdit();
        Observer.Observe('id_before', Pg.Id.Value());
        Pg.InsertPositioned.Invoke();
        Observer.Observe('id_after', Pg.Id.Value());
        Observer.Observe('name_after', Pg.Name.Value());
        Observer.Observe('first', Format(Pg.First()));
        Observer.Observe('id_after_first', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('id_before', '0');
        Observer.Expect('id_after', '5');
        Observer.Expect('name_after', 'positioned');
        Observer.Expect('first', 'Yes');
        Observer.Expect('id_after_first', '5');
        Observer.Verify();
    end;

    [Test]
    procedure List_ViewOpen_InsertThroughAnotherVariable()
    var
        Pg: TestPage "W1 Show List";
        Observer: Codeunit "Probe Observer";
    begin
        Empty();
        Pg.OpenView();
        Pg.InsertOtherVar.Invoke();
        Observer.Observe('id_after', Pg.Id.Value());
        Observer.Observe('first', Format(Pg.First()));
        Observer.Observe('id_after_first', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('id_after', '6');
        Observer.Expect('first', 'Yes');
        Observer.Expect('id_after_first', '6');
        Observer.Verify();
    end;

    [Test]
    procedure List_ViewOpen_InsertThroughAnotherVariable_ThenGet()
    var
        Pg: TestPage "W1 Show List";
        Observer: Codeunit "Probe Observer";
    begin
        Empty();
        Pg.OpenView();
        Pg.InsertOtherVarThenGet.Invoke();
        Observer.Observe('id_after', Pg.Id.Value());
        Observer.Observe('name_after', Pg.Name.Value());
        Pg.Close();
        Observer.Expect('id_after', '7');
        Observer.Expect('name_after', 'otherget');
        Observer.Verify();
    end;

    [Test]
    procedure FilteredList_InsertedRowTheViewAdmits()
    var
        Pg: TestPage "W1 Show Filtered List";
        Observer: Codeunit "Probe Observer";
    begin
        Empty();
        Pg.OpenView();
        Pg.InsertAdmitted.Invoke();
        Observer.Observe('id_after', Pg.Id.Value());
        Observer.Observe('name_after', Pg.Name.Value());
        Pg.Close();
        Observer.Expect('id_after', '8');
        Observer.Expect('name_after', 'admitted');
        Observer.Verify();
    end;

    [Test]
    procedure FilteredList_InsertedRowTheViewHides()
    var
        Pg: TestPage "W1 Show Filtered List";
        Observer: Codeunit "Probe Observer";
    begin
        Empty();
        Pg.OpenView();
        Pg.InsertHidden.Invoke();
        Observer.Observe('id_after', Pg.Id.Value());
        Observer.Observe('name_after', Pg.Name.Value());
        Observer.Observe('first', Format(Pg.First()));
        Observer.Observe('id_after_first', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('id_after', '');
        Observer.Expect('name_after', '');
        Observer.Expect('first', 'No');
        Observer.Expect('id_after_first', '');
        Observer.Verify();
    end;

    [Test]
    procedure Card_EditOpen_InsertPositioned()
    var
        Pg: TestPage "W1 Show Card";
        Observer: Codeunit "Probe Observer";
    begin
        Empty();
        Pg.OpenEdit();
        Observer.Observe('id_before', Pg.Id.Value());
        Pg.InsertPositioned.Invoke();
        Observer.Observe('id_after', Pg.Id.Value());
        Observer.Observe('name_after', Pg.Name.Value());
        Pg.Close();
        Observer.Expect('id_before', '');
        Observer.Expect('id_after', '5');
        Observer.Expect('name_after', 'positioned');
        Observer.Verify();
    end;

    [Test]
    procedure Card_ViewOpen_InsertThroughAnotherVariable()
    var
        Pg: TestPage "W1 Show Card";
        Observer: Codeunit "Probe Observer";
    begin
        Empty();
        Pg.OpenView();
        Pg.InsertOtherVar.Invoke();
        Observer.Observe('id_after', Pg.Id.Value());
        Observer.Observe('name_after', Pg.Name.Value());
        Pg.Close();
        Observer.Expect('id_after', '6');
        Observer.Expect('name_after', 'other');
        Observer.Verify();
    end;
}
