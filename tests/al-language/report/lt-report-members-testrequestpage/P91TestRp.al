// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P91Fix.al; self-contained report 71603 and codeunit 71614
// Facts: TestRequestPage navigation and search members on a request page (First, Last, Next, Previous, New, GoToKey, GoToRecord, Expand, IsExpanded, FindFirstField, FindNextField,
// FindPreviousField, GetValidationError, ValidationErrorCount) and SaveAsPdf / SaveAsWord / SaveAsExcel / SaveAsXml on a layout-less report; each handler runs for sure
// (the report is started with Report.Run in the test that declares it)

report 71603 "LT P91 RpPage"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT P91 Row")
        {
            RequestFilterFields = Id;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(General)
                {
                    field(TextCtl; TextVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Text Control';
                    }
                    field(IntCtl; IntVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Integer Control';
                    }
                }
                group(Advanced)
                {
                    field(AdvText; AdvVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Advanced Control';
                    }
                }
            }
        }
    }

    var
        TextVal: Text[20];
        IntVal: Integer;
        AdvVal: Text[20];
}

codeunit 71614 "LT P91 TestRp Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P91 Helper";
        Observer: Codeunit "Probe Observer";

    local procedure Failed(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryNav(var RP: TestRequestPage "LT P91 RpPage"; Op: Integer; var R: Text)
    var
        Row: Record "LT P91 Row";
    begin
        case Op of
            1:
                R := Format(RP.First());
            2:
                R := Format(RP.Last());
            3:
                R := Format(RP.Next());
            4:
                R := Format(RP.Previous());
            5:
                RP.New();
            6:
                R := Format(RP.GoToKey(1));
            7:
                R := Format(RP.GoToRecord(Row));
            8:
                RP.Expand(true);
            9:
                R := Format(RP.IsExpanded());
            10:
                RP.Expand(false);
        end;
    end;

    local procedure Nav(var RP: TestRequestPage "LT P91 RpPage"; Op: Integer): Text
    var
        R: Text;
    begin
        if TryNav(RP, Op, R) then
            exit('ok ' + R);
        exit(Failed());
    end;

    [RequestPageHandler]
    procedure NavHandler(var RP: TestRequestPage "LT P91 RpPage")
    var
        i: Integer;
    begin
        for i := 1 to 10 do
            Observer.Observe('nav' + Format(i), Nav(RP, i));
        RP.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TryFind(var RP: TestRequestPage "LT P91 RpPage"; Op: Integer; var R: Text)
    begin
        case Op of
            1:
                R := Format(RP.FindFirstField(RP.TextCtl, ''));
            2:
                R := Format(RP.FindNextField(RP.TextCtl, ''));
            3:
                R := Format(RP.FindPreviousField(RP.TextCtl, ''));
            4:
                R := Format(RP.FindFirstField(RP.IntCtl, 0));
            5:
                R := Format(RP.FindNextField(RP.IntCtl, 0));
            6:
                R := Format(RP.FindPreviousField(RP.IntCtl, 0));
            7:
                R := Format(RP.FindFirstField(RP.TextCtl, 'nomatch'));
        end;
    end;

    local procedure Find(var RP: TestRequestPage "LT P91 RpPage"; Op: Integer): Text
    var
        R: Text;
    begin
        if TryFind(RP, Op, R) then
            exit('ok ' + R);
        exit(Failed());
    end;

    [RequestPageHandler]
    procedure FindHandler(var RP: TestRequestPage "LT P91 RpPage")
    var
        i: Integer;
    begin
        for i := 1 to 7 do
            Observer.Observe('find' + Format(i), Find(RP, i));
        RP.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TryValidation(var RP: TestRequestPage "LT P91 RpPage"; Op: Integer; var R: Text)
    begin
        case Op of
            1:
                R := Format(RP.ValidationErrorCount());
            2:
                R := RP.GetValidationError(1);
            3:
                R := RP.GetValidationError(0);
            4:
                R := RP.GetValidationError(-1);
            5:
                R := RP.GetValidationError(100);
        end;
    end;

    local procedure Validation(var RP: TestRequestPage "LT P91 RpPage"; Op: Integer): Text
    var
        R: Text;
    begin
        if TryValidation(RP, Op, R) then
            exit('ok ' + R);
        exit(Failed());
    end;

    [RequestPageHandler]
    procedure ValidationHandler(var RP: TestRequestPage "LT P91 RpPage")
    var
        i: Integer;
    begin
        for i := 1 to 5 do
            Observer.Observe('before' + Format(i), Validation(RP, i));
        asserterror RP.IntCtl.SetValue('abc');
        Observer.ObserveError('set int abc');
        for i := 1 to 5 do
            Observer.Observe('after' + Format(i), Validation(RP, i));
        RP.Cancel().Invoke();
    end;
}
