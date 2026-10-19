// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-class
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 81850, pages 81851-81853 (UnopenedFixtures.al)
// Probe: corpus issue 673 item 1 (al-runtime-rs #292). Every literal asserted below is what BC 27.5, 28.5 and 29.0 produced in the corpus CI.
// Facts: CurrPage methods (Update(false/true), SaveRecord, Activate, Caption, Editable, SetSelectionFilter, Rec) run by a procedure of a Page variable that was never opened: ListPart with a temporary Integer source, List and Card with a table; called directly and through a TryFunction; with SetRecord/SetTableView before; RunModal of the same variable afterwards.
// BC versions: 27+

codeunit 81855 "LT BL Unopened CurrPage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerSeen: Text;

    local procedure Seed()
    var
        Row: Record "LT BL Unopened Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
    end;

    // The al-runtime-rs #292 repro: a ListPart with a temporary Integer source, the procedure called directly (no TryFunction).
    [Test]
    procedure Direct_Part_UpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
        P: Page "LT BL Unopened Part";
    begin
        Observer.Observe('log', P.Act('update-false'));
        Observer.Finish();
    end;

    [Test]
    procedure Direct_Part_UpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
        P: Page "LT BL Unopened Part";
    begin
        Observer.Observe('log', P.Act('update-true'));
        Observer.Finish();
    end;

    [Test]
    procedure Direct_List_UpdateFalse_Twice()
    var
        Observer: Codeunit "Probe Observer";
        P: Page "LT BL Unopened List";
    begin
        Seed();
        Observer.Observe('first', P.Act('update-false'));
        Observer.Observe('second', P.Act('update-true'));
        Observer.Finish();
    end;

    local procedure RunPart(var Observer: Codeunit "Probe Observer"; Op: Text)
    var
        P: Page "LT BL Unopened Part";
        Log: Text;
    begin
        ClearLastError();
        if TryPart(P, Op, Log) then
            Observer.Observe(Op, 'ok ' + Log)
        else
            Observer.Observe(Op, 'error [' + GetLastErrorText() + '] [' + GetLastErrorCode() + '] ' + Log);
    end;

    [TryFunction]
    local procedure TryPart(var P: Page "LT BL Unopened Part"; Op: Text; var Log: Text)
    begin
        Log := P.Act(Op);
    end;

    [Test]
    procedure Never_Opened_Part_TryFunction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RunPart(Observer, 'update-false');
        RunPart(Observer, 'update-true');
        RunPart(Observer, 'saverecord');
        RunPart(Observer, 'activate');
        RunPart(Observer, 'activate-true');
        RunPart(Observer, 'caption-get');
        RunPart(Observer, 'caption-set');
        RunPart(Observer, 'editable-get');
        RunPart(Observer, 'editable-set');
        RunPart(Observer, 'selection');
        RunPart(Observer, 'rec');
        Observer.Finish();
    end;

    local procedure RunList(var Observer: Codeunit "Probe Observer"; Op: Text)
    var
        P: Page "LT BL Unopened List";
        Log: Text;
    begin
        ClearLastError();
        if TryList(P, Op, Log) then
            Observer.Observe(Op, 'ok ' + Log)
        else
            Observer.Observe(Op, 'error [' + GetLastErrorText() + '] [' + GetLastErrorCode() + '] ' + Log);
    end;

    [TryFunction]
    local procedure TryList(var P: Page "LT BL Unopened List"; Op: Text; var Log: Text)
    begin
        Log := P.Act(Op);
    end;

    [Test]
    procedure Never_Opened_List_TryFunction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RunList(Observer, 'update-false');
        RunList(Observer, 'update-true');
        RunList(Observer, 'saverecord');
        RunList(Observer, 'activate');
        RunList(Observer, 'activate-true');
        RunList(Observer, 'caption-get');
        RunList(Observer, 'caption-set');
        RunList(Observer, 'editable-get');
        RunList(Observer, 'editable-set');
        RunList(Observer, 'selection');
        RunList(Observer, 'rec');
        Observer.Finish();
    end;

    local procedure RunCard(var Observer: Codeunit "Probe Observer"; Op: Text)
    var
        P: Page "LT BL Unopened Card";
        Log: Text;
    begin
        ClearLastError();
        if TryCard(P, Op, Log) then
            Observer.Observe(Op, 'ok ' + Log)
        else
            Observer.Observe(Op, 'error [' + GetLastErrorText() + '] [' + GetLastErrorCode() + '] ' + Log);
    end;

    [TryFunction]
    local procedure TryCard(var P: Page "LT BL Unopened Card"; Op: Text; var Log: Text)
    begin
        Log := P.Act(Op);
    end;

    [Test]
    procedure Never_Opened_Card_TryFunction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RunCard(Observer, 'update-false');
        RunCard(Observer, 'update-true');
        RunCard(Observer, 'saverecord');
        RunCard(Observer, 'activate');
        RunCard(Observer, 'activate-true');
        RunCard(Observer, 'caption-get');
        RunCard(Observer, 'caption-set');
        RunCard(Observer, 'editable-get');
        RunCard(Observer, 'editable-set');
        RunCard(Observer, 'selection');
        RunCard(Observer, 'rec');
        Observer.Finish();
    end;

    [Test]
    procedure SetRecord_Then_Update_List()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Unopened Row";
        P: Page "LT BL Unopened List";
    begin
        Seed();
        Row.Get(2);
        P.SetRecord(Row);
        Observer.Observe('rec-before', P.Act('rec'));
        Observer.Observe('update-false', P.Act('update-false'));
        Observer.Observe('rec-after', P.Act('rec'));
        Observer.Finish();
    end;

    [Test]
    procedure SetTableView_Then_Update_Card()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Unopened Row";
        P: Page "LT BL Unopened Card";
    begin
        Seed();
        Row.SetRange(Id, 2);
        P.SetTableView(Row);
        Observer.Observe('rec-before', P.Act('rec'));
        Observer.Observe('update-true', P.Act('update-true'));
        Observer.Observe('rec-after', P.Act('rec'));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure ReadCardModal(var P: TestPage "LT BL Unopened Card")
    begin
        HandlerSeen := 'card id=' + P.KeyCtl.Value();
        P.Close();
    end;

    [Test]
    [HandlerFunctions('ReadCardModal')]
    procedure Update_Then_RunModal_Card()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Unopened Row";
        P: Page "LT BL Unopened Card";
        Action: Action;
    begin
        Seed();
        Row.Get(2);
        P.SetRecord(Row);
        Observer.Observe('update-false', P.Act('update-false'));
        HandlerSeen := '';
        Action := P.RunModal();
        Observer.Observe('handler', HandlerSeen);
        Observer.Observe('action', Format(Action));
        Observer.Observe('rec-after-close', P.Act('rec'));
        Observer.Finish();
    end;
}
