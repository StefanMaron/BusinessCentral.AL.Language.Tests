// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-overview
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG List (70135), LT PnG Item (70130), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row 59 (TestPage): a page that showed no row shows one when page code left Rec on a stored row that the view admits and that was not stored before the action
// Facts: First()/Last()/value of a list opened on an empty table or a filter that admits nothing, after an action that inserts through Rec, through another variable, with CurrPage.Update, or only positions Rec on an existing row
// BC versions: 29 (27 and 28 by CI)

codeunit 70176 "LT PnG Show Row"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedOne()
    var
        Item: Record "LT PnG Item";
    begin
        Item.DeleteAll();
        Item."No." := 'S1';
        Item.Name := 'Seed';
        Item.Qty := 1;
        Item.Insert();
    end;

    [Test]
    procedure EmptyListInsertViaRec()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Item.DeleteAll();
        Log.Reset();
        List.OpenEdit();
        Observer.Observe('first-before', Format(List.First()));
        List.InsertViaRec.Invoke();
        Observer.Observe('stored-after', Format(Item.Count()));
        Observer.Observe('first-after', Format(List.First()));
        Observer.Observe('no-after', List.NoCtl.Value());
        Observer.Observe('name-after', List.NameCtl.Value());
        Observer.Observe('next-after', Format(List.Next()));
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Expect('first-before', 'No');
        Observer.Expect('stored-after', '1');
        Observer.Expect('first-after', 'Yes');
        Observer.Expect('no-after', 'NEW1');
        Observer.Expect('name-after', 'Created');
        Observer.Expect('next-after', 'Yes');
        Observer.Expect('log', 'List.OnInit;List.OnOpenPage;List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,);List.AGR(NEW1,Created);List.AGR(NEW1,Created);List.AGR(NEW1,Created);List.AGCR(NEW1,NEW1);List.OnNewRecord;List.AGCR(,)');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyListInsertViaOtherVariable()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Item.DeleteAll();
        Log.Reset();
        List.OpenEdit();
        List.InsertViaOtherVar.Invoke();
        Observer.Observe('stored-after', Format(Item.Count()));
        Observer.Observe('first-after', Format(List.First()));
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Expect('stored-after', '1');
        Observer.Expect('first-after', 'Yes');
        Observer.Expect('log', 'List.OnInit;List.OnOpenPage;List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,);List.AGR(NEW2,Created);List.AGR(NEW2,Created);List.AGCR(NEW2,);List.OnNewRecord;List.AGCR(,);List.AGR(NEW2,Created);List.AGR(NEW2,Created);List.AGCR(NEW2,NEW2)');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyListInsertViaRecAndUpdate()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Item.DeleteAll();
        Log.Reset();
        List.OpenEdit();
        List.InsertViaRecAndUpdate.Invoke();
        Observer.Observe('stored-after', Format(Item.Count()));
        Observer.Observe('first-after', Format(List.First()));
        Observer.Observe('no-after', List.NoCtl.Value());
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Expect('stored-after', '1');
        Observer.Expect('first-after', 'Yes');
        Observer.Expect('no-after', 'NEW3');
        Observer.Expect('log', 'List.OnInit;List.OnOpenPage;List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,);List.AGR(NEW3,Created);List.AGR(NEW3,Created);List.AGR(NEW3,Created);List.AGCR(NEW3,NEW3)');
        Observer.Verify();
    end;

    [Test]
    procedure FilteredEmptyListPositionOnStoredRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        SeedOne();
        Log.Reset();
        List.OpenEdit();
        List.Filter.SetFilter(Name, 'NoSuchName');
        Observer.Observe('first-filtered', Format(List.First()));
        List.PositionOnStoredRow.Invoke();
        Observer.Observe('first-after', Format(List.First()));
        Observer.Observe('no-after', List.NoCtl.Value());
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Expect('first-filtered', 'No');
        Observer.Expect('first-after', 'No');
        Observer.Expect('no-after', '');
        Observer.Expect('log', 'List.OnInit;List.OnOpenPage;List.AGR(S1,Seed);List.AGR(S1,Seed);List.AGCR(S1,);List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,)');
        Observer.Verify();
    end;

    [Test]
    procedure ViewModeEmptyListInsertViaRec()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        List: TestPage "LT PnG List";
    begin
        Item.DeleteAll();
        List.OpenView();
        List.InsertViaRec.Invoke();
        Observer.Observe('stored-after', Format(Item.Count()));
        Observer.Observe('first-after', Format(List.First()));
        List.Close();
        Observer.Expect('stored-after', '1');
        Observer.Expect('first-after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure NonEmptyListInsertViaRec()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        SeedOne();
        Log.Reset();
        List.OpenEdit();
        List.InsertViaRec.Invoke();
        Observer.Observe('stored-after', Format(Item.Count()));
        Observer.Observe('current-after', List.NoCtl.Value());
        Observer.Observe('first-after', Format(List.First()));
        Observer.Observe('first-no', List.NoCtl.Value());
        Observer.Observe('next-after', Format(List.Next()));
        Observer.Observe('next-no', List.NoCtl.Value());
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Expect('stored-after', '2');
        Observer.Expect('current-after', 'NEW1');
        Observer.Expect('first-after', 'Yes');
        Observer.Expect('first-no', 'NEW1');
        Observer.Expect('next-after', 'Yes');
        Observer.Expect('next-no', 'S1');
        Observer.Expect('log', 'List.OnInit;List.OnOpenPage;List.AGR(S1,Seed);List.AGR(S1,Seed);List.AGCR(S1,);List.AGR(S1,Seed);List.AGR(NEW1,Created);List.AGR(NEW1,Created);List.AGR(S1,Seed);List.AGR(NEW1,Created);List.AGR(NEW1,Created);List.AGCR(NEW1,NEW1);List.AGR(S1,Seed);List.AGR(S1,Seed);List.AGCR(S1,NEW1)');
        Observer.Verify();
    end;
}
