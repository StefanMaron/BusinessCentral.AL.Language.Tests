// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P91Fix.al; self-contained reports 71601, 71602 and codeunit 71613
// Facts: members whose exact signature is unsure (the lead drops what does not compile): Report.GetSubstituteReportId, Report.ValidateAndPrepareLayout,
// CurrReport.NewPagePerRecord, CurrReport.PaperSource, and the RequestPage members of a report variable (Activate, Close, Editable, LookupMode, ObjectId, SaveRecord, SetSelectionFilter) outside a run

report 71601 "LT P91 Props"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P91 Row")
        {
        }
    }

    procedure Probe(): Text
    begin
        exit(Format(CurrReport.NewPagePerRecord));
    end;
}

report 71602 "LT P91 ReqMembers"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT P91 Row")
        {
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(TextCtl; TextVal)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        TextVal: Text[20];
}

codeunit 71613 "LT P91 Unsure Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TrySubstitute(Id: Integer; var R: Text)
    begin
        R := Format(Report.GetSubstituteReportId(Id));
    end;

    local procedure SubstituteOf(Id: Integer): Text
    var
        R: Text;
    begin
        if TrySubstitute(Id, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure GetSubstituteReportId_Values()
    begin
        Observer.Observe('own', Format(SubstituteOf(Report::"LT P91 Props") = Format(Report::"LT P91 Props")));
        Observer.Observe('zero', SubstituteOf(0));
        Observer.Observe('unknown', SubstituteOf(71999));
        Observer.Finish();
    end;

    [Test]
    procedure CurrReport_NewPagePerRecord_PaperSource()
    var
        Rpt: Report "LT P91 Props";
    begin
        Observer.Observe('probe', Rpt.Probe());
        Observer.Finish();
    end;
}
