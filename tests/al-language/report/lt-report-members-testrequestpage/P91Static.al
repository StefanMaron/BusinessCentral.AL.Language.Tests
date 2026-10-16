// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P91Fix.al; self-contained reports 71597, 71598 and codeunit 71611
// Facts (stream SaveAs overloads are OnPrem only and not used): static Report layout members (DefaultLayout, RdlcLayout, WordLayout, ExcelLayout, WordXmlPart) on reports without a layout file, a ProcessingOnly report, 0 and an unknown id;
// stream overloads SaveAsPdf / SaveAsWord / SaveAsExcel / SaveAsHtml / SaveAsXml into an OutStream

report 71597 "LT P91 NoLayout"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P91 Row")
        {
            column(IdCol; Id) { }
            column(NameCol; Name) { }
        }
    }
}

report 71598 "LT P91 ProcOnly"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P91 Row")
        {
            column(IdCol; Id) { }
        }
    }
}

codeunit 71611 "LT P91 Static Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P91 Helper";
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryDefaultLayout(Id: Integer; var R: Text)
    begin
        R := Format(Report.DefaultLayout(Id));
    end;

    local procedure DefaultLayoutOf(Id: Integer): Text
    var
        R: Text;
    begin
        if TryDefaultLayout(Id, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryLayoutStream(Kind: Integer; Id: Integer; var R: Text)
    var
        InS: InStream;
    begin
        case Kind of
            1:
                Report.RdlcLayout(Id, InS);
            2:
                Report.WordLayout(Id, InS);
            3:
                Report.ExcelLayout(Id, InS);
        end;
        R := 'eos=' + Format(InS.EOS());
    end;

    local procedure LayoutStreamOf(Kind: Integer; Id: Integer): Text
    var
        R: Text;
    begin
        if TryLayoutStream(Kind, Id, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryWordXmlPart(Id: Integer; var R: Text)
    begin
        R := 'len>0=' + Format(StrLen(Report.WordXmlPart(Id)) > 0);
    end;

    local procedure WordXmlPartOf(Id: Integer): Text
    var
        R: Text;
    begin
        if TryWordXmlPart(Id, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure DefaultLayout_Reports()
    begin
        Observer.Observe('nolayout', DefaultLayoutOf(Report::"LT P91 NoLayout"));
        Observer.Observe('proconly', DefaultLayoutOf(Report::"LT P91 ProcOnly"));
        Observer.Observe('zero', DefaultLayoutOf(0));
        Observer.Observe('unknown', DefaultLayoutOf(71999));
        Observer.Observe('negative', DefaultLayoutOf(-1));
        Observer.Finish();
    end;

    [Test]
    procedure DefaultLayout_AsserterrorUnknown()
    var
        Lay: Variant;
    begin
        asserterror Lay := Report.DefaultLayout(71999);
        Observer.ObserveError('unknown');
        Observer.Finish();
    end;

    [Test]
    procedure RdlcLayout_Reports()
    begin
        Observer.Observe('nolayout', LayoutStreamOf(1, Report::"LT P91 NoLayout"));
        Observer.Observe('proconly', LayoutStreamOf(1, Report::"LT P91 ProcOnly"));
        Observer.Observe('zero', LayoutStreamOf(1, 0));
        Observer.Observe('unknown', LayoutStreamOf(1, 71999));
        Observer.Finish();
    end;

    [Test]
    procedure WordLayout_Reports()
    begin
        Observer.Observe('nolayout', LayoutStreamOf(2, Report::"LT P91 NoLayout"));
        Observer.Observe('proconly', LayoutStreamOf(2, Report::"LT P91 ProcOnly"));
        Observer.Observe('zero', LayoutStreamOf(2, 0));
        Observer.Observe('unknown', LayoutStreamOf(2, 71999));
        Observer.Finish();
    end;

    [Test]
    procedure ExcelLayout_Reports()
    begin
        Observer.Observe('nolayout', LayoutStreamOf(3, Report::"LT P91 NoLayout"));
        Observer.Observe('proconly', LayoutStreamOf(3, Report::"LT P91 ProcOnly"));
        Observer.Observe('zero', LayoutStreamOf(3, 0));
        Observer.Observe('unknown', LayoutStreamOf(3, 71999));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_Reports()
    begin
        Observer.Observe('nolayout', WordXmlPartOf(Report::"LT P91 NoLayout"));
        Observer.Observe('proconly', WordXmlPartOf(Report::"LT P91 ProcOnly"));
        Observer.Observe('zero', WordXmlPartOf(0));
        Observer.Observe('unknown', WordXmlPartOf(71999));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_AsserterrorUnknown()
    var
        Txt: Text;
    begin
        asserterror Txt := Report.WordXmlPart(71999);
        Observer.ObserveError('unknown');
        Observer.Finish();
    end;
}
