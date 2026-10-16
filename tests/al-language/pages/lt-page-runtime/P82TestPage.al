// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P82 List (71188), LT P82 Card (71187), LT P82 Tree (71189), LT P82 Host (71191), LT P82 Sub (71190), LT P82 Item (71184), LT P82 Group (71192), LT P82 Log (71186) from P82Fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestPage navigation (First / Next / Previous / Last / GoToKey / GoToRecord with misses and several key values), Filter.SetFilter on fields and views, Caption, Expand / IsExpanded on a tree, TestPart Visible / Enabled / Editable and rows
// BC versions: 29 (27 and 28 by CI)

codeunit 71204 "LT P82 TestPage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT P82 Item";
        Grp: Record "LT P82 Group";
        Log: Codeunit "LT P82 Log";
        I: Integer;
    begin
        Item.DeleteAll();
        Grp.DeleteAll();
        Log.Reset();
        Grp.Code := 'G1';
        Grp.Descr := 'Group one';
        Grp.Insert();
        Grp.Code := 'G2';
        Grp.Descr := 'Group two';
        Grp.Insert();
        for I := 1 to 5 do begin
            Item."No." := 'N' + Format(I);
            Item.Name := 'Name ' + Format(I);
            Item.Qty := I * 10;
            Item.Amount := I / 4;
            Item.Grp := 'G' + Format((I mod 2) + 1);
            Item.Indent := 0;
            Item.Insert();
        end;
    end;

    [Test]
    procedure Navigation_FirstNextPreviousLast()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('first-no', List.NoCtl.Value());
        Observer.Observe('previous-at-first', Format(List.Previous()));
        Observer.Observe('no-after-failed-previous', List.NoCtl.Value());
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('next-no', List.NoCtl.Value());
        Observer.Observe('last', Format(List.Last()));
        Observer.Observe('last-no', List.NoCtl.Value());
        Observer.Observe('next-at-last', Format(List.Next()));
        Observer.Observe('no-after-failed-next', List.NoCtl.Value());
        Observer.Observe('previous', Format(List.Previous()));
        Observer.Observe('previous-no', List.NoCtl.Value());
        List.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Navigation_GoToKey()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('hit', Format(List.GoToKey('N3')));
        Observer.Observe('hit-no', List.NoCtl.Value());
        Observer.Observe('miss', Format(List.GoToKey('ZZ')));
        Observer.Observe('no-after-miss', List.NoCtl.Value());
        Observer.Observe('empty-key', Format(List.GoToKey('')));
        Observer.Observe('no-after-empty', List.NoCtl.Value());
        Observer.Observe('lowercase', Format(List.GoToKey('n2')));
        Observer.Observe('lowercase-no', List.NoCtl.Value());
        Observer.Observe('backwards', Format(List.GoToKey('N1')));
        Observer.Observe('backwards-no', List.NoCtl.Value());
        asserterror List.GoToKey('N1', 'extra');
        Observer.ObserveError('too-many-key-values');
        asserterror List.GoToKey(1);
        Observer.ObserveError('wrong-type');
        List.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Navigation_GoToRecord()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P82 Item";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.OpenView();
        Item.Get('N4');
        Observer.Observe('hit', Format(List.GoToRecord(Item)));
        Observer.Observe('hit-no', List.NoCtl.Value());
        Item."No." := 'NOPE';
        Observer.Observe('miss', Format(List.GoToRecord(Item)));
        Observer.Observe('no-after-miss', List.NoCtl.Value());
        Clear(Item);
        Observer.Observe('cleared-record', Format(List.GoToRecord(Item)));
        Item.Get('N2');
        Item.Name := 'Different name';
        Observer.Observe('key-only-match', Format(List.GoToRecord(Item)));
        Observer.Observe('key-only-no', List.NoCtl.Value());
        List.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Filter_SetFilter_Fields()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P82 List";
        N: Integer;
    begin
        Seed();
        List.OpenView();
        List.Filter.SetFilter(Qty, '20..40');
        if List.First() then
            repeat
                N += 1;
                Observer.Observe('range-row' + Format(N), List.NoCtl.Value());
            until not List.Next();
        List.Filter.SetFilter(Qty, '');
        Observer.Observe('count-after-clear', Format(CountRows(List)));
        List.Filter.SetFilter(Name, '*3|*5');
        Observer.Observe('count-name-or', Format(CountRows(List)));
        List.Filter.SetFilter(Name, 'Name 1');
        Observer.Observe('count-name-exact', Format(CountRows(List)));
        List.Filter.SetFilter(Qty, '>1000');
        Observer.Observe('count-none', Format(CountRows(List)));
        Observer.Observe('first-none', Format(List.First()));
        asserterror List.Filter.SetFilter(Qty, 'abc');
        Observer.ObserveError('invalid-integer-filter');
        List.Close();
        Observer.Finish();
    end;

    local procedure CountRows(var List: TestPage "LT P82 List"): Integer
    var
        N: Integer;
    begin
        if List.First() then
            repeat
                N += 1;
            until not List.Next();
        exit(N);
    end;

    [Test]
    procedure Filter_CurrentKey_And_Ascending()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P82 List";
        N: Integer;
    begin
        Seed();
        List.OpenView();
        List.Filter.SetCurrentKey(Qty);
        List.Filter.Ascending(false);
        if List.First() then
            repeat
                N += 1;
                Observer.Observe('desc-row' + Format(N), List.NoCtl.Value());
            until not List.Next();
        Observer.Observe('ascending', Format(List.Filter.Ascending()));
        List.Close();
        Observer.Finish();
    end;

    [Test]
    procedure OpenView_FilterBeforeOpen()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.Trap();
        Page.Run(Page::"LT P82 List");
        Observer.Observe('count-after-trap', Format(CountRows(List)));
        List.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Caption_List_And_Host()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT P82 Host";
        Group: TestPage "LT P82 Group List";
    begin
        Seed();
        Group.OpenView();
        Observer.Observe('group-caption', Group.Caption());
        Observer.Observe('code-caption', Group.CodeCtl.Caption());
        Group.Close();
        Host.OpenView();
        Observer.Observe('host-caption', Host.Caption());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Tree_Expand_IsExpanded()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P82 Item";
        Tree: TestPage "LT P82 Tree";
        N: Integer;
    begin
        Seed();
        Item.Get('N2');
        Item.Indent := 1;
        Item.Modify();
        Item.Get('N3');
        Item.Indent := 2;
        Item.Modify();
        Item.Get('N4');
        Item.Indent := 1;
        Item.Modify();
        Tree.OpenView();
        Tree.GoToKey('N1');
        Observer.Observe('n1-expanded-initial', Format(Tree.IsExpanded()));
        Tree.Expand(true);
        Observer.Observe('n1-expanded-after-true', Format(Tree.IsExpanded()));
        Tree.Expand(true);
        Observer.Observe('n1-expanded-after-second-true', Format(Tree.IsExpanded()));
        Tree.Expand(false);
        Observer.Observe('n1-expanded-after-false', Format(Tree.IsExpanded()));
        Tree.Expand(false);
        Observer.Observe('n1-expanded-after-second-false', Format(Tree.IsExpanded()));
        asserterror Tree.GoToKey('N2');
        Observer.ObserveError('af238');
        Observer.Observe('n2-expanded-initial', Format(Tree.IsExpanded()));
        Tree.Expand(true);
        Observer.Observe('n2-expanded-after-true', Format(Tree.IsExpanded()));
        asserterror Tree.GoToKey('N3');
        Observer.ObserveError('af243');
        Observer.Observe('n3-expanded-leaf', Format(Tree.IsExpanded()));
        Tree.Expand(true);
        Observer.Observe('n3-expanded-leaf-after-true', Format(Tree.IsExpanded()));
        Tree.GoToKey('N5');
        Observer.Observe('n5-expanded-leaf', Format(Tree.IsExpanded()));
        Tree.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Tree_Rows_WhileCollapsed()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P82 Item";
        Tree: TestPage "LT P82 Tree";
        N: Integer;
    begin
        Seed();
        Item.Get('N2');
        Item.Indent := 1;
        Item.Modify();
        Item.Get('N3');
        Item.Indent := 1;
        Item.Modify();
        Tree.OpenView();
        Tree.GoToKey('N1');
        Tree.Expand(false);
        if Tree.First() then
            repeat
                N += 1;
                Observer.Observe('collapsed-row' + Format(N), Tree.NoCtl.Value());
            until not Tree.Next();
        Observer.Observe('goto-child-collapsed', Format(Tree.GoToKey('N2')));
        Tree.GoToKey('N1');
        Tree.Expand(true);
        N := 0;
        if Tree.First() then
            repeat
                N += 1;
                Observer.Observe('expanded-row' + Format(N), Tree.NoCtl.Value());
            until not Tree.Next();
        Tree.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_Hidden_And_Disabled_Access()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT P82 Host";
    begin
        Seed();
        Host.OpenView();
        Host.GoToKey('G1');
        asserterror Observer.Observe('hidden-first', Format(Host.HiddenPart.First()));
        Observer.ObserveError('hidden-first');
        Observer.Observe('disabled-first', Format(Host.DisabledPart.First()));
        Observer.Observe('disabled-first', 'no error');
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Page_Editable_And_Close_Twice()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('view-editable', Format(Card.Editable()));
        Card.Close();
        Card.OpenEdit();
        Observer.Observe('edit-editable', Format(Card.Editable()));
        Card.Close();
        asserterror Card.Close();
        Observer.ObserveError('close-twice');
        asserterror Observer.Observe('editable-closed', Format(Card.Editable()));
        Observer.ObserveError('editable-closed');
        asserterror Observer.Observe('caption-closed', Card.Caption());
        Observer.ObserveError('caption-closed');
        Observer.Finish();
    end;

    [Test]
    procedure OpenNew_Then_GoToKey()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenNew();
        Observer.Observe('new-no', Card.NoCtl.Value());
        Observer.Observe('goto-existing', Format(Card.GoToKey('N2')));
        Observer.Observe('goto-existing-name', Card.NameCtl.Value());
        Card.Close();
        Observer.Finish();
    end;
}
