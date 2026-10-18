// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpageview-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT F3 Head / Line / Part Log / Part / Host pages (F3PartFixtures.al)
// Probe: (1) a part whose SubPageView names its linked field with filter(...), <> or const(...), with one host row and with four: the part's reads and filter at open, and after host moves.
//        (2) the cursor mechanism of the part (OnFindRecord(Which) and OnNextRecord(Steps) per read) at open and after a host move.
//        (3) page code reading a part of a Page variable that was never opened, or that ran modally and closed.
// Object ids 67093 - 67094.

codeunit 67093 "LT F3 Part Reads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Step(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Log: Codeunit "LT F3 Part Log";
    begin
        Observer.Observe(Name, Log.Dump());
        Log.Reset();
    end;

    [Test]
    procedure FilterView_OneHost_OpenAndMoves()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Part Log";
        Doc: TestPage "LT F3 Host Filter";
    begin
        Log.Seed(1);
        Doc.OpenView();
        Step(Observer, 'open');
        Observer.Observe('next', Format(Doc.Next()));
        Step(Observer, 'after_next');
        Doc.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FilterView_FourHosts_OpenAndMoves()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Part Log";
        Doc: TestPage "LT F3 Host Filter";
    begin
        Log.Seed(4);
        Doc.OpenView();
        Step(Observer, 'open');
        Observer.Observe('next1', Format(Doc.Next()));
        Step(Observer, 'after_next1');
        Observer.Observe('next2', Format(Doc.Next()));
        Step(Observer, 'after_next2');
        Observer.Observe('next3', Format(Doc.Next()));
        Step(Observer, 'after_next3');
        Doc.Close();
        Observer.Finish();
    end;

    [Test]
    procedure NotEqualView_OneHost_OpenAndMoves()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Part Log";
        Doc: TestPage "LT F3 Host NotEqual";
    begin
        Log.Seed(1);
        Doc.OpenView();
        Step(Observer, 'open');
        Observer.Observe('next', Format(Doc.Next()));
        Step(Observer, 'after_next');
        Doc.Close();
        Observer.Finish();
    end;

    [Test]
    procedure NotEqualView_FourHosts_OpenAndMoves()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Part Log";
        Doc: TestPage "LT F3 Host NotEqual";
    begin
        Log.Seed(4);
        Doc.OpenView();
        Step(Observer, 'open');
        Observer.Observe('next1', Format(Doc.Next()));
        Step(Observer, 'after_next1');
        Observer.Observe('next2', Format(Doc.Next()));
        Step(Observer, 'after_next2');
        Observer.Observe('next3', Format(Doc.Next()));
        Step(Observer, 'after_next3');
        Doc.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SameFieldView_OneHost_Cursor()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Part Log";
        Doc: TestPage "LT F3 Host Same";
    begin
        Log.Seed(1);
        Doc.OpenView();
        Step(Observer, 'open');
        Observer.Observe('next', Format(Doc.Next()));
        Step(Observer, 'after_next');
        Doc.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SameFieldView_FourHosts_Cursor()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Part Log";
        Doc: TestPage "LT F3 Host Same";
    begin
        Log.Seed(4);
        Doc.OpenView();
        Step(Observer, 'open');
        Observer.Observe('next1', Format(Doc.Next()));
        Step(Observer, 'after_next1');
        Observer.Observe('next2', Format(Doc.Next()));
        Step(Observer, 'after_next2');
        Observer.Observe('last', Format(Doc.Last()));
        Step(Observer, 'after_last');
        Observer.Observe('previous', Format(Doc.Previous()));
        Step(Observer, 'after_previous');
        Observer.Observe('first', Format(Doc.First()));
        Step(Observer, 'after_first');
        Doc.Close();
        Observer.Finish();
    end;
}

codeunit 67094 "LT F3 Part Of Closed Page"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [ModalPageHandler]
    procedure HostHandler(var P: TestPage "LT F3 Host Filter")
    begin
        Observer.Observe('h_code', P.CodeCtl.Value());
        Observer.Observe('h_goto', Format(P.Lines.GoToKey('H1', 20000)));
        Observer.Observe('h_line', P.Lines.LineNoCtl.Value());
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryReadPart(var Host: Page "LT F3 Host Filter"; var Result: Text)
    begin
        Result := Host.ReadPart();
    end;

    [TryFunction]
    local procedure TrySelectionCount(var Host: Page "LT F3 Delete List"; var Result: Text)
    begin
        Result := Host.SelectedFilterCount();
    end;

    local procedure ObserveRead(Name: Text; var Host: Page "LT F3 Host Filter")
    var
        Result: Text;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryReadPart(Host, Result);
        Observer.Observe(Name + '_ok', Format(Ok));
        Observer.Observe(Name + '_result', Result);
        if not Ok then begin
            Observer.Observe(Name + '_error', GetLastErrorText());
            Observer.Observe(Name + '_code', GetLastErrorCode());
        end;
    end;

    [Test]
    procedure PageVariableNeverOpened_PartRead()
    var
        Host: Page "LT F3 Host Filter";
        Log: Codeunit "LT F3 Part Log";
    begin
        Log.Seed(2);
        ObserveRead('never_opened', Host);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HostHandler')]
    procedure PageVariableRanModalAndClosed_PartRead()
    var
        Host: Page "LT F3 Host Filter";
        Head: Record "LT F3 Head";
        Log: Codeunit "LT F3 Part Log";
        Result: Action;
    begin
        Log.Seed(2);
        Head.Get('H1');
        Host.SetRecord(Head);
        Result := Host.RunModal();
        Observer.Observe('action', Format(Result));
        ObserveRead('after_modal', Host);
        Observer.Finish();
    end;

    [Test]
    procedure SelectionFilter_PageVariableNeverOpened()
    var
        Host: Page "LT F3 Delete List";
        Log: Codeunit "LT F3 Log Mgt";
        Result: Text;
        Ok: Boolean;
    begin
        Log.Seed(3);
        ClearLastError();
        Ok := TrySelectionCount(Host, Result);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('result', Result);
        if not Ok then begin
            Observer.Observe('error', GetLastErrorText());
            Observer.Observe('code', GetLastErrorCode());
        end;
        Observer.Finish();
    end;
}
