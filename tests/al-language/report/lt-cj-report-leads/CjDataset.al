// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table, log and helper of CjFix.al; own reports 84647-84649, test codeunit 84650
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced.
// Facts (corpus issue 667): DataItemTableView = where(Date field = const(0D)) compiles and filters (item 149); a procedure Foo() defined on both the report and the
//   data item table: which one an unqualified call in a data item trigger, a report trigger and a column source expression runs (item 150); a table extension field used
//   without a record prefix in a data item trigger (item 153); rows of a temporary record of the caller (SetTableView, the RecordRef overload of SaveAs, and a
//   UseTemporary data item that shares the caller's temporary table) in the Xml dataset and in Execute (item 157).
// BC versions: 27-29

report 84647 "LT CJ Scope Rep"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT CJ Row")
        {
            DataItemTableView = where("My Date" = const(0D));

            column(RowId; Id) { }
            column(FooCol; Foo()) { }
            column(ExtCol; "LT CJ Ext Code") { }

            trigger OnPreDataItem()
            begin
                Log.Add('view=' + Row.GetView(false));
            end;

            trigger OnAfterGetRecord()
            var
                Other: Record "LT CJ Row";
            begin
                Other.SetRange("LT CJ Ext Code", "LT CJ Ext Code");
                Log.Add('row ' + Format(Id) + ' foo=' + Foo() + ' ext=' + "LT CJ Ext Code" + ' same ext=' + Format(Other.Count()));
            end;
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('prereport foo=' + Foo());
    end;

    procedure Foo(): Text
    begin
        exit('report');
    end;

    var
        Log: Codeunit "LT CJ Log";
}

report 84648 "LT CJ Temp Caller Rep"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT CJ Row")
        {
            column(RowId; Id) { }

            trigger OnPreDataItem()
            begin
                Log.Add('istemporary=' + Format(Row.IsTemporary()));
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('row ' + Format(Id));
            end;
        }
    }

    var
        Log: Codeunit "LT CJ Log";
}

report 84649 "LT CJ Temp Shared Rep"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Tmp; "LT CJ Row")
        {
            UseTemporary = true;

            column(TmpId; Id) { }

            trigger OnPreDataItem()
            begin
                Log.Add('count=' + Format(Tmp.Count()));
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('tmp ' + Format(Id));
            end;
        }
    }

    procedure SetRows(var Source: Record "LT CJ Row" temporary)
    begin
        Tmp.Copy(Source, true);
    end;

    var
        Log: Codeunit "LT CJ Log";
}

codeunit 84650 "LT CJ Dataset Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT CJ Helper";
        Log: Codeunit "LT CJ Log";

    local procedure FillTemp(var Temp: Record "LT CJ Row" temporary)
    begin
        Temp.Id := 101;
        Temp.Name := 'T1';
        Temp.Insert();
        Temp.Id := 102;
        Temp.Name := 'T2';
        Temp.Insert();
    end;

    [Test]
    procedure ZeroDateView_Scope_ExtensionField()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Xml: Text;
    begin
        Helper.Seed();
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('saved', Format(Report.SaveAs(Report::"LT CJ Scope Rep", '', ReportFormat::Xml, OutS)));
        Xml := Helper.ReadAll(TempBlob);
        Observer.Observe('RowId', Helper.Values(Xml, 'RowId'));
        Observer.Observe('FooCol', Helper.Values(Xml, 'FooCol'));
        Observer.Observe('ExtCol', Helper.Values(Xml, 'ExtCol'));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure TempRecord_SetTableView_SaveAsXml()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT CJ Row" temporary;
        Rpt: Report "LT CJ Temp Caller Rep";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Helper.Seed();
        FillTemp(Temp);
        Rpt.SetTableView(Temp);
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('saved', Format(Rpt.SaveAs('', ReportFormat::Xml, OutS)));
        Observer.Observe('RowId', Helper.Values(Helper.ReadAll(TempBlob), 'RowId'));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure TempRecord_RecordRefOverload_SaveAsXml()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT CJ Row" temporary;
        RecRef: RecordRef;
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Helper.Seed();
        FillTemp(Temp);
        RecRef.GetTable(Temp);
        Observer.Observe('recref temporary', Format(RecRef.IsTemporary()));
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('saved', Format(Report.SaveAs(Report::"LT CJ Temp Caller Rep", '', ReportFormat::Xml, OutS, RecRef)));
        Observer.Observe('RowId', Helper.Values(Helper.ReadAll(TempBlob), 'RowId'));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure TempRecord_UseTemporaryShared_SaveAsXml()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT CJ Row" temporary;
        Rpt: Report "LT CJ Temp Shared Rep";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Helper.Seed();
        FillTemp(Temp);
        Rpt.SetRows(Temp);
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('saved', Format(Rpt.SaveAs('', ReportFormat::Xml, OutS)));
        Observer.Observe('TmpId', Helper.Values(Helper.ReadAll(TempBlob), 'TmpId'));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryExecuteShared(var Rpt: Report "LT CJ Temp Shared Rep")
    begin
        Rpt.Execute('');
    end;

    [TryFunction]
    local procedure TryExecuteCaller(var Rpt: Report "LT CJ Temp Caller Rep")
    begin
        Rpt.Execute('');
    end;

    [Test]
    procedure TempRecord_Execute()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT CJ Row" temporary;
        Shared: Report "LT CJ Temp Shared Rep";
        Caller: Report "LT CJ Temp Caller Rep";
    begin
        Helper.Seed();
        FillTemp(Temp);
        Shared.SetRows(Temp);
        ClearLastError();
        Observer.Observe('shared execute', Format(TryExecuteShared(Shared)));
        Observer.ObserveError('shared execute err');
        Observer.Observe('shared log', Log.Take());
        Caller.SetTableView(Temp);
        Observer.Observe('caller execute', Format(TryExecuteCaller(Caller)));
        Observer.ObserveError('caller execute err');
        Observer.Observe('caller log', Log.Take());
        Observer.Finish();
    end;
}
