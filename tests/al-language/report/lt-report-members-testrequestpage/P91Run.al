// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P91Fix.al; SingleInstance log 71599 is used only by test codeunit 71612
// Facts: Report.Run / RunModal / Execute static and on a variable: ids 0 and unknown, Execute with empty, garbage and XML parameters, Run twice, UseRequestPage

codeunit 71599 "LT P91 Run Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 71600 "LT P91 RunRep"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P91 Row")
        {
            RequestFilterFields = Id;

            trigger OnPreDataItem()
            begin
                L.Add('row pre filter=[' + Row.GetFilter(Id) + ']');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;
        }
    }

    trigger OnPreReport()
    begin
        L.Add('pre');
    end;

    trigger OnPostReport()
    begin
        L.Add('post');
    end;

    var
        L: Codeunit "LT P91 Run Log";
}

codeunit 71612 "LT P91 Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P91 Run Log";
        Helper: Codeunit "LT P91 Helper";
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure Run_Static_Instance_Modal()
    var
        Rpt: Report "LT P91 RunRep";
    begin
        Helper.Seed();
        L.Take();
        Report.Run(Report::"LT P91 RunRep");
        Observer.Observe('static run', L.Take());
        Report.RunModal(Report::"LT P91 RunRep");
        Observer.Observe('static runmodal', L.Take());
        Rpt.Run();
        Observer.Observe('instance run', L.Take());
        Rpt.RunModal();
        Observer.Observe('instance runmodal', L.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Run_WithRecordFilter()
    var
        Row: Record "LT P91 Row";
    begin
        Helper.Seed();
        Row.SetFilter(Id, '2..3');
        L.Take();
        Report.Run(Report::"LT P91 RunRep", false, false, Row);
        Observer.Observe('run filtered', L.Take());
        Report.RunModal(Report::"LT P91 RunRep", false, false, Row);
        Observer.Observe('runmodal filtered', L.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Run_InvalidIds()
    begin
        asserterror Report.Run(0);
        Observer.ObserveError('run 0');
        asserterror Report.Run(71999);
        Observer.ObserveError('run unknown');
        asserterror Report.Run(-1);
        Observer.ObserveError('run negative');
        asserterror Report.RunModal(0);
        Observer.ObserveError('runmodal 0');
        asserterror Report.RunModal(71999);
        Observer.ObserveError('runmodal unknown');
        Observer.Finish();
    end;

    [Test]
    procedure Execute_Parameters()
    begin
        Helper.Seed();
        L.Take();
        Report.Execute(Report::"LT P91 RunRep", '');
        Observer.Observe('empty', L.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Execute_InvalidIds()
    begin
        asserterror Report.Execute(0, '');
        Observer.ObserveError('execute 0');
        asserterror Report.Execute(71999, '');
        Observer.ObserveError('execute unknown');
        Observer.Finish();
    end;

    [Test]
    procedure Execute_WithRecord()
    var
        Row: Record "LT P91 Row";
    begin
        Helper.Seed();
        Row.SetRange(Grp, 1);
        L.Take();
        Report.Execute(Report::"LT P91 RunRep", '', Row);
        Observer.Observe('with row', L.Take());
        Observer.Finish();
    end;

    [Test]
    procedure RunRequestPage_NoRequestPage()
    var
        Rpt: Report "LT P91 RunRep";
        Params: Text;
    begin
        Helper.Seed();
        asserterror Params := Rpt.RunRequestPage();
        Observer.ObserveError('af183');
        Observer.Observe('params blank', Format(Params = ''));
        Observer.Finish();
    end;

    [Test]
    procedure UseRequestPage_Defaults()
    var
        Rpt: Report "LT P91 RunRep";
    begin
        Observer.Observe('default', Format(Rpt.UseRequestPage()));
        Rpt.UseRequestPage(true);
        Observer.Observe('set true', Format(Rpt.UseRequestPage()));
        Rpt.UseRequestPage(false);
        Observer.Observe('set false', Format(Rpt.UseRequestPage()));
        Observer.Finish();
    end;
}
