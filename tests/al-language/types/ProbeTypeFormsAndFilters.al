// Probe: Evaluate/Format of enums and DateFormula, InitValue of a DateFormula, Clear, CopyFilter, TableFilter,
// Format(Record) with FlowFilter / unloaded Blob, arrays of Option, ClientType and ExecutionMode members.
enum 69453 "Probe Ty Kind"
{
    Extensible = true;

    value(0; None) { Caption = 'No Kind'; }
    value(1; Alpha) { }
    value(5; "Beta Gamma") { }
}

table 69454 "Probe Ty Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; CodeF; Code[10]) { }
        field(3; TextF; Text[20]) { }
        field(4; Period; DateFormula) { InitValue = '1Y'; }
        field(5; Filt; TableFilter) { }
        field(6; Flt; Integer) { FieldClass = FlowFilter; }
        field(7; Pic; Blob) { }
        field(8; KindF; Enum "Probe Ty Kind") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(Sec; TextF) { }
    }
}

codeunit 69455 "Probe Type Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Enum_FormatNineAndZeroAndTwo()
    var
        K: Enum "Probe Ty Kind";
        Observer: Codeunit "Probe Observer";
    begin
        K := K::"Beta Gamma";
        Observer.Observe('format0', Format(K));
        Observer.Observe('format2', Format(K, 0, 2));
        Observer.Observe('format9', Format(K, 0, 9));
        K := K::None;
        Observer.Observe('zeroFormat0', Format(K));
        Observer.Observe('zeroFormat9', Format(K, 0, 9));
        Observer.Expect('format0', 'Beta Gamma');
        Observer.Expect('format2', '5');
        Observer.Expect('format9', '5');
        Observer.Expect('zeroFormat0', 'No Kind');
        Observer.Expect('zeroFormat9', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_Evaluate_Forms()
    var
        K: Enum "Probe Ty Kind";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('exactName_result', Format(Evaluate(K, 'Beta Gamma')));
        Observer.Observe('exactName_value', Format(K, 0, 2));
        K := K::None;
        Observer.Observe('lowerName_result', Format(Evaluate(K, 'beta gamma')));
        Observer.Observe('lowerName_value', Format(K, 0, 2));
        K := K::None;
        Observer.Observe('caption_result', Format(Evaluate(K, 'No Kind')));
        K := K::None;
        Observer.Observe('ordinalText_result', Format(Evaluate(K, '5')));
        Observer.Observe('ordinalText_value', Format(K, 0, 2));
        K := K::None;
        Observer.Observe('format9ordinal_result', Format(Evaluate(K, '5', 9)));
        Observer.Observe('format9name_result', Format(Evaluate(K, 'Alpha', 9)));
        Observer.Observe('unknown_result', Format(Evaluate(K, 'Nope')));
        Observer.Observe('unknownOrdinal_result', Format(Evaluate(K, '7')));
        Observer.Expect('exactName_result', 'Yes');
        Observer.Expect('exactName_value', '5');
        Observer.Expect('lowerName_result', 'Yes');
        Observer.Expect('lowerName_value', '5');
        Observer.Expect('caption_result', 'Yes');
        Observer.Expect('ordinalText_result', 'Yes');
        Observer.Expect('ordinalText_value', '5');
        Observer.Expect('format9ordinal_result', 'Yes');
        Observer.Expect('format9name_result', 'Yes');
        Observer.Expect('unknown_result', 'No');
        Observer.Expect('unknownOrdinal_result', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_Evaluate_FormatNumberTwo_NonEnglish()
    var
        DF: DateFormula;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('german1T_result', Format(Evaluate(DF, '1T', 2)));
        Observer.Observe('german1T_value', Format(DF));
        Clear(DF);
        Observer.Observe('german1M_format2', Format(Evaluate(DF, '1M', 2)));
        Clear(DF);
        Observer.Observe('english1D_format2', Format(Evaluate(DF, '1D', 2)));
        Observer.Observe('english1D_value', Format(DF));
        Clear(DF);
        Observer.Observe('english1D_format0', Format(Evaluate(DF, '1D', 0)));
        Observer.Observe('english1D_format0_value', Format(DF));
        Clear(DF);
        Observer.Observe('lowerWithBrackets', Format(Evaluate(DF, '<1m + cm>')));
        Observer.Observe('lowerWithBrackets_value', Format(DF));
        Observer.Expect('german1T_result', 'No');
        Observer.Expect('german1T_value', '');
        Observer.Expect('german1M_format2', 'Yes');
        Observer.Expect('english1D_format2', 'Yes');
        Observer.Expect('english1D_value', '1D');
        Observer.Expect('english1D_format0', 'Yes');
        Observer.Expect('english1D_format0_value', '1D');
        Observer.Expect('lowerWithBrackets', 'Yes');
        Observer.Expect('lowerWithBrackets_value', '1M+CM');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_InitValue_OfTableField()
    var
        Row: Record "Probe Ty Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.Init();
        Observer.Observe('afterInit', Format(Row.Period));
        Observer.Observe('calcDateFromJan1', Format(CalcDate(Row.Period, DMY2Date(1, 1, 2030)), 0, 9));
        Observer.Expect('afterInit', '1Y');
        Observer.Expect('calcDateFromJan1', '2031-01-01');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilter_Format_Unset_AndAfterInsertGet()
    var
        Row: Record "Probe Ty Row";
        Other: Record "Probe Ty Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.Init();
        Observer.Observe('unsetFormat', Format(Row.Filt));
        Observer.Observe('unsetLength', Format(StrLen(Format(Row.Filt))));
        Row.DeleteAll();
        Row.Insert();
        Other.Get(Row.Id);
        Observer.Observe('afterRoundTripFormat', Format(Other.Filt));
        Observer.Expect('unsetFormat', '');
        Observer.Expect('unsetLength', '0');
        Observer.Expect('afterRoundTripFormat', '');
        Observer.Verify();
    end;

    local procedure SafeFormat(var Row: Record "Probe Ty Row"): Text
    var
        Result: Text;
    begin
        if TryFormat(Row, Result) then
            exit(ReplaceTabs(Result));
        exit('ERROR: ' + GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryFormat(var Row: Record "Probe Ty Row"; var Result: Text)
    begin
        Result := Format(Row);
    end;

    [Test]
    procedure FormatRecord_WithFlowFilter_BeforeAndAfterSetRange()
    var
        Row: Record "Probe Ty Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.CodeF := 'C1';
        Row.TextF := 'T1';
        Row.Insert();
        Row.Get(1);
        Observer.Observe('beforeFlowFilter', SafeFormat(Row));
        Row.SetRange(Flt, 3);
        Observer.Observe('afterFlowFilter', SafeFormat(Row));
        Row.SetRange(Flt, 3, 8);
        Observer.Observe('afterRangeFlowFilter', SafeFormat(Row));
        Observer.Expect('beforeFlowFilter', '1<TAB>C1<TAB>T1<TAB>1Y<TAB><TAB> <TAB>No Kind<TAB>0');
        Observer.Expect('afterFlowFilter', '1<TAB>C1<TAB>T1<TAB>1Y<TAB><TAB> <TAB>No Kind<TAB>0');
        Observer.Expect('afterRangeFlowFilter', '1<TAB>C1<TAB>T1<TAB>1Y<TAB><TAB> <TAB>No Kind<TAB>0');
        Observer.Verify();
    end;

    [Test]
    procedure FormatRecord_BlobReadFromTableNotLoaded()
    var
        Row: Record "Probe Ty Row";
        Out: OutStream;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Pic.CreateOutStream(Out);
        Out.WriteText('payload');
        Row.Insert();
        Observer.Observe('afterInsertSameVariable', SafeFormat(Row));
        Clear(Row);
        Row.Get(1);
        Observer.Observe('afterGetNoCalcFields', SafeFormat(Row));
        Observer.Observe('hasValueAfterGet', Format(Row.Pic.HasValue()));
        Row.CalcFields(Pic);
        Observer.Observe('afterCalcFields', SafeFormat(Row));
        Observer.Expect('afterInsertSameVariable', '1<TAB><TAB><TAB>1Y<TAB><TAB>*<TAB>No Kind<TAB>0');
        Observer.Expect('afterGetNoCalcFields', '1<TAB><TAB><TAB>1Y<TAB><TAB>*<TAB>No Kind<TAB>0');
        Observer.Expect('hasValueAfterGet', 'Yes');
        Observer.Expect('afterCalcFields', '1<TAB><TAB><TAB>1Y<TAB><TAB>*<TAB>No Kind<TAB>0');
        Observer.Verify();
    end;

    [Test]
    procedure FormatRecord_AssignmentCopiesBlobBytes()
    var
        Row: Record "Probe Ty Row";
        Copy1: Record "Probe Ty Row";
        Out: OutStream;
        InS: InStream;
        Txt: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Pic.CreateOutStream(Out);
        Out.WriteText('abc');
        Copy1 := Row;
        Observer.Observe('copyFormat', ReplaceTabs(Format(Copy1)));
        Copy1.CalcFields(Pic);
        Copy1.Pic.CreateInStream(InS);
        InS.ReadText(Txt);
        Observer.Observe('copyBlobText', Txt);
        Observer.Expect('copyFormat', '1<TAB><TAB><TAB>1Y<TAB><TAB>*<TAB>No Kind<TAB>0');
        Observer.Expect('copyBlobText', '');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_TemporaryRecordWithRows_ThenCount()
    var
        Temp: Record "Probe Ty Row" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Temp.Id := 1;
        Temp.Insert();
        Temp.Id := 2;
        Temp.Insert();
        Temp.SetRange(Id, 1);
        Observer.Observe('countBefore', Format(Temp.Count()));
        Clear(Temp);
        Observer.Observe('countAfter', Format(Temp.Count()));
        Observer.Observe('idAfter', Format(Temp.Id));
        Observer.Observe('filtersAfter', Temp.GetFilters());
        Observer.Observe('isTemporary', Format(Temp.IsTemporary()));
        Observer.Expect('countBefore', '1');
        Observer.Expect('countAfter', '2');
        Observer.Expect('idAfter', '0');
        Observer.Expect('filtersAfter', '');
        Observer.Expect('isTemporary', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_ArrayPassedByVar_AndLocalArray()
    var
        Arr: array[3] of Integer;
        Txts: array[2] of Text;
        Observer: Codeunit "Probe Observer";
    begin
        Arr[1] := 5;
        Arr[2] := 6;
        Arr[3] := 7;
        ClearViaVar(Arr);
        Observer.Observe('afterVarClear', Format(Arr[1]) + ',' + Format(Arr[2]) + ',' + Format(Arr[3]));
        Txts[1] := 'a';
        Txts[2] := 'b';
        Clear(Txts);
        Observer.Observe('afterLocalClear', '[' + Txts[1] + '][' + Txts[2] + ']');
        Observer.Expect('afterVarClear', '0,0,0');
        Observer.Expect('afterLocalClear', '[][]');
        Observer.Verify();
    end;

    local procedure ClearViaVar(var A: array[3] of Integer)
    begin
        Clear(A);
    end;

    [Test]
    procedure Clear_JsonTypes_GiveFreshUnassigned()
    var
        Obj: JsonObject;
        Arr: JsonArray;
        Val: JsonValue;
        Tok: JsonToken;
        Observer: Codeunit "Probe Observer";
    begin
        Obj.Add('a', 1);
        Arr.Add(1);
        Val.SetValue(5);
        Tok := Obj.AsToken();
        Clear(Obj);
        Clear(Arr);
        Clear(Val);
        Clear(Tok);
        Observer.Observe('objText', Format(Obj));
        Observer.Observe('arrCount', Format(Arr.Count()));
        Observer.Observe('valIsNull', Format(Val.IsNull()));
        Observer.Observe('valIsUndefined', Format(Val.IsUndefined()));
        Observer.Observe('tokIsValue', Format(Tok.IsValue()));
        Observer.Observe('tokText', Format(Tok));
        Observer.Expect('objText', '{}');
        Observer.Expect('arrCount', '0');
        Observer.Expect('valIsNull', 'Yes');
        Observer.Expect('valIsUndefined', 'No');
        Observer.Expect('tokIsValue', 'Yes');
        Observer.Expect('tokText', 'null');
        Observer.Verify();
    end;

    [Test]
    procedure OptionArray_DefaultAssignCompare()
    var
        Kinds: array[3] of Option "None",Released,FirmPlanned,Purchase;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('untouched1', Format(Kinds[1]));
        Observer.Observe('untouched1Int', Format(Kinds[1], 0, 2));
        Kinds[2] := Kinds[2]::Purchase;
        Observer.Observe('assigned2', Format(Kinds[2]));
        Observer.Observe('assigned2Int', Format(Kinds[2], 0, 2));
        Observer.Observe('equalsMember', Format(Kinds[2] = Kinds[2]::Purchase));
        Observer.Observe('differs', Format(Kinds[1] = Kinds[2]));
        Kinds[3] := Kinds[2];
        Observer.Observe('copied3', Format(Kinds[3]));
        Observer.Expect('untouched1', 'None');
        Observer.Expect('untouched1Int', '0');
        Observer.Expect('assigned2', 'Purchase');
        Observer.Expect('assigned2Int', '3');
        Observer.Expect('equalsMember', 'Yes');
        Observer.Expect('differs', 'No');
        Observer.Expect('copied3', 'Purchase');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFilter_InsideFilterGroupTwo_AndAcrossFieldTypes()
    var
        Src: Record "Probe Ty Row";
        Dst: Record "Probe Ty Row";
        Observer: Codeunit "Probe Observer";
    begin
        Src.SetFilter(CodeF, 'A*|B1');
        Src.FilterGroup(2);
        Src.SetFilter(CodeF, '<>Z');
        Src.FilterGroup(0);
        Dst.SetFilter(TextF, 'old');
        asserterror Src.CopyFilter(CodeF, Dst.TextF);
        Observer.ObserveError('group0CodeToText_error');
        Observer.Observe('group0CodeToText', Dst.GetFilter(TextF));
        Dst.FilterGroup(2);
        Observer.Observe('dstGroup2AfterGroup0Copy', Dst.GetFilter(TextF));
        Dst.FilterGroup(0);
        Src.FilterGroup(2);
        Dst.Reset();
        Src.CopyFilter(CodeF, Dst.CodeF);
        Observer.Observe('srcInGroup2_copyToDstGroup0', Dst.GetFilter(CodeF));
        Src.FilterGroup(0);
        Src.Reset();
        Dst.SetFilter(CodeF, 'X');
        Src.CopyFilter(CodeF, Dst.CodeF);
        Observer.Observe('unfilteredSrcClearsDst', '[' + Dst.GetFilter(CodeF) + ']');
        Observer.Expect('group0CodeToText_error|text', 'The type of the constant must be compatible with that of the TextF field, and the length of the constant must not exceed the length of the field.\r\\r\Type: Text <-- Code\r\Field: TextF <-- CodeF\r\Table: Probe Ty Row');
        Observer.Expect('group0CodeToText_error|code', 'NCLCSRTS:TableEqualValue');
        Observer.Expect('group0CodeToText', 'old');
        Observer.Expect('dstGroup2AfterGroup0Copy', '');
        Observer.Expect('srcInGroup2_copyToDstGroup0', '<>Z');
        Observer.Expect('unfilteredSrcClearsDst', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_Ascending_AffectsFindOrder()
    var
        Row: Record "Probe Ty Row";
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        RecRef.Open(Database::"Probe Ty Row");
        Observer.Observe('defaultAscending', Format(RecRef.Ascending()));
        RecRef.Ascending(false);
        RecRef.FindFirst();
        Observer.Observe('firstDescending', Format(RecRef.Field(1).Value));
        Observer.Observe('ascendingAfter', Format(RecRef.Ascending()));
        Observer.Expect('defaultAscending', 'Yes');
        Observer.Expect('firstDescending', '2');
        Observer.Expect('ascendingAfter', 'No');
        Observer.Verify();
    end;

    local procedure ReplaceTabs(Value: Text): Text
    var
        Tab: Text[1];
    begin
        Tab[1] := 9;
        exit(Value.Replace(Tab, '<TAB>'));
    end;
}
