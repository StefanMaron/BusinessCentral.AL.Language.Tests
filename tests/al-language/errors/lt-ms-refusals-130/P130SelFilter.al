// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-setselectionfilter-method
// Scope: in-scope
// Fixtures used: P130Fixtures.al (table 73536, log 73538, page 73543), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CurrPage.SetSelectionFilter into a record that already has a view (a range on the key, a filter on another field, a range that excludes the selected row,
//   marks with MarkedOnly, a SetView with another sort order, a filter that matches nothing); into the page's own Rec (before and after: filter, count, current row);
//   into a page global record called twice on two rows (does the filter accumulate or start again)
// Settles issue 130 reasons 4, 6, 13 (Page.SetSelectionFilter into a record that has filters)
// BC versions: 29 (27 and 28 by CI)

codeunit 73547 "LT P130 Sel Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RunMode(var Observer: Codeunit "Probe Observer"; Name: Text; Mode: Integer; KeyValue: Code[20])
    var
        Log: Codeunit "LT P130 Log";
        List: TestPage "LT P130 Sel List";
    begin
        Log.Seed();
        Log.SetMode(Mode);
        List.OpenView();
        List.GoToKey(KeyValue);
        List.ActSel.Invoke();
        Observer.Observe(Name, Log.Take());
        List.Close();
    end;

    [Test]
    procedure P130_SelectionFilter_IntoFilteredRecord_OnRowB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMode(Observer, 'mode0_no_prior_view_rowB', 0, 'B');
        RunMode(Observer, 'mode1_range_no_B_rowB', 1, 'B');
        RunMode(Observer, 'mode1_range_no_B_rowA', 1, 'A');
        RunMode(Observer, 'mode2_filter_qty_ge2_rowB', 2, 'B');
        RunMode(Observer, 'mode2_filter_qty_ge2_rowA', 2, 'A');
        RunMode(Observer, 'mode3_range_A_B_rowB', 3, 'B');
        RunMode(Observer, 'mode3_range_A_B_rowC', 3, 'C');
        RunMode(Observer, 'mode4_marked_C_rowB', 4, 'B');
        RunMode(Observer, 'mode4_marked_C_rowC', 4, 'C');
        RunMode(Observer, 'mode5_view_desc_rowB', 5, 'B');
        RunMode(Observer, 'mode5_view_desc_rowA', 5, 'A');
        RunMode(Observer, 'mode6_name_Z_rowB', 6, 'B');
        Observer.Expect('mode0_no_prior_view_rowB', 'mode=0 count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(B)) marked=No;');
        Observer.Expect('mode1_range_no_B_rowB', 'mode=1 count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(B)) marked=No;');
        Observer.Expect('mode1_range_no_B_rowA', 'mode=1 count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(A)) marked=No;');
        Observer.Expect('mode2_filter_qty_ge2_rowB', 'mode=2 count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(B)) marked=No;');
        Observer.Expect('mode2_filter_qty_ge2_rowA', 'mode=2 count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(A)) marked=No;');
        Observer.Expect('mode3_range_A_B_rowB', 'mode=3 count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(B)) marked=No;');
        Observer.Expect('mode3_range_A_B_rowC', 'mode=3 count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(C)) marked=No;');
        Observer.Expect('mode4_marked_C_rowB', 'mode=4 count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(B)) marked=Yes;');
        Observer.Expect('mode4_marked_C_rowC', 'mode=4 count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(C)) marked=Yes;');
        Observer.Expect('mode5_view_desc_rowB', 'mode=5 count=1 view=VERSION(1) SORTING(Field3) ORDER(1) WHERE(Field1=1(B)) marked=No;');
        Observer.Expect('mode5_view_desc_rowA', 'mode=5 count=1 view=VERSION(1) SORTING(Field3) ORDER(1) WHERE(Field1=1(A)) marked=No;');
        Observer.Expect('mode6_name_Z_rowB', 'mode=6 count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(B)) marked=No;');
        Observer.Verify();
    end;

    [Test]
    procedure P130_SelectionFilter_IntoPageRec()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
        List: TestPage "LT P130 Sel List";
    begin
        Log.Seed();
        List.OpenView();
        List.GoToKey('B');
        List.ActSelRec.Invoke();
        Observer.Observe('plain', Log.Take());
        Observer.Observe('current_after', List."No.".Value());
        List.Next();
        Observer.Observe('next_after', List."No.".Value());
        List.First();
        Observer.Observe('first_after', List."No.".Value());
        List.Close();

        Log.Seed();
        List.OpenView();
        List.Filter.SetFilter(Qty, '>=2');
        List.First();
        List.ActSelRec.Invoke();
        Observer.Observe('page_filter', Log.Take());
        Observer.Observe('page_filter_current_after', List."No.".Value());
        List.Last();
        Observer.Observe('page_filter_last_after', List."No.".Value());
        List.Close();
        Observer.Expect('plain', 'before rec=B view=VERSION(1) SORTING(Field1);after rec=B count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(B));');
        Observer.Expect('current_after', 'B');
        Observer.Expect('next_after', 'B');
        Observer.Expect('first_after', 'B');
        Observer.Expect('page_filter', 'before rec=B view=VERSION(1) SORTING(Field1) WHERE(Field3=1(>=2));after rec=B count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(B));');
        Observer.Expect('page_filter_current_after', 'B');
        Observer.Expect('page_filter_last_after', 'B');
        Observer.Verify();
    end;

    [Test]
    procedure P130_SelectionFilter_IntoPageGlobal_CalledTwice()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
        List: TestPage "LT P130 Sel List";
    begin
        Log.Seed();
        List.OpenView();
        List.First();
        List.ActSelGlobal.Invoke();
        List.Next();
        List.ActSelGlobal.Invoke();
        List.Last();
        List.ActSelGlobal.Invoke();
        Observer.Observe('three_calls', Log.Take());
        List.Close();

        Log.Seed();
        List.OpenView();
        List.GoToKey('C');
        List.ActSelGlobal.Invoke();
        List.GoToKey('A');
        List.ActSelGlobal.Invoke();
        Observer.Observe('C_then_A', Log.Take());
        List.Close();
        Observer.Expect('three_calls', 'global count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(A));global count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(B));global count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(C));');
        Observer.Expect('C_then_A', 'global count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(C));global count=1 view=VERSION(1) SORTING(Field1) WHERE(Field1=1(A));');
        Observer.Verify();
    end;
}
