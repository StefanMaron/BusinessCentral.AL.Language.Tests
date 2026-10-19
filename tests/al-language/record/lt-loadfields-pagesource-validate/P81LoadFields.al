// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setloadfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained tables 70301, 70302 and codeunit 70303
// Probe: written against BC 29 (tag P81, GitHub issue 81); every literal asserted later is what a local BC 29 tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetLoadFields / AddLoadFields with a FlowField, a FlowFilter field, a Blob, a Media and the system fields; AreFieldsLoaded, the values read, CalcFields on them, Modify afterwards
// BC versions: 29 (27 and 28 by CI)

table 70301 "LT P81 LF Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Parent Code"; Code[10]) { }
        field(3; Kind; Code[10]) { }
        field(4; Amount; Decimal) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 70302 "LT P81 LF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; Notes; Blob) { }
        field(5; Pic; Media) { }
        field(6; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT P81 LF Child" where("Parent Code" = field(Code), Kind = field("Kind Filter")));
        }
        field(7; "Kind Filter"; Code[10]) { FieldClass = FlowFilter; }
        field(8; "Sum Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT P81 LF Child".Amount where("Parent Code" = field(Code)));
        }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 70303 "LT P81 LoadFields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P81 LF Row";
        Child: Record "LT P81 LF Child";
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        Row.Init();
        Row.Code := 'A';
        Row.Name := 'alpha';
        Row.Qty := 7;
        SetNotes(Row, 'blob-a');
        Row.Insert();
        Row.Init();
        Row.Code := 'B';
        Row.Name := 'bravo';
        Row.Qty := 8;
        Row.Insert();
        Child.Init();
        Child."Entry No." := 1;
        Child."Parent Code" := 'A';
        Child.Kind := 'X';
        Child.Amount := 10;
        Child.Insert();
        Child.Init();
        Child."Entry No." := 2;
        Child."Parent Code" := 'A';
        Child.Kind := 'Y';
        Child.Amount := 20;
        Child.Insert();
    end;

    local procedure SetNotes(var Row: Record "LT P81 LF Row"; Txt: Text)
    var
        OutS: OutStream;
    begin
        Row.Notes.CreateOutStream(OutS);
        OutS.WriteText(Txt);
    end;

    local procedure GetNotes(var Row: Record "LT P81 LF Row"): Text
    var
        InS: InStream;
        T: Text;
    begin
        if not Row.Notes.HasValue() then
            exit('<empty>');
        Row.Notes.CreateInStream(InS);
        InS.ReadText(T);
        exit(T);
    end;

    [TryFunction]
    local procedure TryLoaded(var Row: Record "LT P81 LF Row"; Which: Integer; var R: Boolean)
    begin
        case Which of
            1:
                R := Row.AreFieldsLoaded(Row.Code);
            2:
                R := Row.AreFieldsLoaded(Row.Name);
            3:
                R := Row.AreFieldsLoaded(Row.Qty);
            4:
                R := Row.AreFieldsLoaded(Row.Notes);
            5:
                R := Row.AreFieldsLoaded(Row.Pic);
            6:
                R := Row.AreFieldsLoaded(Row.Cnt);
            7:
                R := Row.AreFieldsLoaded(Row."Kind Filter");
            8:
                R := Row.AreFieldsLoaded(Row."Sum Amount");
            9:
                R := Row.AreFieldsLoaded(Row.SystemId);
            10:
                R := Row.AreFieldsLoaded(Row.SystemCreatedAt);
            11:
                R := Row.AreFieldsLoaded(Row.SystemModifiedAt);
            12:
                R := Row.AreFieldsLoaded(Row.SystemCreatedBy);
            13:
                R := Row.AreFieldsLoaded(Row.SystemModifiedBy);
        end;
    end;

    local procedure Loaded(var Row: Record "LT P81 LF Row"; Which: Integer): Text
    var
        R: Boolean;
    begin
        if TryLoaded(Row, Which, R) then
            exit(Format(R));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ObserveLoaded(var Observer: Codeunit "Probe Observer"; var Row: Record "LT P81 LF Row"; Prefix: Text)
    var
        Names: List of [Text];
        i: Integer;
    begin
        Names.Add('Code');
        Names.Add('Name');
        Names.Add('Qty');
        Names.Add('Notes');
        Names.Add('Pic');
        Names.Add('Cnt');
        Names.Add('KindFilter');
        Names.Add('SumAmount');
        Names.Add('SystemId');
        Names.Add('SystemCreatedAt');
        Names.Add('SystemModifiedAt');
        Names.Add('SystemCreatedBy');
        Names.Add('SystemModifiedBy');
        for i := 1 to Names.Count() do
            Observer.Observe(Prefix + '_loaded_' + Names.Get(i), Loaded(Row, i));
    end;

    [Test]
    procedure LoadFields_Name_Get_LoadedFlags()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('name', Row.Name);
        Observer.Observe('qty', Format(Row.Qty));
        Observer.Observe('code', Row.Code);
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'Yes');
        Observer.Expect('a_loaded_Qty', 'No');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'No');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('name', 'alpha');
        Observer.Expect('qty', '7');
        Observer.Expect('code', 'A');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_FlowField_ReadThenCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Cnt);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('cnt_before', Format(Row.Cnt));
        Observer.Observe('name', Row.Name);
        Row.CalcFields(Cnt);
        Observer.Observe('cnt_after', Format(Row.Cnt));
        Observer.Observe('loaded_cnt_after', Loaded(Row, 6));
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'No');
        Observer.Expect('a_loaded_Qty', 'No');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'No');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('cnt_before', '0');
        Observer.Expect('name', 'alpha');
        Observer.Expect('cnt_after', '2');
        Observer.Expect('loaded_cnt_after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_FlowFieldSum_Find()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields("Sum Amount");
        Row.SetRange(Code, 'A');
        Row.FindFirst();
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('sum_before', Format(Row."Sum Amount"));
        Row.CalcFields("Sum Amount");
        Observer.Observe('sum_after', Format(Row."Sum Amount"));
        Observer.Observe('name', Row.Name);
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'No');
        Observer.Expect('a_loaded_Qty', 'No');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'No');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('sum_before', '0');
        Observer.Expect('sum_after', '30');
        Observer.Expect('name', 'alpha');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_FlowFilterField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields("Kind Filter");
        Row.SetRange("Kind Filter", 'X');
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('filter', Row.GetFilter("Kind Filter"));
        Row.CalcFields(Cnt);
        Observer.Observe('cnt_x', Format(Row.Cnt));
        Observer.Observe('loaded_cnt_after', Loaded(Row, 6));
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'No');
        Observer.Expect('a_loaded_Qty', 'No');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'No');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('filter', 'X');
        Observer.Expect('cnt_x', '1');
        Observer.Expect('loaded_cnt_after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_FlowFieldAndFlowFilter_Together()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Cnt, "Kind Filter");
        Row.SetRange("Kind Filter", 'Y');
        Row.Get('A');
        Observer.Observe('loaded_cnt', Loaded(Row, 6));
        Observer.Observe('loaded_kindfilter', Loaded(Row, 7));
        Observer.Observe('loaded_name', Loaded(Row, 2));
        Row.CalcFields(Cnt);
        Observer.Observe('cnt_y', Format(Row.Cnt));
        Row.SetRange("Kind Filter", 'Z');
        Row.CalcFields(Cnt);
        Observer.Observe('cnt_z', Format(Row.Cnt));
        Row.SetRange("Kind Filter");
        Row.CalcFields(Cnt);
        Observer.Observe('cnt_all', Format(Row.Cnt));
        Observer.Expect('loaded_cnt', 'Yes');
        Observer.Expect('loaded_kindfilter', 'Yes');
        Observer.Expect('loaded_name', 'No');
        Observer.Expect('cnt_y', '1');
        Observer.Expect('cnt_z', '0');
        Observer.Expect('cnt_all', '2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Blob_ReadAndCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Notes);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('hasvalue_before', Format(Row.Notes.HasValue()));
        Row.CalcFields(Notes);
        Observer.Observe('hasvalue_after', Format(Row.Notes.HasValue()));
        Observer.Observe('text', GetNotes(Row));
        Observer.Observe('name', Row.Name);
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'No');
        Observer.Expect('a_loaded_Qty', 'No');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'No');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('hasvalue_before', 'Yes');
        Observer.Expect('hasvalue_after', 'Yes');
        Observer.Expect('text', 'blob-a');
        Observer.Expect('name', 'alpha');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_BlobNotLoaded_CalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        Observer.Observe('loaded_notes_before', Loaded(Row, 4));
        Observer.Observe('hasvalue_before', Format(Row.Notes.HasValue()));
        Row.CalcFields(Notes);
        Observer.Observe('loaded_notes_after', Loaded(Row, 4));
        Observer.Observe('hasvalue_after', Format(Row.Notes.HasValue()));
        Observer.Observe('text', GetNotes(Row));
        Observer.Expect('loaded_notes_before', 'Yes');
        Observer.Expect('hasvalue_before', 'Yes');
        Observer.Expect('loaded_notes_after', 'Yes');
        Observer.Expect('hasvalue_after', 'Yes');
        Observer.Expect('text', 'blob-a');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Media_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Pic);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('pic_hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('pic_mediaid_null', Format(IsNullGuid(Row.Pic.MediaId())));
        Observer.Observe('name', Row.Name);
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'No');
        Observer.Expect('a_loaded_Qty', 'No');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'Yes');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('pic_hasvalue', 'No');
        Observer.Expect('pic_mediaid_null', 'Yes');
        Observer.Expect('name', 'alpha');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_MediaNotLoaded()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        Observer.Observe('loaded_pic', Loaded(Row, 5));
        Observer.Observe('pic_hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('pic_mediaid_null', Format(IsNullGuid(Row.Pic.MediaId())));
        asserterror Row.CalcFields(Pic);
        Observer.ObserveError('af329');
        Observer.Observe('loaded_pic_after_calc', Loaded(Row, 5));
        Observer.Expect('loaded_pic', 'No');
        Observer.Expect('pic_hasvalue', 'No');
        Observer.Expect('pic_mediaid_null', 'Yes');
        Observer.Expect('af329|text', 'The Pic field in the LT P81 LF Row table must be a FlowField.');
        Observer.Expect('af329|code', 'DB:Ok');
        Observer.Expect('loaded_pic_after_calc', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_SystemId_Only()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
    begin
        Seed();
        Full.Get('A');
        Row.SetLoadFields(SystemId);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('systemid_null', Format(IsNullGuid(Row.SystemId)));
        Observer.Observe('systemid_equals_full', Format(Row.SystemId = Full.SystemId));
        Observer.Observe('name', Row.Name);
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'Yes');
        Observer.Expect('a_loaded_Qty', 'Yes');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'Yes');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('systemid_null', 'No');
        Observer.Expect('systemid_equals_full', 'Yes');
        Observer.Expect('name', 'alpha');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_SystemTimestamps_Only()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
    begin
        Seed();
        Full.Get('A');
        Row.SetLoadFields(SystemCreatedAt, SystemModifiedAt);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('createdat_zero', Format(Row.SystemCreatedAt = 0DT));
        Observer.Observe('modifiedat_ge_createdat', Format(Row.SystemModifiedAt >= Row.SystemCreatedAt));
        Observer.Observe('createdat_equals_full', Format(Row.SystemCreatedAt = Full.SystemCreatedAt));
        Observer.Observe('createdby_null', Format(IsNullGuid(Row.SystemCreatedBy)));
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'Yes');
        Observer.Expect('a_loaded_Qty', 'Yes');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'Yes');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('createdat_zero', 'No');
        Observer.Expect('modifiedat_ge_createdat', 'Yes');
        Observer.Expect('createdat_equals_full', 'Yes');
        Observer.Expect('createdby_null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_SystemCreatedBy_Only()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
    begin
        Seed();
        Full.Get('A');
        Row.SetLoadFields(SystemCreatedBy, SystemModifiedBy);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('createdby_equals_full', Format(Row.SystemCreatedBy = Full.SystemCreatedBy));
        Observer.Observe('modifiedby_equals_full', Format(Row.SystemModifiedBy = Full.SystemModifiedBy));
        Observer.Observe('systemid_null', Format(IsNullGuid(Row.SystemId)));
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'Yes');
        Observer.Expect('a_loaded_Qty', 'Yes');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'Yes');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('createdby_equals_full', 'Yes');
        Observer.Expect('modifiedby_equals_full', 'Yes');
        Observer.Expect('systemid_null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AddLoadFields_WithoutSetLoadFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.AddLoadFields(Qty);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('name', Row.Name);
        Observer.Observe('qty', Format(Row.Qty));
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'Yes');
        Observer.Expect('a_loaded_Qty', 'Yes');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'Yes');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('name', 'alpha');
        Observer.Expect('qty', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SetLoadFields_Empty_ResetsToAllFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.SetLoadFields();
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'Yes');
        Observer.Expect('a_loaded_Qty', 'Yes');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'Yes');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetLoadFields_AfterGet_AppliesToNextRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.Get('A');
        Observer.Observe('full_loaded_qty', Loaded(Row, 3));
        Row.SetLoadFields(Name);
        Observer.Observe('after_set_loaded_qty', Loaded(Row, 3));
        Row.Get('B');
        Observer.Observe('b_name', Row.Name);
        Observer.Observe('b_qty', Format(Row.Qty));
        Observer.Observe('b_loaded_qty', Loaded(Row, 3));
        Observer.Observe('b_loaded_name', Loaded(Row, 2));
        Observer.Expect('full_loaded_qty', 'Yes');
        Observer.Expect('after_set_loaded_qty', 'Yes');
        Observer.Expect('b_name', 'bravo');
        Observer.Expect('b_qty', '8');
        Observer.Expect('b_loaded_qty', 'Yes');
        Observer.Expect('b_loaded_name', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_FindSet_Loop()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        n: Integer;
    begin
        Seed();
        Row.SetLoadFields(Name, Cnt);
        if Row.FindSet() then
            repeat
                n += 1;
                Row.CalcFields(Cnt);
                Observer.Observe('row' + Format(n) + '_name', Row.Name);
                Observer.Observe('row' + Format(n) + '_qty', Format(Row.Qty));
                Observer.Observe('row' + Format(n) + '_cnt', Format(Row.Cnt));
            until Row.Next() = 0;
        Observer.Observe('rows', Format(n));
        Observer.Expect('row1_name', 'alpha');
        Observer.Expect('row1_qty', '7');
        Observer.Expect('row1_cnt', '2');
        Observer.Expect('row2_name', 'bravo');
        Observer.Expect('row2_qty', '8');
        Observer.Expect('row2_cnt', '0');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFields_OnNotLoadedFlowAndBlob()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        Row.CalcFields(Cnt, "Sum Amount", Notes);
        Observer.Observe('cnt', Format(Row.Cnt));
        Observer.Observe('sum', Format(Row."Sum Amount"));
        Observer.Observe('notes', GetNotes(Row));
        Observer.Observe('loaded_cnt', Loaded(Row, 6));
        Observer.Observe('loaded_sum', Loaded(Row, 8));
        Observer.Observe('loaded_notes', Loaded(Row, 4));
        Observer.Observe('loaded_qty', Loaded(Row, 3));
        Observer.Expect('cnt', '2');
        Observer.Expect('sum', '30');
        Observer.Expect('notes', 'blob-a');
        Observer.Expect('loaded_cnt', 'Yes');
        Observer.Expect('loaded_sum', 'Yes');
        Observer.Expect('loaded_notes', 'Yes');
        Observer.Expect('loaded_qty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_AfterPartialLoad_KeepsUnloadedFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        Row.Name := 'beta';
        Row.Modify();
        Full.Get('A');
        Full.CalcFields(Cnt, Notes);
        Observer.Observe('name', Full.Name);
        Observer.Observe('qty', Format(Full.Qty));
        Observer.Observe('notes', GetNotes(Full));
        Observer.Observe('cnt', Format(Full.Cnt));
        Observer.Expect('name', 'beta');
        Observer.Expect('qty', '7');
        Observer.Expect('notes', 'blob-a');
        Observer.Expect('cnt', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_AfterLoadingOnlyFlowField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Cnt);
        Row.Get('A');
        Row.CalcFields(Cnt);
        Row.Modify();
        Full.Get('A');
        Observer.Observe('name', Full.Name);
        Observer.Observe('qty', Format(Full.Qty));
        Observer.Observe('row_name_in_buffer', Row.Name);
        Observer.Expect('name', 'alpha');
        Observer.Expect('qty', '7');
        Observer.Expect('row_name_in_buffer', 'alpha');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_AfterLoadingOnlyBlob_NewText()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Notes);
        Row.Get('A');
        Row.CalcFields(Notes);
        SetNotes(Row, 'blob-new');
        Row.Modify();
        Full.Get('A');
        Full.CalcFields(Notes);
        Observer.Observe('notes', GetNotes(Full));
        Observer.Observe('name', Full.Name);
        Observer.Observe('qty', Format(Full.Qty));
        Observer.Expect('notes', 'blob-new');
        Observer.Expect('name', 'alpha');
        Observer.Expect('qty', '7');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_AssignUnloadedField_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        Row.Qty := 99;
        Row.Modify();
        Full.Get('A');
        Observer.Observe('name', Full.Name);
        Observer.Observe('qty', Format(Full.Qty));
        Observer.Expect('name', 'alpha');
        Observer.Expect('qty', '99');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_WithSystemFieldsLoaded_Timestamps()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
        CreatedBefore: DateTime;
    begin
        Seed();
        Full.Get('A');
        CreatedBefore := Full.SystemCreatedAt;
        Row.SetLoadFields(SystemId, SystemModifiedAt, Name);
        Row.Get('A');
        Row.Name := 'gamma';
        Row.Modify();
        Full.Get('A');
        Observer.Observe('name', Full.Name);
        Observer.Observe('created_unchanged', Format(Full.SystemCreatedAt = CreatedBefore));
        Observer.Observe('modified_ge_created', Format(Full.SystemModifiedAt >= Full.SystemCreatedAt));
        Observer.Observe('systemid_same', Format(Row.SystemId = Full.SystemId));
        Observer.Expect('name', 'gamma');
        Observer.Expect('created_unchanged', 'Yes');
        Observer.Expect('modified_ge_created', 'Yes');
        Observer.Expect('systemid_same', 'Yes');
        Observer.Verify();
    end;
}
