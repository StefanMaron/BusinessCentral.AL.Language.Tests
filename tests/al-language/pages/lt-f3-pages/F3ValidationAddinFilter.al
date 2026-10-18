// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-getvalidationerror-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT F3 Row / Log Mgt / List (F3Fixtures.al); own objects 67116 - 67121
// Probe: (1) TestPage.GetValidationError() without an index after no error, one error and two errors; (2) TestFilter.SetFilter(Field, '') on a TestPage list: does it clear the filter;
//        (3) calls to a control add-in procedure from AL (no-op or error), whether an event fires,, from a page that ran and from a Page variable that never ran.

table 67116 "LT F3 Valid"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; A; Integer)
        {
            trigger OnValidate()
            begin
                if A < 0 then
                    Error('A must not be negative');
            end;
        }
        field(3; B; Integer)
        {
            trigger OnValidate()
            begin
                if B < 0 then
                    Error('B must not be negative');
            end;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 67117 "LT F3 Valid Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT F3 Valid";

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(ACtl; Rec.A) { ApplicationArea = All; }
            field(BCtl; Rec.B) { ApplicationArea = All; }
        }
    }
}

controladdin "LT F3 Addin"
{
    RequestedHeight = 100;
    RequestedWidth = 100;

    event Ready();
    event Clicked(Value: Text);

    procedure SetLocale(Locale: Text);
    procedure Load(Payload: JsonObject);
}

page 67119 "LT F3 Addin Page"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT F3 Row";

    layout
    {
        area(Content)
        {
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            usercontrol(Host; "LT F3 Addin")
            {
                ApplicationArea = All;

                trigger Ready()
                var
                    Log: Codeunit "LT F3 Log Mgt";
                begin
                    Log.Add('Addin.Ready');
                end;

                trigger Clicked(Value: Text)
                var
                    Log: Codeunit "LT F3 Log Mgt";
                begin
                    Log.Add('Addin.Clicked(' + Value + ')');
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT F3 Log Mgt";
    begin
        CurrPage.Host.SetLocale('de-DE');
        Log.Add('OnOpenPage after SetLocale');
    end;

    procedure CallSetLocale(Locale: Text)
    begin
        CurrPage.Host.SetLocale(Locale);
    end;

    procedure CallLoad()
    var
        Payload: JsonObject;
    begin
        Payload.Add('k', 1);
        CurrPage.Host.Load(Payload);
    end;
}

codeunit 67120 "LT F3 Validation Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryGet(var P: TestPage "LT F3 Valid Card"; Index: Integer; var Result: Text)
    begin
        if Index = 0 then
            Result := P.GetValidationError()
        else
            Result := P.GetValidationError(Index);
    end;

    local procedure ObserveGet(var Observer: Codeunit "Probe Observer"; Name: Text; var P: TestPage "LT F3 Valid Card"; Index: Integer)
    var
        Result: Text;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryGet(P, Index, Result);
        Observer.Observe(Name + '_ok', Format(Ok));
        Observer.Observe(Name + '_result', Result);
        if not Ok then begin
            Observer.Observe(Name + '_error', GetLastErrorText());
            Observer.Observe(Name + '_code', GetLastErrorCode());
        end;
    end;

    local procedure Prepare()
    var
        Valid: Record "LT F3 Valid";
    begin
        Valid.DeleteAll();
        Valid.Init();
        Valid."No." := 'V1';
        Valid.Insert();
    end;

    [Test]
    procedure GetValidationError_NoError()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT F3 Valid Card";
    begin
        Prepare();
        P.OpenEdit();
        ObserveGet(Observer, 'noindex', P, 0);
        ObserveGet(Observer, 'index1', P, 1);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure GetValidationError_OneError()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT F3 Valid Card";
    begin
        Prepare();
        P.OpenEdit();
        asserterror P.ACtl.SetValue(-1);
        Observer.ObserveError('set_a');
        ObserveGet(Observer, 'noindex', P, 0);
        ObserveGet(Observer, 'index1', P, 1);
        ObserveGet(Observer, 'index2', P, 2);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure GetValidationError_TwoErrors()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT F3 Valid Card";
    begin
        Prepare();
        P.OpenEdit();
        asserterror P.ACtl.SetValue(-1);
        Observer.ObserveError('set_a');
        asserterror P.BCtl.SetValue(-2);
        Observer.ObserveError('set_b');
        ObserveGet(Observer, 'noindex', P, 0);
        ObserveGet(Observer, 'index1', P, 1);
        ObserveGet(Observer, 'index2', P, 2);
        ObserveGet(Observer, 'index3', P, 3);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure GetValidationError_ErrorThenCorrected()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT F3 Valid Card";
    begin
        Prepare();
        P.OpenEdit();
        asserterror P.ACtl.SetValue(-1);
        Observer.ObserveError('set_bad');
        P.ACtl.SetValue(5);
        ObserveGet(Observer, 'noindex', P, 0);
        P.Close();
        Observer.Finish();
    end;
}

codeunit 67121 "LT F3 TestFilter Empty"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TestPage_SetFilterEmpty_ClearsFilter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        P: TestPage "LT F3 List";
        Count: Integer;
    begin
        Log.Seed(5);
        P.OpenView();
        P.Filter.SetFilter(Qty, '>=3');
        Observer.Observe('filter_set', P.Filter.GetFilter(Qty));
        Count := 0;
        if P.First() then
            repeat
                Count += 1;
            until not P.Next();
        Observer.Observe('rows_filtered', Format(Count));
        P.Filter.SetFilter(Qty, '');
        Observer.Observe('filter_empty', P.Filter.GetFilter(Qty));
        Count := 0;
        if P.First() then
            repeat
                Count += 1;
            until not P.Next();
        Observer.Observe('rows_after_empty', Format(Count));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TestPage_SetFilterEmptyOnOtherField_KeepsFirst()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        P: TestPage "LT F3 List";
    begin
        Log.Seed(5);
        P.OpenView();
        P.Filter.SetFilter(Qty, '>=3');
        P.Filter.SetFilter(Name, '');
        Observer.Observe('qty_filter', P.Filter.GetFilter(Qty));
        Observer.Observe('name_filter', P.Filter.GetFilter(Name));
        P.Close();
        Observer.Finish();
    end;
}

