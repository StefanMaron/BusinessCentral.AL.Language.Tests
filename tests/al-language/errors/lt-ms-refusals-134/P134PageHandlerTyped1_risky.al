// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-pagehandler-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table, pages and log of P134ModalPair.al; test codeunit 74118 (P134). RISKY: a [PageHandler] whose parameter is a Page, not a TestPage, may not compile
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a non-modal [PageHandler] with the single parameter (var P: Page "X"): what it is handed for Page.Run (record, LookupMode, Editable), and what Page.Run does afterwards
// BC versions: 29 (27 and 28 by CI)

codeunit 74118 "LT P134 PH Typed 1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P134 Log";

    local procedure Seed()
    var
        Row: Record "LT P134 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Log.Take();
    end;

    [PageHandler]
    procedure ListHandler(var P: Page "LT P134 ListA")
    var
        Row: Record "LT P134 Row";
    begin
        P.GetRecord(Row);
        Log.Add('handler rec=' + Format(Row.Id) + '/' + Row.Name);
        Log.Add('handler lookupmode=' + Format(P.LookupMode()));
        Log.Add('handler editable=' + Format(P.Editable()));
    end;

    [PageHandler]
    procedure CardHandler(var P: Page "LT P134 CardC")
    var
        Row: Record "LT P134 Row";
    begin
        P.GetRecord(Row);
        Log.Add('card handler rec=' + Format(Row.Id) + '/' + Row.Name);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P134_PageRun_List_NoRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Page.Run(Page::"LT P134 ListA");
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'handler rec=0/;handler lookupmode=No;handler editable=Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P134_PageRun_List_WithRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P134 Row";
    begin
        Seed();
        Row.Get(2);
        Page.Run(Page::"LT P134 ListA", Row);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'handler rec=2/two;handler lookupmode=No;handler editable=Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure P134_PageRun_Card_WithRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P134 Row";
    begin
        Seed();
        Row.Get(2);
        Page.Run(Page::"LT P134 CardC", Row);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'card handler rec=2/two;');
        Observer.Verify();
    end;
}
