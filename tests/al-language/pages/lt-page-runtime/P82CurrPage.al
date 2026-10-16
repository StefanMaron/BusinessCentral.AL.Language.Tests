// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P82 Card (71187), LT P82 List (71188), LT P82 Item (71184), LT P82 Log (71186) from P82Fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CurrPage.Update(false/true/default), Close, Editable, SaveRecord, SetSelectionFilter, ObjectId(true/false), Caption (read and assigned) called from page actions, with the trigger log and the stored rows
// BC versions: 29 (27 and 28 by CI)

codeunit 71202 "LT P82 CurrPage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT P82 Item";
        Log: Codeunit "LT P82 Log";
    begin
        Item.DeleteAll();
        Log.Reset();
        Item."No." := 'A';
        Item.Name := 'Alpha';
        Item.Qty := 1;
        Item.Insert();
        Item."No." := 'B';
        Item.Name := 'Beta';
        Item.Qty := 2;
        Item.Insert();
        Item."No." := 'C';
        Item.Name := 'Gamma';
        Item.Qty := 3;
        Item.Insert();
    end;

    [Test]
    procedure Update_False_KeepsPendingEdit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Item: Record "LT P82 Item";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('A');
        Observer.Observe('log-open', Log.Dump());
        Log.Reset();
        Card.NameCtl.SetValue('Edited');
        Observer.Observe('log-after-setvalue', Log.Dump());
        Log.Reset();
        Card.ActUpdate.Invoke();
        Observer.Observe('log-after-update-false', Log.Dump());
        Observer.Observe('name-on-page', Card.NameCtl.Value());
        Item.Get('A');
        Observer.Observe('name-stored', Item.Name);
        Card.Close();
        Item.Get('A');
        Observer.Observe('name-stored-after-close', Item.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Update_True_SavesPendingEdit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Item: Record "LT P82 Item";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('B');
        Card.NameCtl.SetValue('Edited B');
        Log.Reset();
        Card.ActUpdateSave.Invoke();
        Observer.Observe('log-after-update-true', Log.Dump());
        Item.Get('B');
        Observer.Observe('name-stored', Item.Name);
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Update_Default_Overload()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Item: Record "LT P82 Item";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('B');
        Card.NameCtl.SetValue('Edited default');
        Log.Reset();
        Card.ActUpdateDefault.Invoke();
        Observer.Observe('log-after-update', Log.Dump());
        Item.Get('B');
        Observer.Observe('name-stored', Item.Name);
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Update_PicksUpRowChangedBehindThePage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Item: Record "LT P82 Item";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('C');
        Observer.Observe('name-before', Card.NameCtl.Value());
        Item.Get('C');
        Item.Name := 'Changed behind';
        Item.Modify();
        Observer.Observe('name-before-update', Card.NameCtl.Value());
        Card.ActUpdate.Invoke();
        Observer.Observe('name-after-update', Card.NameCtl.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Close_FromAction_Triggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey('A');
        Log.Reset();
        Card.ActClose.Invoke();
        Observer.Observe('log-after-currpage-close', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure Close_TestPageClose_Triggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Log.Reset();
        Card.Close();
        Observer.Observe('log-after-testpage-close', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure Close_ThenUseTestPage()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.ActClose.Invoke();
        asserterror Observer.Observe('name-after-close', Card.NameCtl.Value());
        Observer.ObserveError('value-after-currpage-close');
        asserterror Card.ActUpdate.Invoke();
        Observer.ObserveError('invoke-after-currpage-close');
        asserterror Card.Close();
        Observer.ObserveError('close-after-currpage-close');
        Observer.Finish();
    end;

    [Test]
    procedure Editable_ReadInTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.ActEditRead.Invoke();
        Card.ActEditF.Invoke();
        Card.ActEditRead.Invoke();
        Card.ActEditT.Invoke();
        Card.ActEditRead.Invoke();
        Card.Close();
        Observer.Observe('log', Log.Dump());
        Log.Reset();
        Card.OpenView();
        Card.ActEditRead.Invoke();
        Card.ActEditT.Invoke();
        Card.ActEditRead.Invoke();
        Card.Close();
        Observer.Observe('log-view', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure SaveRecord_StoresPendingEdit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Item: Record "LT P82 Item";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('A');
        Card.NameCtl.SetValue('Saved by action');
        Item.Get('A');
        Observer.Observe('stored-before', Item.Name);
        Card.ActSave.Invoke();
        Item.Get('A');
        Observer.Observe('stored-after', Item.Name);
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SaveRecord_InViewMode()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.ActSave.Invoke();
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SaveRecord_NewRecordWithoutKey()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P82 Item";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenNew();
        Card.NameCtl.SetValue('No key yet');
        Card.ActSave.Invoke();
        Observer.Observe('save-without-key', 'no error');
        Observer.Observe('count', Format(Item.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure SetSelectionFilter_OnTheCurrentRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('log-open', Log.Dump());
        Log.Reset();
        List.First();
        List.ActSelFilter.Invoke();
        List.Next();
        List.ActSelFilter.Invoke();
        List.Last();
        List.ActSelFilter.Invoke();
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SetSelectionFilter_WithPageFilter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.OpenView();
        List.Filter.SetFilter(Qty, '>=2');
        List.First();
        List.ActSelFilter.Invoke();
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SetSelectionFilter_EmptyPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Item: Record "LT P82 Item";
        List: TestPage "LT P82 List";
    begin
        Item.DeleteAll();
        Log.Reset();
        List.OpenView();
        List.ActSelFilter.Invoke();
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ObjectId_WithAndWithoutName()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.ActObjId.Invoke();
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Caption_ReadAndAssign()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('testpage-caption-before', Card.Caption());
        Card.ActCaption.Invoke();
        Card.ActSetCaption.Invoke();
        Observer.Observe('testpage-caption-after', Card.Caption());
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Card.OpenView();
        Observer.Observe('testpage-caption-reopened', Card.Caption());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Caption_List_Open()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('list-caption', List.Caption());
        List.Close();
        List.OpenEdit();
        Observer.Observe('list-caption-edit', List.Caption());
        List.Close();
        Observer.Finish();
    end;

    [Test]
    procedure LookupMode_ReadInAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.OpenView();
        List.ActLookupMode.Invoke();
        List.Close();
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure ActionError_Surfaces()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey('B');
        asserterror Card.ActErr.Invoke();
        Observer.ObserveError('action-error');
        Observer.Observe('no-after', Card.NoCtl.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure OnQueryClosePage_CloseActionText()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.Close();
        Observer.Observe('log-edit', Log.Dump());
        Log.Reset();
        Card.OpenNew();
        Card.NoCtl.SetValue('QC1');
        Card.Close();
        Observer.Observe('log-new', Log.Dump());
        Observer.Finish();
    end;
}
