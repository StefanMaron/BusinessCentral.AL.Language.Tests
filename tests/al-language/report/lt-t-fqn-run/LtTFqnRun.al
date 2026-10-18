// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 69383, log codeunit 69384, report 69385, page 69386, test codeunit 69387
// Facts: the fully qualified name overloads of Report.Run, Report.RunModal, Report.Execute, Page.Run, Page.RunModal, RecordRef.Open and RecordRef.FullyQualifiedName (runtime 17.0, BC 28 and later).
// BC versions: 28.0 and later

#if BC28PLUS
namespace LT.T.Fqn;

using Microsoft.Sales.Customer;
using Microsoft.Finance.GeneralLedger.Ledger;

table 69383 "LT T Fqn Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69384 "LT T Fqn Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

report 69385 "LT T Fqn Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT T Fqn Row")
        {
            trigger OnAfterGetRecord()
            begin
                FqnLog.Add('Row' + Format(Row.Id));
            end;
        }
    }

    var
        FqnLog: Codeunit "LT T Fqn Log";

    trigger OnPreReport()
    begin
        FqnLog.Add('Pre');
    end;

    trigger OnPostReport()
    begin
        FqnLog.Add('Post');
    end;
}

page 69386 "LT T Fqn Page"
{
    PageType = Card;
    SourceTable = "LT T Fqn Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
    }
}

