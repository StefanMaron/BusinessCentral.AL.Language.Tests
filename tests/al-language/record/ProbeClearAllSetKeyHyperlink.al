// Probe: ClearAll per object kind, SetCurrentKey on fields that are not stored, Hyperlink in a test run,
// CurrReport.Language before any set / zero / effect on Format. ClearAll in a table and a page extension: misc/lt-bo2-odd-leads/BoClearAllExt.al (82360-82362).
table 69527 "Probe Rb Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
        field(3; Amount; Decimal) { }
        field(4; Flow; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Probe Rb Row");
        }
        field(5; FlowFilt; Integer) { FieldClass = FlowFilter; }
        field(6; Pic; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    var
        TableGlobal: Integer;

    procedure SetTableGlobal(Value: Integer)
    begin
        TableGlobal := Value;
    end;

    procedure ClearAllInTable(): Text
    begin
        ClearAll();
        exit('Id=' + Format(Id) + ',Name=' + Name + ',global=' + Format(TableGlobal));
    end;
}

codeunit 69528 "Probe ClearAll Plain"
{
    var
        IntVar: Integer;
        TextVar: Text;
        RecVar: Record "Probe Rb Row";
        ArrVar: array[2] of Integer;

    procedure Fill()
    begin
        IntVar := 7;
        TextVar := 'set';
        RecVar.Id := 5;
        RecVar.SetRange(Id, 5);
        ArrVar[1] := 3;
    end;

    procedure ClearAllGlobals(): Text
    var
        LocalVar: Integer;
    begin
        LocalVar := 9;
        ClearAll();
        exit('local=' + Format(LocalVar) + ',' + Describe());
    end;

    procedure Describe(): Text
    begin
        exit('int=' + Format(IntVar) + ',text=' + TextVar + ',recId=' + Format(RecVar.Id) + ',recFilter=[' + RecVar.GetFilters() + '],arr1=' + Format(ArrVar[1]));
    end;
}

codeunit 69529 "PB ClearAll Table No"
{
    TableNo = "Probe Rb Row";

    var
        Marker: Integer;

    trigger OnRun()
    begin
        Marker := 4;
        ClearAll();
        Log := 'recId=' + Format(Rec.Id) + ',name=' + Rec.Name + ',marker=' + Format(Marker);
    end;

    var
        Log: Text;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

codeunit 69530 "PB ClearAll Single"
{
    SingleInstance = true;

    var
        Counter: Integer;

    procedure Bump()
    begin
        Counter += 1;
    end;

    procedure ClearAllAndRead(): Integer
    begin
        ClearAll();
        exit(Counter);
    end;

    procedure Read(): Integer
    begin
        exit(Counter);
    end;
}

report 69531 "Probe Language Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    trigger OnPreReport()
    var
        Log: Codeunit "Probe Lang Log";
    begin
        Log.Add('languageBeforeSet=' + Format(CurrReport.Language));
        CurrReport.Language := 1031;
        Log.Add('language1031=' + Format(CurrReport.Language));
        Log.Add('dateFormatAfter1031=' + Format(DMY2Date(5, 3, 2030)));
        Log.Add('decimalFormatAfter1031=' + Format(1234.5));
        CurrReport.Language := 1033;
        Log.Add('dateFormatAfter1033=' + Format(DMY2Date(5, 3, 2030)));
        Log.Add('decimalFormatAfter1033=' + Format(1234.5));
        if not TrySetZero() then
            Log.Add('languageZero_error=' + GetLastErrorText() + '|' + GetLastErrorCode());
        Log.Add('languageAfterZeroAttempt=' + Format(CurrReport.Language));
        CurrReport.Language := 1031;
        Log.Add('formatRegionBeforeSet=[' + CurrReport.FormatRegion + ']');
    end;

    [TryFunction]
    local procedure TrySetZero()
    begin
        CurrReport.Language := 0;
    end;
}

