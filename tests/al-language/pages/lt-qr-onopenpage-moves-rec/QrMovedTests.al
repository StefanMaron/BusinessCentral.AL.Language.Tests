// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onopenpage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in QrMovedObjects.al (87260 - 87265)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a page opened WITHOUT a record (TestPage OpenView / OpenEdit, Page.Run, Page.RunModal) whose OnOpenPage moves Rec (Get, FindLast,
//   FindFirst + Next, SetRange + FindLast, SetCurrentKey + Get, a key assigned without a read, Get then a filter that excludes the row):
//   which row the page shows (No.|Name of the TestPage), which triggers ran on the way (log, see QrMovedObjects.al), and where Next and
//   Previous go from there. Card and List, on a normal table and on a temporary source that OnOpenPage fills.
//   BC (27.5, 28.5, 29.0 alike): the page opens on the row OnOpenPage left Rec on (C after Get, D after FindLast, B after FindFirst+Next,
//   C after only assigning the key), in the view and key OnOpenPage set; a Rec outside the filter it set opens on the nearest row of the view
//   (B for C with filter A..B). OnAfterGetRecord and OnAfterGetCurrRecord run for that row (a list also reads its window). A temporary source
//   filled in OnOpenPage opens on the row Rec was left on (D after the inserts). Next past the last row of a list opened by Page.Run or
//   RunModal answers Yes on a new empty row.
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
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenView_FindLast()
    begin
        ViewCard(2, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenView_FindFirstNext()
    begin
        ViewCard(3, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenView_SetRangeFindLast()
    begin
        ViewCard(4, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenView_SetCurrentKeyGet()
    begin
        ViewCard(5, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenView_KeyAssigned()
    begin
        ViewCard(6, false);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenView_GetThenFilterExcludes()
    begin
        ViewCard(7, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:C;R:B;C:B;');
        Observer.Expect('next', 'No|B');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenView_SetRangeFindFirst()
    begin
        ViewCard(8, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenEdit_Get()
    begin
        ViewCard(1, true);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_Get()
    begin
        ViewList(1, false);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_FindLast()
    begin
        ViewList(2, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_FindFirstNext()
    begin
        ViewList(3, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:C;R:D;R:B;R:A;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_SetRangeFindLast()
    begin
        ViewList(4, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_SetCurrentKeyGet()
    begin
        ViewList(5, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:B;R:A;R:B;R:C;R:D;R:B;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;R:A;R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_KeyAssigned()
    begin
        ViewList(6, false);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_GetThenFilterExcludes()
    begin
        ViewList(7, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:C;R:B;R:A;R:B;R:B;C:B;');
        Observer.Expect('next', 'No|B');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_SetRangeFindFirst()
    begin
        ViewList(8, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:C;R:D;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenEdit_Get()
    begin
        ViewList(1, true);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempCard_OpenView_NoMove()
    begin
        ViewTempCard(0, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempCard_OpenView_Get()
    begin
        ViewTempCard(1, false);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempCard_OpenView_FindLast()
    begin
        ViewTempCard(2, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempCard_OpenView_FindFirstNext()
    begin
        ViewTempCard(3, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempCard_OpenView_SetRangeFindLast()
    begin
        ViewTempCard(4, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempList_OpenView_NoMove()
    begin
        ViewTempList(0, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempList_OpenView_Get()
    begin
        ViewTempList(1, false);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempList_OpenView_FindLast()
    begin
        ViewTempList(2, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempList_OpenView_FindFirstNext()
    begin
        ViewTempList(3, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:C;R:D;R:B;R:A;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempList_OpenView_SetRangeFindLast()
    begin
        ViewTempList(4, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure QR_Card_PageRun_Get()
    begin
        Seed(1);
        Page.Run(Page::"LT QR Moved Card");
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure QR_List_PageRun_Get()
    begin
        Seed(1);
        Page.Run(Page::"LT QR Moved List");
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempCardHandler')]
    procedure QR_TempCard_PageRun_Get()
    begin
        Seed(1);
        Page.Run(Page::"LT QR Moved Temp Card");
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempListHandler')]
    procedure QR_TempList_PageRun_NoMove()
    begin
        Seed(0);
        Page.Run(Page::"LT QR Moved Temp List");
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|');
        Observer.Expect('next log', 'C:;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardModalHandler')]
    procedure QR_Card_RunModal_Get()
    begin
        Seed(1);
        Page.RunModal(Page::"LT QR Moved Card");
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListModalHandler')]
    procedure QR_List_RunModal_FindLast()
    begin
        Seed(2);
        Page.RunModal(Page::"LT QR Moved List");
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|');
        Observer.Expect('next log', 'C:;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempListModalHandler')]
    procedure QR_TempList_RunModal_Get()
    begin
        Seed(1);
        Page.RunModal(Page::"LT QR Moved Temp List");
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    // ---- Writer QT (2026-10-22): a temporary Worksheet (and List) that a procedure fills BEFORE Run / RunModal; objects in
    // QtTempWorksheetObjects.al. Which row the page opens on (No.|Name), the triggers on the way, Next and Previous from there. ----

    local procedure QtReadWs(var P: TestPage "LT QT Temp Ws")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    [ModalPageHandler]
    procedure QtModalWs(var P: TestPage "LT QT Temp Ws")
    begin
        QtReadWs(P);
    end;

    local procedure QtRunModalWs(Pos: Text; Lookup: Boolean)
    var
        Pg: Page "LT QT Temp Ws";
    begin
        Log.SetMode(0);
        Pg.SetRows(Pos);
        if Lookup then
            Pg.LookupMode(true);
        Observer.Observe('before run log', Log.Take());
        Pg.RunModal();
        Observer.Observe('after close log', Log.Take());
    end;

    local procedure QtReadWsNext(var P: TestPage "LT QT Temp Ws Next")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    [ModalPageHandler]
    procedure QtModalWsNext(var P: TestPage "LT QT Temp Ws Next")
    begin
        QtReadWsNext(P);
    end;

    local procedure QtRunModalWsNext(Pos: Text; Lookup: Boolean)
    var
        Pg: Page "LT QT Temp Ws Next";
    begin
        Log.SetMode(0);
        Pg.SetRows(Pos);
        if Lookup then
            Pg.LookupMode(true);
        Observer.Observe('before run log', Log.Take());
        Pg.RunModal();
        Observer.Observe('after close log', Log.Take());
    end;

    local procedure QtReadWsFind(var P: TestPage "LT QT Temp Ws Find Next")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    [ModalPageHandler]
    procedure QtModalWsFind(var P: TestPage "LT QT Temp Ws Find Next")
    begin
        QtReadWsFind(P);
    end;

    local procedure QtRunModalWsFind(Pos: Text; Lookup: Boolean)
    var
        Pg: Page "LT QT Temp Ws Find Next";
    begin
        Log.SetMode(0);
        Pg.SetRows(Pos);
        if Lookup then
            Pg.LookupMode(true);
        Observer.Observe('before run log', Log.Take());
        Pg.RunModal();
        Observer.Observe('after close log', Log.Take());
    end;

    local procedure QtReadList(var P: TestPage "LT QT Temp List")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    [ModalPageHandler]
    procedure QtModalList(var P: TestPage "LT QT Temp List")
    begin
        QtReadList(P);
    end;

    local procedure QtRunModalList(Pos: Text; Lookup: Boolean)
    var
        Pg: Page "LT QT Temp List";
    begin
        Log.SetMode(0);
        Pg.SetRows(Pos);
        if Lookup then
            Pg.LookupMode(true);
        Observer.Observe('before run log', Log.Take());
        Pg.RunModal();
        Observer.Observe('after close log', Log.Take());
    end;

    local procedure QtRunWs(Pos: Text)
    var
        Pg: Page "LT QT Temp Ws";
        P: TestPage "LT QT Temp Ws";
    begin
        Log.SetMode(0);
        Pg.SetRows(Pos);
        Log.Take();
        P.Trap();
        Pg.Run();
        QtReadWs(P);
        P.Close();
        Observer.Observe('after close log', Log.Take());
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_RunModal_D_NoMove()
    begin
        QtRunModalWs('', false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_RunModal_A()
    begin
        QtRunModalWs('A', false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_RunModal_B()
    begin
        QtRunModalWs('B', false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_RunModal_BB_Between()
    begin
        QtRunModalWs('BB', false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_RunModal_E_PastLast()
    begin
        QtRunModalWs('E', false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_RunModal_ByName_B()
    begin
        QtRunModalWs('NAME:B', false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_Lookup_A()
    begin
        QtRunModalWs('A', true);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_Lookup_B()
    begin
        QtRunModalWs('B', true);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_Lookup_BB_Between()
    begin
        QtRunModalWs('BB', true);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalWsNext')]
    procedure QT_TempWsNext_RunModal_A()
    begin
        QtRunModalWsNext('A', false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalWsNext')]
    procedure QT_TempWsNext_RunModal_B()
    begin
        QtRunModalWsNext('B', false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalWsNext')]
    procedure QT_TempWsNext_RunModal_BB_Between()
    begin
        QtRunModalWsNext('BB', false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalWsNext')]
    procedure QT_TempWsNext_Lookup_B()
    begin
        QtRunModalWsNext('B', true);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalWsFind')]
    procedure QT_TempWsFind_RunModal_B()
    begin
        QtRunModalWsFind('B', false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalWsFind')]
    procedure QT_TempWsFind_RunModal_BB_Between()
    begin
        QtRunModalWsFind('BB', false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalList')]
    procedure QT_TempList_RunModal_B()
    begin
        QtRunModalList('B', false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalList')]
    procedure QT_TempList_RunModal_BB_Between()
    begin
        QtRunModalList('BB', false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QtModalList')]
    procedure QT_TempList_Lookup_B()
    begin
        QtRunModalList('B', true);
        Observer.Finish();
    end;

    [Test]
    procedure QT_TempWs_Run_B()
    begin
        QtRunWs('B');
        Observer.Finish();
    end;

    [Test]
    procedure QT_TempWs_Run_BB_Between()
    begin
        QtRunWs('BB');
        Observer.Finish();
    end;

    [Test]
    procedure QT_TempWs_Run_A()
    begin
        QtRunWs('A');
        Observer.Finish();
    end;
}