codeunit 67122 "LT F3 Addin Calls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [PageHandler]
    procedure AddinPageHandler(var P: TestPage "LT F3 Addin Page")
    begin
        Observer.Observe('h_name', P.NameCtl.Value());
    end;

    [TryFunction]
    local procedure TryCall(var Pg: Page "LT F3 Addin Page"; Which: Integer)
    begin
        case Which of
            1:
                Pg.CallSetLocale('de-DE');
            2:
                Pg.CallLoad();
        end;
    end;

    local procedure ObserveCall(Name: Text; var Pg: Page "LT F3 Addin Page"; Which: Integer)
    var
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryCall(Pg, Which);
        Observer.Observe(Name + '_ok', Format(Ok));
        if not Ok then begin
            Observer.Observe(Name + '_error', GetLastErrorText());
            Observer.Observe(Name + '_code', GetLastErrorCode());
        end;
    end;

    [Test]
    [HandlerFunctions('AddinPageHandler')]
    procedure Addin_PageOpened_OnOpenPageCallsProcedure()
    var
        Log: Codeunit "LT F3 Log Mgt";
        Row: Record "LT F3 Row";
        Ok: Boolean;
    begin
        Log.Seed(1);
        Log.Clear();
        Row.FindFirst();
        ClearLastError();
        Ok := TryRunPage(Row);
        Observer.Observe('ok', Format(Ok));
        if not Ok then begin
            Observer.Observe('error', GetLastErrorText());
            Observer.Observe('code', GetLastErrorCode());
        end;
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryRunPage(var Row: Record "LT F3 Row")
    begin
        Page.Run(Page::"LT F3 Addin Page", Row);
    end;

    [Test]
    procedure Addin_PageVariableNeverOpened_Calls()
    var
        Pg: Page "LT F3 Addin Page";
        Log: Codeunit "LT F3 Log Mgt";
    begin
        Log.Clear();
        ObserveCall('setlocale', Pg, 1);
        ObserveCall('load', Pg, 2);
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;
}