codeunit 69387 "LT T Fqn Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        FqnLog: Codeunit "LT T Fqn Log";
        Seen: Text;
        ActionSeen: Text;

    local procedure Seed()
    var
        Row: Record "LT T Fqn Row";
        Index: Integer;
    begin
        Row.DeleteAll();
        for Index := 1 to 5 do begin
            Row.Init();
            Row.Id := Index;
            Row.Txt := 'T' + Format(Index);
            Row.Insert();
        end;
        FqnLog.Take();
    end;

    [Test]
    procedure Names()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LT T Fqn Row");
        Observer.Observe('table fqn', RecRef.FullyQualifiedName());
        Observer.Observe('table fqn property', RecRef.FullyQualifiedName);
        RecRef.Close();
        Observer.Finish();
    end;


    [TryFunction]
    local procedure TryOpen(Name: Text; var Number: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Name);
        Number := RecRef.Number;
        RecRef.Close();
    end;

    [Test]
    procedure Candidates()
    var
        Names: List of [Text];
        Name: Text;
        Number: Integer;
        Ok: Boolean;
        Index: Integer;
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::Customer);
        Observer.Observe('customer fqn', RecRef.FullyQualifiedName());
        RecRef.Close();
        RecRef.Open(Database::"G/L Entry");
        Observer.Observe('gl entry fqn', RecRef.FullyQualifiedName());
        RecRef.Close();
        Names.Add('LT.T.Fqn.LT T Fqn Row');
        Names.Add('LT.T.Fqn.lt t fqn row');
        Names.Add('LT.T.Fqn.No Such Table');
        Names.Add('lt.t.fqn.LT T Fqn Row');
        Names.Add('LT.T.LT T Fqn Row');
        Names.Add('LT T Fqn Row');
        Names.Add('Microsoft.Sales.Customer.Customer');
        Names.Add('Microsoft.Sales.Customer.customer');
        Names.Add('Sales.Customer.Customer');
        Names.Add('Customer');
        Names.Add('');
        Names.Add('LT.T.Fqn.');
        Names.Add('.LT T Fqn Row');
        Index := 0;
        foreach Name in Names do begin
            Index += 1;
            Number := 0;
            Ok := TryOpen(Name, Number);
            Observer.Observe('cand ' + Format(Index) + ' ' + Name, Format(Ok) + ' ' + Format(Number) + ' ' + GetLastErrorText());
            ClearLastError();
        end;
        Observer.Finish();
    end;

    [Test]
    procedure OpenByName()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open('LT.T.Fqn.LT T Fqn Row');
        Observer.Observe('plain name number', Format(RecRef.Number));
        RecRef.Close();
        asserterror RecRef.Open('LT T Fqn Row');
        Observer.ObserveError('open plain name');
        asserterror RecRef.Open(Format(Database::"LT T Fqn Row"));
        Observer.ObserveError('open number text');
        Observer.Finish();
    end;

    [Test]
    procedure OpenByFqn()
    var
        RecRef: RecordRef;
        Other: RecordRef;
        Name: Text;
    begin
        RecRef.Open(Database::"LT T Fqn Row");
        Name := RecRef.FullyQualifiedName();
        RecRef.Close();
        Other.Open(Name, true, CompanyName());
        Observer.Observe('open fqn number', Format(Other.Number));
        Observer.Observe('open fqn temporary', Format(Other.IsTemporary()));
        Other.Close();
        Other.Open(Name);
        Observer.Observe('open fqn plain number', Format(Other.Number));
        Observer.Observe('open fqn plain temporary', Format(Other.IsTemporary()));
        Other.Close();
        asserterror Other.Open('No Such Table');
        Observer.ObserveError('open unknown');
        Observer.Finish();
    end;

    [Test]
    procedure ReportByName()
    var
        Row: Record "LT T Fqn Row";
        RecRef: RecordRef;
        Name: Text;
    begin
        Seed();
        RecRef.Open(Database::"LT T Fqn Row");
        Name := RecRef.FullyQualifiedName();
        asserterror Report.Run('LT T Fqn Report', false, false);
        Observer.ObserveError('run plain name');
        asserterror Report.Execute('LT T Fqn Report', '');
        Observer.ObserveError('execute plain name');
        Report.Run('LT.T.Fqn.LT T Fqn Report', false, false);
        Observer.Observe('plain run log', FqnLog.Take());
        Row.SetFilter(Id, '>=%1', 4);
        Report.Run('LT.T.Fqn.LT T Fqn Report', false, false, Row);
        Observer.Observe('plain run row log', FqnLog.Take());
        Report.RunModal('LT.T.Fqn.LT T Fqn Report', false, false, Row);
        Observer.Observe('plain runmodal row log', FqnLog.Take());
        RecRef.SetView(Row.GetView());
        Report.Execute('LT.T.Fqn.LT T Fqn Report', '', RecRef);
        Observer.Observe('plain execute recref log', FqnLog.Take());
        Report.Execute('LT.T.Fqn.LT T Fqn Report', '');
        Observer.Observe('plain execute log', FqnLog.Take());
        asserterror Report.Run('No Such Report', false, false);
        Observer.ObserveError('run unknown');
        asserterror Report.Execute('No Such Report', '');
        Observer.ObserveError('execute unknown');
        asserterror Report.RunModal('No Such Report', false, false, Row);
        Observer.ObserveError('runmodal unknown');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure PageRunByName()
    var
        Row: Record "LT T Fqn Row";
    begin
        Seed();
        Row.Get(3);
        Seen := '';
        Page.Run('LT.T.Fqn.LT T Fqn Page', Row, Row.Txt);
        Observer.Observe('page run seen', Seen);
        Seen := '';
        asserterror Page.Run('LT T Fqn Page', Row);
        Observer.ObserveError('page run plain name');
        Observer.Finish();
    end;

    [PageHandler]
    procedure CardHandler(var P: TestPage "LT T Fqn Page")
    begin
        Seen += P.Id.Value + '/' + P.Txt.Value + ';';
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure PageRunModalOk()
    var
        Row: Record "LT T Fqn Row";
        RecRef: RecordRef;
        FRef: FieldRef;
        Result: Action;
    begin
        Seed();
        Row.Get(2);
        Seen := '';
        Result := Page.RunModal('LT.T.Fqn.LT T Fqn Page', Row, Row.Txt);
        Observer.Observe('modal field', Format(Result) + ' ' + Seen);
        Seen := '';
        Result := Page.RunModal('LT.T.Fqn.LT T Fqn Page', Row, 2);
        Observer.Observe('modal fieldno', Format(Result) + ' ' + Seen);
        RecRef.GetTable(Row);
        FRef := RecRef.Field(2);
        Seen := '';
        Result := Page.RunModal('LT.T.Fqn.LT T Fqn Page', Row, FRef);
        Observer.Observe('modal fieldref', Format(Result) + ' ' + Seen);
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure OkHandler(var P: TestPage "LT T Fqn Page")
    begin
        Seen += P.Id.Value + '/' + P.Txt.Value + ';';
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure PageRunModalCancel()
    var
        Row: Record "LT T Fqn Row";
        Result: Action;
    begin
        Seed();
        Row.Get(2);
        Result := Page.RunModal('LT.T.Fqn.LT T Fqn Page', Row, Row.Txt);
        Observer.Observe('modal cancel', Format(Result));
        asserterror Page.Run('No Such Page', Row);
        Observer.ObserveError('page run unknown');
        asserterror Page.RunModal('No Such Page', Row, Row.Txt);
        Observer.ObserveError('page runmodal unknown');
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure CancelHandler(var P: TestPage "LT T Fqn Page")
    begin
        P.Cancel().Invoke();
    end;
}
#endif
