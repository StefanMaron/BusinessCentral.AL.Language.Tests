// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onopenpage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in QrMovedObjects.al (87260 - 87265)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a page opened WITHOUT a record (TestPage OpenView / OpenEdit, Page.Run, Page.RunModal) whose OnOpenPage moves Rec (Get, FindLast,
//   FindFirst + Next, SetRange + FindLast, SetCurrentKey + Get, a key assigned without a read, Get then a filter that excludes the row):
//   which row the page shows (No.|Name of the TestPage), which triggers ran on the way (log, see QrMovedObjects.al), and where Next and
//   Previous go from there. Card and List, on a normal table and on a temporary source that OnOpenPage fills.
// BC versions: 27, 28, 29

codeunit 87266 "LT QR Moved Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QR Page Log";

    local procedure Seed(Mode: Integer)
    var
        Row: Record "LT QR Page Row";
    begin
        Row.DeleteAll();
        Log.Fill(Row);
        Log.SetMode(Mode);
    end;

    local procedure ReadCard(var P: TestPage "LT QR Moved Card")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    local procedure ViewCard(Mode: Integer; Edit: Boolean)
    var
        P: TestPage "LT QR Moved Card";
    begin
        Seed(Mode);
        if Edit then
            P.OpenEdit()
        else
            P.OpenView();
        ReadCard(P);
        P.Close();
        Observer.Finish();
    end;

    [PageHandler]
    procedure CardHandler(var P: TestPage "LT QR Moved Card")
    begin
        ReadCard(P);
    end;

    [ModalPageHandler]
    procedure CardModalHandler(var P: TestPage "LT QR Moved Card")
    begin
        ReadCard(P);
    end;

    local procedure ReadList(var P: TestPage "LT QR Moved List")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    local procedure ViewList(Mode: Integer; Edit: Boolean)
    var
        P: TestPage "LT QR Moved List";
    begin
        Seed(Mode);
        if Edit then
            P.OpenEdit()
        else
            P.OpenView();
        ReadList(P);
        P.Close();
        Observer.Finish();
    end;

    [PageHandler]
    procedure ListHandler(var P: TestPage "LT QR Moved List")
    begin
        ReadList(P);
    end;

    [ModalPageHandler]
    procedure ListModalHandler(var P: TestPage "LT QR Moved List")
    begin
        ReadList(P);
    end;

    local procedure ReadTempCard(var P: TestPage "LT QR Moved Temp Card")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    local procedure ViewTempCard(Mode: Integer; Edit: Boolean)
    var
        P: TestPage "LT QR Moved Temp Card";
    begin
        Seed(Mode);
        if Edit then
            P.OpenEdit()
        else
            P.OpenView();
        ReadTempCard(P);
        P.Close();
        Observer.Finish();
    end;

    [PageHandler]
    procedure TempCardHandler(var P: TestPage "LT QR Moved Temp Card")
    begin
        ReadTempCard(P);
    end;

    [ModalPageHandler]
    procedure TempCardModalHandler(var P: TestPage "LT QR Moved Temp Card")
    begin
        ReadTempCard(P);
    end;

    local procedure ReadTempList(var P: TestPage "LT QR Moved Temp List")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    local procedure ViewTempList(Mode: Integer; Edit: Boolean)
    var
        P: TestPage "LT QR Moved Temp List";
    begin
        Seed(Mode);
        if Edit then
            P.OpenEdit()
        else
            P.OpenView();
        ReadTempList(P);
        P.Close();
        Observer.Finish();
    end;

    [PageHandler]
    procedure TempListHandler(var P: TestPage "LT QR Moved Temp List")
    begin
        ReadTempList(P);
    end;

    [ModalPageHandler]
    procedure TempListModalHandler(var P: TestPage "LT QR Moved Temp List")
    begin
        ReadTempList(P);
    end;

    [Test]
    procedure QR_Card_OpenView_Get()
    begin
        ViewCard(1, false);
    end;

    [Test]
    procedure QR_Card_OpenView_FindLast()
    begin
        ViewCard(2, false);
    end;

    [Test]
    procedure QR_Card_OpenView_FindFirstNext()
    begin
        ViewCard(3, false);
    end;

    [Test]
    procedure QR_Card_OpenView_SetRangeFindLast()
    begin
        ViewCard(4, false);
    end;

    [Test]
    procedure QR_Card_OpenView_SetCurrentKeyGet()
    begin
        ViewCard(5, false);
    end;

    [Test]
    procedure QR_Card_OpenView_KeyAssigned()
    begin
        ViewCard(6, false);
    end;

    [Test]
    procedure QR_Card_OpenView_GetThenFilterExcludes()
    begin
        ViewCard(7, false);
    end;

    [Test]
    procedure QR_Card_OpenView_SetRangeFindFirst()
    begin
        ViewCard(8, false);
    end;

    [Test]
    procedure QR_Card_OpenEdit_Get()
    begin
        ViewCard(1, true);
    end;

    [Test]
    procedure QR_List_OpenView_Get()
    begin
        ViewList(1, false);
    end;

    [Test]
    procedure QR_List_OpenView_FindLast()
    begin
        ViewList(2, false);
    end;

    [Test]
    procedure QR_List_OpenView_FindFirstNext()
    begin
        ViewList(3, false);
    end;

    [Test]
    procedure QR_List_OpenView_SetRangeFindLast()
    begin
        ViewList(4, false);
    end;

    [Test]
    procedure QR_List_OpenView_SetCurrentKeyGet()
    begin
        ViewList(5, false);
    end;

    [Test]
    procedure QR_List_OpenView_KeyAssigned()
    begin
        ViewList(6, false);
    end;

    [Test]
    procedure QR_List_OpenView_GetThenFilterExcludes()
    begin
        ViewList(7, false);
    end;

    [Test]
    procedure QR_List_OpenView_SetRangeFindFirst()
    begin
        ViewList(8, false);
    end;

    [Test]
    procedure QR_List_OpenEdit_Get()
    begin
        ViewList(1, true);
    end;

    [Test]
    procedure QR_TempCard_OpenView_NoMove()
    begin
        ViewTempCard(0, false);
    end;

    [Test]
    procedure QR_TempCard_OpenView_Get()
    begin
        ViewTempCard(1, false);
    end;

    [Test]
    procedure QR_TempCard_OpenView_FindLast()
    begin
        ViewTempCard(2, false);
    end;

    [Test]
    procedure QR_TempCard_OpenView_FindFirstNext()
    begin
        ViewTempCard(3, false);
    end;

    [Test]
    procedure QR_TempCard_OpenView_SetRangeFindLast()
    begin
        ViewTempCard(4, false);
    end;

    [Test]
    procedure QR_TempList_OpenView_NoMove()
    begin
        ViewTempList(0, false);
    end;

    [Test]
    procedure QR_TempList_OpenView_Get()
    begin
        ViewTempList(1, false);
    end;

    [Test]
    procedure QR_TempList_OpenView_FindLast()
    begin
        ViewTempList(2, false);
    end;

    [Test]
    procedure QR_TempList_OpenView_FindFirstNext()
    begin
        ViewTempList(3, false);
    end;

    [Test]
    procedure QR_TempList_OpenView_SetRangeFindLast()
    begin
        ViewTempList(4, false);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure QR_Card_PageRun_Get()
    begin
        Seed(1);
        Page.Run(Page::"LT QR Moved Card");
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure QR_List_PageRun_Get()
    begin
        Seed(1);
        Page.Run(Page::"LT QR Moved List");
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TempCardHandler')]
    procedure QR_TempCard_PageRun_Get()
    begin
        Seed(1);
        Page.Run(Page::"LT QR Moved Temp Card");
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TempListHandler')]
    procedure QR_TempList_PageRun_NoMove()
    begin
        Seed(0);
        Page.Run(Page::"LT QR Moved Temp List");
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardModalHandler')]
    procedure QR_Card_RunModal_Get()
    begin
        Seed(1);
        Page.RunModal(Page::"LT QR Moved Card");
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListModalHandler')]
    procedure QR_List_RunModal_FindLast()
    begin
        Seed(2);
        Page.RunModal(Page::"LT QR Moved List");
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TempListModalHandler')]
    procedure QR_TempList_RunModal_Get()
    begin
        Seed(1);
        Page.RunModal(Page::"LT QR Moved Temp List");
        Observer.Finish();
    end;
}
