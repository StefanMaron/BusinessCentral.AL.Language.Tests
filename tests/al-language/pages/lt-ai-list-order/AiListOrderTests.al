// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT AI Row / Log Mgt / List pages (AiFixtures.al)
// Probe: trigger order of list pages: Update with the current row kept, Update on an unchanged view, with and without OnAfterGetCurrRecord,
//        Update after the view dropped the current row (no OnNextRecord, no row after), Next past the last row, cursor not on the first row, 20+ rows.
// Object ids 78860 - 78862.

codeunit 78860 "LT AI List Update Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Keep_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1003')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.KeepFilter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Same_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1003')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.SameView.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Keep_NavCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Curr";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1003')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.KeepFilter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Same_NavCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Curr";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1003')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.SameView.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Same_Nav_OnOpenRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        P.SameView.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Same_NavCurr_OnOpenRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Curr";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        P.SameView.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Keep_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Plain";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1003')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.KeepFilter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Same_PlainCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List PlainCurr";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1003')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.SameView.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure DropCurrent_RowsAfter_FindOnly()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List FindOnly";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1003')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.DropCurrentRowsAfter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure DropCurrent_RowsAfter_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Plain";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1003')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.DropCurrentRowsAfter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure DropCurrent_RowsAfter_PlainCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List PlainCurr";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1003')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.DropCurrentRowsAfter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure DropCurrent_NoRowsAfter_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1012')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.DropCurrentNoRowsAfter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure DropCurrent_NoRowsAfter_NavCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Curr";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1012')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.DropCurrentNoRowsAfter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure DropCurrent_NoRowsAfter_FindOnly()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List FindOnly";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1012')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.DropCurrentNoRowsAfter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure DropCurrent_NoRowsAfter_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Plain";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1012')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.DropCurrentNoRowsAfter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Finish();
    end;
}

codeunit 78861 "LT AI List Navigation Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Next_OneRow_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(1);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('next1', Format(P.Next()));
        Observer.Observe('next1_log', Log.Dump());
        Observer.Observe('next1_no', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next2', Format(P.Next()));
        Observer.Observe('next2_log', Log.Dump());
        Observer.Observe('next2_no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Next_OneRow_NavCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Curr";
    begin
        Log.Seed(1);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('next1', Format(P.Next()));
        Observer.Observe('next1_log', Log.Dump());
        Observer.Observe('next1_no', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next2', Format(P.Next()));
        Observer.Observe('next2_log', Log.Dump());
        Observer.Observe('next2_no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Next_TwoRows_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(2);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('next1', Format(P.Next()));
        Observer.Observe('next1_log', Log.Dump());
        Observer.Observe('next1_no', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next2', Format(P.Next()));
        Observer.Observe('next2_log', Log.Dump());
        Observer.Observe('next2_no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Next_TwoRows_NavCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Curr";
    begin
        Log.Seed(2);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('next1', Format(P.Next()));
        Observer.Observe('next1_log', Log.Dump());
        Observer.Observe('next1_no', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next2', Format(P.Next()));
        Observer.Observe('next2_log', Log.Dump());
        Observer.Observe('next2_no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Next_OneRow_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Plain";
    begin
        Log.Seed(1);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('next1', Format(P.Next()));
        Observer.Observe('next1_log', Log.Dump());
        Observer.Observe('next1_no', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next2', Format(P.Next()));
        Observer.Observe('next2_log', Log.Dump());
        Observer.Observe('next2_no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Next_TwoRows_PlainCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List PlainCurr";
    begin
        Log.Seed(2);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('next1', Format(P.Next()));
        Observer.Observe('next1_log', Log.Dump());
        Observer.Observe('next1_no', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next2', Format(P.Next()));
        Observer.Observe('next2_log', Log.Dump());
        Observer.Observe('next2_no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Next_EmptyList_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(0);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_log', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure GoToRecord_BeforeAnyNavigation_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        Row: Record "LT AI Row";
        P: TestPage "LT AI List";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Row.Get('R1007');
        Observer.Observe('goto', Format(P.GoToRecord(Row)));
        Observer.Observe('goto_log', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_log', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure GoToRecord_BeforeAnyNavigation_NavCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        Row: Record "LT AI Row";
        P: TestPage "LT AI List Curr";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Row.Get('R1007');
        Observer.Observe('goto', Format(P.GoToRecord(Row)));
        Observer.Observe('goto_log', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_log', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure OpenOnRow_SetPositionInOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Pos";
    begin
        Log.Seed(12);
        Log.SetStartKey('R1007');
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_log', Log.Dump());
        Log.SetStartKey('');
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure OpenOnRow_SetPositionInOnOpenPage_Next()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Pos";
    begin
        Log.Seed(12);
        Log.SetStartKey('R1007');
        Log.Clear();
        P.OpenView();
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_log', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.SetStartKey('');
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure OpenOnRow_SetPositionInOnOpenPage_LastRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Pos";
    begin
        Log.Seed(12);
        Log.SetStartKey('R1012');
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_log', Log.Dump());
        Log.SetStartKey('');
        P.Close();
        Observer.Finish();
    end;
}

codeunit 78862 "LT AI List Paging Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [PageHandler]
    procedure RunHandler(var P: TestPage "LT AI List")
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Observer.Observe('open', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_log', Log.Dump());
        Observer.Observe('current2', P.NoCtl.Value());
    end;

    [Test]
    [HandlerFunctions('RunHandler')]
    procedure PageRun_RecordOnFifthRow()
    var
        Log: Codeunit "LT AI Log Mgt";
        Row: Record "LT AI Row";
    begin
        Log.Seed(12);
        Log.Clear();
        Row.Get('R1005');
        Page.Run(Page::"LT AI List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RunHandler')]
    procedure PageRun_RecordWithFilterOnFifthRow()
    var
        Log: Codeunit "LT AI Log Mgt";
        Row: Record "LT AI Row";
    begin
        Log.Seed(12);
        Log.Clear();
        Row.SetFilter(Qty, '>=%1', 3);
        Row.Get('R1005');
        Page.Run(Page::"LT AI List", Row);
        Observer.Finish();
    end;

    [Test]
    procedure Paging_TwentyFiveRows_Nav()
    var
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
        Walked: Integer;
    begin
        Log.Seed(25);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('last_log', Log.Dump());
        Observer.Observe('last_no', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_log', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1021')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        while P.Next() do
            Walked += 1;
        Observer.Observe('walked', Format(Walked));
        Observer.Observe('walk_log', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Paging_TwentyFiveRows_UpdateOnRowTwentyOne()
    var
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Curr";
    begin
        Log.Seed(25);
        Log.Clear();
        P.OpenView();
        Observer.Observe('goto', Format(P.GoToKey('R1021')));
        Log.Clear();
        P.SameView.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;
}