codeunit 69532 "Probe ClearAll Key Hyperlink"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ClearAll_PlainCodeunit_ResetsGlobalsKeepsLocals()
    var
        Cu: Codeunit "Probe ClearAll Plain";
        Observer: Codeunit "Probe Observer";
    begin
        Cu.Fill();
        Observer.Observe('beforeClearAll', Cu.Describe());
        Observer.Observe('insideClearAll', Cu.ClearAllGlobals());
        Observer.Observe('afterClearAll', Cu.Describe());
        Observer.Expect('beforeClearAll', 'int=7,text=set,recId=5,recFilter=[Id: 5],arr1=3');
        Observer.Expect('insideClearAll', 'local=9,int=0,text=,recId=0,recFilter=[],arr1=0');
        Observer.Expect('afterClearAll', 'int=0,text=,recId=0,recFilter=[],arr1=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_CodeunitWithTableNo_KeepsRec()
    var
        Row: Record "Probe Rb Row";
        Cu: Codeunit "PB ClearAll Table No";
        Observer: Codeunit "Probe Observer";
    begin
        Row.Id := 11;
        Row.Name := 'rowname';
        Cu.Run(Row);
        Observer.Observe('log', Cu.GetLog());
        Observer.Expect('log', 'recId=11,name=rowname,marker=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_SingleInstanceCodeunit_ResetsGlobalsAcrossCalls()
    var
        Cu: Codeunit "PB ClearAll Single";
        Cu2: Codeunit "PB ClearAll Single";
        Observer: Codeunit "Probe Observer";
    begin
        Cu.Bump();
        Cu.Bump();
        Observer.Observe('beforeClearAll', Format(Cu2.Read()));
        Observer.Observe('clearAllReturns', Format(Cu.ClearAllAndRead()));
        Observer.Observe('afterClearAllViaOtherVariable', Format(Cu2.Read()));
        Observer.Expect('beforeClearAll', '2');
        Observer.Expect('clearAllReturns', '0');
        Observer.Expect('afterClearAllViaOtherVariable', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_InTableProcedure_ClearsRecAndTableGlobals()
    var
        Row: Record "Probe Rb Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.Id := 3;
        Row.Name := 'abc';
        Row.SetTableGlobal(8);
        Row.SetRange(Id, 3);
        Observer.Observe('result', Row.ClearAllInTable());
        Observer.Observe('callerIdAfter', Format(Row.Id));
        Observer.Observe('callerNameAfter', Row.Name);
        Observer.Observe('callerFilterAfter', '[' + Row.GetFilters() + ']');
        Observer.Expect('result', 'Id=3,Name=abc,global=0');
        Observer.Expect('callerIdAfter', '3');
        Observer.Expect('callerNameAfter', 'abc');
        Observer.Expect('callerFilterAfter', '[Id: 3]');
        Observer.Verify();
    end;

    local procedure SeedRb()
    var
        Row: Record "Probe Rb Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'b';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'a';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'a';
        Row.Insert();
    end;

    [Test]
    procedure SetCurrentKey_OnNonKeyFields_OrderAndCurrentKey()
    var
        Row: Record "Probe Rb Row";
        Order: Text;
        Observer: Codeunit "Probe Observer";
    begin
        SeedRb();
        Row.SetCurrentKey(Name);
        Observer.Observe('currentKeyName', Row.CurrentKey());
        Row.FindSet();
        repeat
            Order += Format(Row.Id) + ',';
        until Row.Next() = 0;
        Observer.Observe('orderByNameThenPk', Order);
        Row.Ascending(false);
        Order := '';
        Row.FindSet();
        repeat
            Order += Format(Row.Id) + ',';
        until Row.Next() = 0;
        Observer.Observe('orderDescending', Order);
        Row.Ascending(true);
        Row.SetCurrentKey(Name, Amount);
        Observer.Observe('currentKeyTwoFields', Row.CurrentKey());
        Observer.Expect('currentKeyName', 'Name');
        Observer.Expect('orderByNameThenPk', '2,3,1,');
        Observer.Expect('orderDescending', '1,3,2,');
        Observer.Expect('currentKeyTwoFields', 'Name,Amount');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_OnFlowFieldFlowFilterBlob_Outcome()
    var
        Row: Record "Probe Rb Row";
        Observer: Codeunit "Probe Observer";
    begin
        SeedRb();
        Observer.Observe('flowField', Format(TryKeyFlow(Row)));
        Observer.ObserveError('flowField');
        Observer.Observe('flowFilter', Format(TryKeyFlowFilter(Row)));
        Observer.ObserveError('flowFilter');
        Observer.Observe('blob', Format(TryKeyBlob(Row)));
        Observer.ObserveError('blob');
        Observer.Expect('flowField', 'Yes');
        Observer.Expect('flowField|text', '');
        Observer.Expect('flowField|code', '');
        Observer.Expect('flowFilter', 'No');
        Observer.Expect('flowFilter|text', 'Sorting cannot be done based on the FlowFilt field(s) in the Probe Rb Row table.');
        Observer.Expect('flowFilter|code', 'DB:Ok');
        Observer.Expect('blob', 'No');
        Observer.Expect('blob|text', 'Sorting cannot be done based on the Pic field(s) in the Probe Rb Row table.');
        Observer.Expect('blob|code', 'DB:Ok');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryKeyFlow(var Row: Record "Probe Rb Row")
    begin
        Row.SetCurrentKey(Flow);
        Row.FindFirst();
    end;

    [TryFunction]
    local procedure TryKeyFlowFilter(var Row: Record "Probe Rb Row")
    begin
        Row.SetCurrentKey(FlowFilt);
        Row.FindFirst();
    end;

    [TryFunction]
    local procedure TryKeyBlob(var Row: Record "Probe Rb Row")
    begin
        Row.SetCurrentKey(Pic);
        Row.FindFirst();
    end;

    [Test]
    procedure Hyperlink_InTestRun_Outcome()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('hyperlink', Format(TryHyperlink()));
        Observer.ObserveError('hyperlink');
        Observer.Expect('hyperlink', 'No');
        Observer.Expect('hyperlink|text', 'Unhandled UI: Hyperlink https://example.com/probe');
        Observer.Expect('hyperlink|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryHyperlink()
    begin
        Hyperlink('https://example.com/probe');
    end;

    [Test]
    procedure CurrReportLanguage_BeforeSet_Zero_AndFormatEffect()
    var
        Rep: Report "Probe Language Report";
        Log: Codeunit "Probe Lang Log";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('reportLog', Log.Take());
        Observer.Expect('reportLog', 'languageBeforeSet=1033;language1031=1031;dateFormatAfter1031=03/05/30;decimalFormatAfter1031=1,234.5;dateFormatAfter1033=03/05/30;decimalFormatAfter1033=1,234.5;languageZero_error=Invalid language ID supplied: 0.|Argument;languageAfterZeroAttempt=1033;formatRegionBeforeSet=[];');
        Observer.Verify();
    end;

    // Corpus issue #664 item 113: ClearAll in a table extension (tableextension 82360, misc/lt-bo2-odd-leads/BoClearAllExt.al):
    // in an extension procedure, in an extension field's OnValidate, and whether ClearAll in base table code clears the extension's globals.
    [Test]
    procedure ClearAll_InTableExtension_WhatIsCleared()
    var
        Row: Record "Probe Rb Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.Id := 3;
        Row.Name := 'abc';
        Row.LtBoNum := 4;
        Row.LtBoSetExtGlobal(8);
        Row.SetRange(Id, 3);
        Observer.Observe('ext procedure', Row.LtBoClearAllInExt());
        Observer.Observe('ext global after ext procedure', Format(Row.LtBoGetExtGlobal()));
        Observer.Observe('caller filter after ext procedure', '[' + Row.GetFilters() + ']');
        Row.LtBoSetExtGlobal(8);
        Row.Validate(LtBoNum, 6);
        Observer.Observe('ext OnValidate', Row.LtBoTraceOfValidate());
        Observer.Observe('ext global after ext OnValidate', Format(Row.LtBoGetExtGlobal()));
        Row.LtBoSetExtGlobal(8);
        Observer.Observe('base procedure', Row.ClearAllInTable());
        Observer.Observe('ext global after base ClearAll', Format(Row.LtBoGetExtGlobal()));
        Observer.Finish();
    end;

    // Corpus issue #664 item 113: ClearAll in a page extension (pageextension 82361 on "Probe Ui Card"): in a procedure called through
    // a Page variable that is not open, and in the extension's OnOpenPage (trace kept by codeunit 82362).
    [Test]
    procedure ClearAll_InPageExtension_WhatIsCleared()
    var
        Card: Page "Probe Ui Card";
        CardView: TestPage "Probe Ui Card";
        Trace: Codeunit "LT BO ClearAll Trace";
        Observer: Codeunit "Probe Observer";
    begin
        Card.LtBoSetPageGlobals(5, 'set');
        Observer.Observe('before', Card.LtBoDescribe());
        Observer.Observe('page ext procedure', Card.LtBoClearAllInPageExt());
        Observer.Observe('after', Card.LtBoDescribe());
        Trace.Take();
        CardView.OpenView();
        CardView.Close();
        Observer.Observe('OnOpenPage trace', Trace.Take());
        Observer.Finish();
    end;
}

// The log of the report above, a SingleInstance codeunit used by this test codeunit only.
codeunit 69164 "Probe Lang Log"
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
