// Observe-only probes (writer A). Rows: RecordRef GetTable/SetTable/Duplicate, KeyRef/FieldRef Active, FieldRef
// IsEnum/EnumValueCount/OptionCaption, GetFilters text, Format(RecordId), permissions/locking, temp records and
// asserterror, write transaction state, LastUsedRowVersion, LockTimeout.
enum 69800 "PA Rec Enum"
{
    Extensible = true;
    value(0; Zero) { Caption = 'Zero Caption'; }
    value(1; One) { }
    value(5; Five) { Caption = 'Five Caption'; }
}

table 69804 "PA Rec Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { Caption = 'Identifier'; }
        field(2; Cd; Code[20]) { }
        field(3; Txt; Text[50]) { }
        field(4; Opt; Option) { OptionMembers = Alpha,Beta,Gamma; OptionCaption = 'First,Second,Third'; }
        field(5; OptPlain; Option) { OptionMembers = Xx,Yy; }
        field(6; En; Enum "PA Rec Enum") { }
        field(7; Dt; Date) { }
        field(8; Dec; Decimal) { }
        field(9; Flag; Boolean) { }
        field(20; Disabled; Integer) { ObsoleteState = No; Enabled = false; }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(K2; Cd) { }
        key(K3; Txt, Dt) { }
    }
}

table 69805 "PA Pk2 Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; A; Code[10]) { }
        field(2; B; Integer) { }
        field(3; V; Text[20]) { }
    }
    keys { key(PK; A, B) { Clustered = true; } }
}

codeunit 69810 "PA RecordRef Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure GetTable_CopiesBufferFiltersKeyDirection()
    var
        O: Codeunit "Probe Observer";
        Rec: Record "PA Rec Row";
        RR: RecordRef;
    begin
        Rec.Id := 7;
        Rec.Txt := 'buffered';
        Rec.SetRange(Id, 1, 5);
        Rec.SetFilter(Cd, 'A*');
        Rec.SetCurrentKey(Cd);
        Rec.SetAscending(Cd, false);
        RR.GetTable(Rec);
        O.Observe('rr_getfilters', RR.GetFilters());
        O.Observe('rr_currentkeyindex', Format(RR.CurrentKeyIndex()));
        O.Observe('rr_ascending', Format(RR.Ascending()));
        O.Observe('rr_buffer_id', Format(RR.Field(1).Value));
        O.Observe('rr_buffer_txt', Format(RR.Field(3).Value));
        O.Observe('rr_getview', RR.GetView());
        RR.Close();
        O.Expect('rr_getfilters', 'Identifier: 1..5, Cd: A*');
        O.Expect('rr_currentkeyindex', '2');
        O.Expect('rr_ascending', 'No');
        O.Expect('rr_buffer_id', '7');
        O.Expect('rr_buffer_txt', 'buffered');
        O.Expect('rr_getview', 'VERSION(1) SORTING(Cd) ORDER(Descending) WHERE(Identifier=FILTER(1..5),Cd=FILTER(A*))');
        O.Verify();
    end;

    [Test]
    procedure GetTable_CopyIsIndependentOfRecord()
    var
        O: Codeunit "Probe Observer";
        Rec: Record "PA Rec Row";
        RR: RecordRef;
    begin
        Rec.Id := 7;
        Rec.SetRange(Id, 1, 5);
        RR.GetTable(Rec);
        Rec.SetRange(Id, 100, 200);
        Rec.Id := 8;
        O.Observe('rr_filters_after_rec_change', RR.GetFilters());
        O.Observe('rr_id_after_rec_change', Format(RR.Field(1).Value));
        RR.Field(1).SetRange(50, 60);
        O.Observe('rec_filters_after_rr_change', Rec.GetFilters());
        O.Expect('rr_filters_after_rec_change', 'Identifier: 1..5');
        O.Expect('rr_id_after_rec_change', '7');
        O.Expect('rec_filters_after_rr_change', 'Identifier: 100..200');
        O.Verify();
    end;

    [Test]
    procedure SetTable_CopiesIntoRecord()
    var
        O: Codeunit "Probe Observer";
        Rec: Record "PA Rec Row";
        Rec2: Record "PA Rec Row";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec2.SetRange(Id, 500, 600);
        Rec2.Txt := 'old';
        RR.Open(Database::"PA Rec Row");
        RR.Field(1).Value := 3;
        RR.Field(3).Value := 'fromref';
        FR := RR.Field(2);
        FR.SetFilter('X*');
        RR.CurrentKeyIndex(2);
        RR.Ascending(false);
        RR.SetTable(Rec2);
        O.Observe('rec2_getfilters', Rec2.GetFilters());
        O.Observe('rec2_currentkey', Rec2.CurrentKey());
        O.Observe('rec2_ascending', Format(Rec2.Ascending()));
        O.Observe('rec2_txt', Rec2.Txt);
        O.Observe('rec2_id', Format(Rec2.Id));
        RR.Close();
        O.Expect('rec2_getfilters', 'Cd: X*');
        O.Expect('rec2_currentkey', 'Cd');
        O.Expect('rec2_ascending', 'No');
        O.Expect('rec2_txt', 'fromref');
        O.Expect('rec2_id', '3');
        O.Verify();
    end;

    [Test]
    procedure SetTable_ReplacesOrKeepsOldFilters()
    var
        O: Codeunit "Probe Observer";
        Rec2: Record "PA Rec Row";
        RR: RecordRef;
    begin
        Rec2.SetRange(Id, 500, 600);
        RR.Open(Database::"PA Rec Row");
        RR.SetTable(Rec2);
        O.Observe('rec2_getfilters_after_empty_ref', '[' + Rec2.GetFilters() + ']');
        RR.Close();
        O.Expect('rec2_getfilters_after_empty_ref', '[]');
        O.Verify();
    end;

    [Test]
    procedure Duplicate_IsIndependent()
    var
        O: Codeunit "Probe Observer";
        RR: RecordRef;
        RR2: RecordRef;
    begin
        RR.Open(Database::"PA Rec Row");
        RR.Field(1).SetRange(1, 5);
        RR.Field(1).Value := 4;
        RR2 := RR.Duplicate();
        RR2.Field(1).SetRange(10, 20);
        RR2.Field(1).Value := 15;
        O.Observe('rr_filters', RR.GetFilters());
        O.Observe('rr2_filters', RR2.GetFilters());
        O.Observe('rr_id', Format(RR.Field(1).Value));
        O.Observe('rr2_id', Format(RR2.Field(1).Value));
        O.Observe('rr2_isempty_state', Format(RR2.Count()));
        RR.Close();
        RR2.Close();
        O.Expect('rr_filters', 'Identifier: 1..5');
        O.Expect('rr2_filters', 'Identifier: 10..20');
        O.Expect('rr_id', '4');
        O.Expect('rr2_id', '15');
        O.Expect('rr2_isempty_state', '0');
        O.Verify();
    end;

    [Test]
    procedure Duplicate_OfTemporaryRef()
    var
        O: Codeunit "Probe Observer";
        RR: RecordRef;
        RR2: RecordRef;
    begin
        RR.Open(Database::"PA Rec Row", true);
        RR.Field(1).Value := 1;
        RR.Insert();
        O.Observe('temporary_duplicate', TryDup(RR));
        O.Expect('temporary_duplicate', 'ok istemporary=Yes count=1');
        O.Verify();
    end;

    local procedure TryDup(RR: RecordRef): Text
    var
        Res: Text;
    begin
        if TryDupF(RR, Res) then
            exit(Res);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryDupF(RR: RecordRef; var Res: Text)
    var
        RR2: RecordRef;
    begin
        RR2 := RR.Duplicate();
        Res := 'ok istemporary=' + Format(RR2.IsTemporary()) + ' count=' + Format(RR2.Count());
    end;

    [Test]
    procedure KeyRef_And_FieldRef_Active()
    var
        O: Codeunit "Probe Observer";
        RR: RecordRef;
        KR: KeyRef;
        FR: FieldRef;
        i: Integer;
    begin
        RR.Open(Database::"PA Rec Row");
        O.Observe('keycount', Format(RR.KeyCount()));
        for i := 1 to RR.KeyCount() do begin
            KR := RR.KeyIndex(i);
            O.Observe('key_' + Format(i) + '_active', Format(KR.Active()) + ' fields=' + Format(KR.FieldCount()));
        end;
        O.Observe('fieldcount', Format(RR.FieldCount()));
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            O.Observe('fieldindex_' + Format(i), Format(FR.Number()) + ' ' + FR.Name() + ' active=' + Format(FR.Active()));
        end;
        O.Observe('field_20_exist', Format(RR.FieldExist(20)));
        O.Observe('field_20_active', TryActive(RR, 20));
        RR.Close();
        O.Expect('keycount', '4');
        O.Expect('key_1_active', 'Yes fields=1');
        O.Expect('key_2_active', 'Yes fields=1');
        O.Expect('key_3_active', 'Yes fields=2');
        O.Expect('key_4_active', 'Yes fields=1');
        O.Expect('fieldindex_1', '1 Id active=Yes');
        O.Expect('fieldindex_2', '2 Cd active=Yes');
        O.Expect('fieldindex_3', '3 Txt active=Yes');
        O.Expect('fieldindex_4', '4 Opt active=Yes');
        O.Expect('fieldindex_5', '5 OptPlain active=Yes');
        O.Expect('fieldindex_6', '6 En active=Yes');
        O.Expect('fieldindex_7', '7 Dt active=Yes');
        O.Expect('fieldindex_8', '8 Dec active=Yes');
        O.Expect('fieldindex_9', '9 Flag active=Yes');
        O.Expect('field_20_exist', 'No');
        O.Expect('field_20_active', 'active=No name=Disabled');
        O.Ignore('fieldcount'); // a dump or environment data: observed, not asserted
        O.Verify();
    end;

    local procedure TryActive(RR: RecordRef; No: Integer): Text
    var
        Res: Text;
    begin
        if TryActiveF(RR, No, Res) then
            exit(Res);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryActiveF(RR: RecordRef; No: Integer; var Res: Text)
    var
        FR: FieldRef;
    begin
        FR := RR.Field(No);
        Res := 'active=' + Format(FR.Active()) + ' name=' + FR.Name();
    end;

    [Test]
    procedure FieldRef_EnumAndOptionInfo()
    var
        O: Codeunit "Probe Observer";
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
        Nos: List of [Integer];
        No: Integer;
    begin
        RR.Open(Database::"PA Rec Row");
        Nos.Add(1);
        Nos.Add(2);
        Nos.Add(4);
        Nos.Add(5);
        Nos.Add(6);
        Nos.Add(9);
        foreach No in Nos do begin
            FR := RR.Field(No);
            O.Observe('field_' + Format(No) + '_isenum', Format(FR.IsEnum()));
            O.Observe('field_' + Format(No) + '_enumvaluecount', TryEnumCount(FR));
            O.Observe('field_' + Format(No) + '_optioncaption', TryOptionCaption(FR));
            O.Observe('field_' + Format(No) + '_optionmembers', TryOptionMembers(FR));
            O.Observe('field_' + Format(No) + '_type', Format(FR.Type()));
        end;
        FR := RR.Field(6);
        for i := 1 to 3 do
            O.Observe('enum_value_' + Format(i), TryEnumValue(FR, i));
        RR.Close();
        O.Expect('field_1_isenum', 'No');
        O.Expect('field_1_enumvaluecount', '0');
        O.Expect('field_1_optioncaption', '');
        O.Expect('field_1_optionmembers', '');
        O.Expect('field_1_type', 'Integer');
        O.Expect('field_2_isenum', 'No');
        O.Expect('field_2_enumvaluecount', '0');
        O.Expect('field_2_optioncaption', '');
        O.Expect('field_2_optionmembers', '');
        O.Expect('field_2_type', 'Code');
        O.Expect('field_4_isenum', 'No');
        O.Expect('field_4_enumvaluecount', '3');
        O.Expect('field_4_optioncaption', 'First,Second,Third');
        O.Expect('field_4_optionmembers', 'Alpha,Beta,Gamma');
        O.Expect('field_4_type', 'Option');
        O.Expect('field_5_isenum', 'No');
        O.Expect('field_5_enumvaluecount', '2');
        O.Expect('field_5_optioncaption', 'Xx,Yy');
        O.Expect('field_5_optionmembers', 'Xx,Yy');
        O.Expect('field_5_type', 'Option');
        O.Expect('field_6_isenum', 'Yes');
        O.Expect('field_6_enumvaluecount', '4');
        O.Expect('field_6_optioncaption', 'Zero Caption,One,Five Caption,Seven Caption');
        O.Expect('field_6_optionmembers', 'Zero,One,Five,Seven');
        O.Expect('field_6_type', 'Option');
        O.Expect('field_9_isenum', 'No');
        O.Expect('field_9_enumvaluecount', '0');
        O.Expect('field_9_optioncaption', '');
        O.Expect('field_9_optionmembers', '');
        O.Expect('field_9_type', 'Boolean');
        O.Expect('enum_value_1', 'name=Zero caption=Zero Caption ordinal=0');
        O.Expect('enum_value_2', 'name=One caption=One ordinal=1');
        O.Expect('enum_value_3', 'name=Five caption=Five Caption ordinal=5');
        O.Verify();
    end;

    local procedure TryEnumCount(FR: FieldRef): Text
    var
        Res: Text;
    begin
        if TryEnumCountF(FR, Res) then
            exit(Res);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryEnumCountF(FR: FieldRef; var Res: Text)
    begin
        Res := Format(FR.EnumValueCount());
    end;

    local procedure TryOptionCaption(FR: FieldRef): Text
    var
        Res: Text;
    begin
        if TryOptionCaptionF(FR, Res) then
            exit(Res);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOptionCaptionF(FR: FieldRef; var Res: Text)
    begin
        Res := FR.OptionCaption();
    end;

    local procedure TryOptionMembers(FR: FieldRef): Text
    var
        Res: Text;
    begin
        if TryOptionMembersF(FR, Res) then
            exit(Res);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOptionMembersF(FR: FieldRef; var Res: Text)
    begin
        Res := FR.OptionMembers();
    end;

    local procedure TryEnumValue(FR: FieldRef; Idx: Integer): Text
    var
        Res: Text;
    begin
        if TryEnumValueF(FR, Idx, Res) then
            exit(Res);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryEnumValueF(FR: FieldRef; Idx: Integer; var Res: Text)
    begin
        Res := 'name=' + FR.GetEnumValueName(Idx) + ' caption=' + FR.GetEnumValueCaption(Idx) + ' ordinal=' + Format(FR.GetEnumValueOrdinal(Idx));
    end;

    [Test]
    procedure Filters_GetFiltersText()
    var
        O: Codeunit "Probe Observer";
        R: Record "PA Rec Row";
    begin
        R.SetRange(Id, 1, 5);
        R.SetFilter(Cd, 'A|B');
        R.SetFilter(Txt, '<>x');
        O.Observe('getfilters_three', R.GetFilters());
        O.Observe('getfilter_id', R.GetFilter(Id));
        O.Observe('getfilter_cd', R.GetFilter(Cd));
        O.Observe('getfilter_txt', R.GetFilter(Txt));
        O.Observe('getview', R.GetView());
        R.Reset();
        R.SetRange(Id, 3);
        O.Observe('single_value', R.GetFilters());
        R.SetRange(Id, 3, 3);
        O.Observe('range_same_both', R.GetFilter(Id));
        R.SetFilter(Id, '>%1', 3);
        O.Observe('greater_than', R.GetFilter(Id));
        R.SetFilter(Id, '<=%1', 3);
        O.Observe('less_equal', R.GetFilter(Id));
        R.SetFilter(Id, '1..3|5|7..');
        O.Observe('open_range_and_list', R.GetFilter(Id));
        R.SetFilter(Id, '..3');
        O.Observe('open_start_range', R.GetFilter(Id));
        R.SetFilter(Id, '<>3&<>4');
        O.Observe('two_not_equal', R.GetFilter(Id));
        R.SetFilter(Id, '1|2|3');
        O.Observe('or_list', R.GetFilter(Id));
        R.SetRange(Cd, '');
        O.Observe('empty_text_filter', '[' + R.GetFilter(Cd) + ']');
        R.SetFilter(Cd, '''''');
        O.Observe('empty_quoted_filter', '[' + R.GetFilter(Cd) + ']');
        R.SetFilter(Flag, '%1', true);
        O.Observe('boolean_filter', R.GetFilter(Flag));
        R.SetRange(Dt, DMY2Date(5, 3, 2024));
        O.Observe('date_filter', R.GetFilter(Dt));
        R.SetRange(Dec, 1.5);
        O.Observe('decimal_filter', R.GetFilter(Dec));
        R.SetRange(Opt, R.Opt::Beta);
        O.Observe('option_filter', R.GetFilter(Opt));
        R.SetRange(En, R.En::Five);
        O.Observe('enum_filter', R.GetFilter(En));
        O.Observe('getfilters_all', R.GetFilters());
        O.Expect('getfilters_three', 'Identifier: 1..5, Cd: A|B, Txt: <>x');
        O.Expect('getfilter_id', '1..5');
        O.Expect('getfilter_cd', 'A|B');
        O.Expect('getfilter_txt', '<>x');
        O.Expect('getview', 'VERSION(1) SORTING(Identifier) WHERE(Identifier=FILTER(1..5),Cd=FILTER(A|B),Txt=FILTER(<>x))');
        O.Expect('single_value', 'Identifier: 3');
        O.Expect('range_same_both', '3');
        O.Expect('greater_than', '>3');
        O.Expect('less_equal', '<=3');
        O.Expect('open_range_and_list', '1..3|5|7..');
        O.Expect('open_start_range', '..3');
        O.Expect('two_not_equal', '<>3&<>4');
        O.Expect('or_list', '1|2|3');
        O.Expect('empty_text_filter', '['''']');
        O.Expect('empty_quoted_filter', '['''']');
        O.Expect('boolean_filter', 'Yes');
        O.Expect('date_filter', '03/05/24');
        O.Expect('decimal_filter', '1.5');
        O.Expect('option_filter', 'Second');
        O.Expect('enum_filter', 'Five Caption');
        O.Expect('getfilters_all', 'Identifier: 1|2|3, Cd: '''', Opt: Second, En: Five Caption, Dt: 03/05/24, Dec: 1.5, Flag: Yes');
        O.Verify();
    end;

    [Test]
    procedure RecordId_FormatForms()
    var
        O: Codeunit "Probe Observer";
        R: Record "PA Rec Row";
        P: Record "PA Pk2 Row";
        Rid: RecordId;
    begin
        R.Id := 42;
        O.Observe('single_key', Format(R.RecordId));
        P.A := 'AB';
        P.B := 7;
        O.Observe('two_key', Format(P.RecordId));
        P.A := 'A,B';
        P.B := -3;
        O.Observe('comma_in_text_key', Format(P.RecordId));
        P.A := 'A B';
        P.B := 0;
        O.Observe('space_in_text_key', Format(P.RecordId));
        P.A := '';
        O.Observe('empty_text_key', Format(P.RecordId));
        Rid := R.RecordId;
        O.Observe('format_recordid_len_f9', Format(Rid, 0, 9));
        O.Observe('format_recordid_len_f0', Format(Rid, 0, 0));
        O.Observe('format_recordid_len_f1', Format(Rid, 0, 1));
        Clear(Rid);
        O.Observe('format_null_recordid', '[' + Format(Rid) + ']');
        O.Expect('single_key', 'PA Rec Row: 42');
        O.Expect('two_key', 'PA Pk2 Row: AB,7');
        O.Expect('comma_in_text_key', 'PA Pk2 Row: "A,B",-3');
        O.Expect('space_in_text_key', 'PA Pk2 Row: A B,0');
        O.Expect('empty_text_key', 'PA Pk2 Row: "",0');
        O.Expect('format_recordid_len_f9', 'PA Rec Row: 42');
        O.Expect('format_recordid_len_f0', 'PA Rec Row: 42');
        O.Expect('format_recordid_len_f1', 'PA Rec Row: 42');
        O.Expect('format_null_recordid', '[]');
        O.Verify();
    end;

    [Test]
    procedure Permissions_And_Locking()
    var
        O: Codeunit "Probe Observer";
        R: Record "PA Rec Row";
    begin
        O.Observe('recordlevellocking', Format(R.RecordLevelLocking()));
        O.Observe('readpermission', Format(R.ReadPermission()));
        O.Observe('writepermission', Format(R.WritePermission()));
        O.Observe('hasfilter_empty', Format(R.HasFilter()));
        O.Observe('istemporary', Format(R.IsTemporary()));
        O.Expect('recordlevellocking', 'Yes');
        O.Expect('readpermission', 'Yes');
        O.Expect('writepermission', 'Yes');
        O.Expect('hasfilter_empty', 'No');
        O.Expect('istemporary', 'No');
        O.Verify();
    end;

    [Test]
    procedure TempRecord_NotRolledBackByAsserterror()
    var
        O: Codeunit "Probe Observer";
        T: Record "PA Rec Row" temporary;
        P: Record "PA Rec Row";
    begin
        P.DeleteAll();
        T.Id := 1;
        T.Insert();
        P.Id := 1;
        P.Insert();
        asserterror begin
            T.Id := 2;
            T.Insert();
            P.Id := 2;
            P.Insert();
            Error('stop');
        end;
        O.Observe('temp_count_after_asserterror', Format(T.Count()));
        O.Observe('persistent_count_after_asserterror', Format(P.Count()));
        O.Observe('error_text', GetLastErrorText());
        P.DeleteAll();
        O.Expect('temp_count_after_asserterror', '2');
        O.Expect('persistent_count_after_asserterror', '0');
        O.Expect('error_text', 'stop');
        O.Verify();
    end;

    [Test]
    procedure TempRecord_ModifyDeleteNotRolledBack()
    var
        O: Codeunit "Probe Observer";
        T: Record "PA Rec Row" temporary;
    begin
        T.Id := 1;
        T.Txt := 'orig';
        T.Insert();
        asserterror begin
            T.Txt := 'changed';
            T.Modify();
            T.Delete();
            Error('stop');
        end;
        O.Observe('temp_exists_after', Format(T.Get(1)));
        O.Observe('temp_count_after', Format(T.Count()));
        O.Expect('temp_exists_after', 'No');
        O.Expect('temp_count_after', '0');
        O.Verify();
    end;

    [Test]
    procedure WriteTransaction_State()
    var
        O: Codeunit "Probe Observer";
        P: Record "PA Rec Row";
        T: Record "PA Rec Row" temporary;
    begin
        P.DeleteAll();
        Commit();
        O.Observe('start', Format(Database.IsInWriteTransaction()));
        T.Id := 1;
        T.Insert();
        O.Observe('after_temp_insert', Format(Database.IsInWriteTransaction()));
        P.DeleteAll();
        O.Observe('after_deleteall_nothing', Format(Database.IsInWriteTransaction()));
        P.Id := 1;
        P.Insert();
        O.Observe('after_insert', Format(Database.IsInWriteTransaction()));
        Commit();
        O.Observe('after_commit', Format(Database.IsInWriteTransaction()));
        P.Delete();
        O.Observe('after_delete', Format(Database.IsInWriteTransaction()));
        Commit();
        P.Reset();
        if P.FindFirst() then;
        O.Observe('after_read', Format(Database.IsInWriteTransaction()));
        P.ModifyAll(Txt, 'x');
        O.Observe('after_modifyall_nothing', Format(Database.IsInWriteTransaction()));
        O.Expect('start', 'No');
        O.Expect('after_temp_insert', 'No');
        O.Expect('after_deleteall_nothing', 'Yes');
        O.Expect('after_insert', 'Yes');
        O.Expect('after_commit', 'No');
        O.Expect('after_delete', 'Yes');
        O.Expect('after_read', 'No');
        O.Expect('after_modifyall_nothing', 'Yes');
        O.Verify();
    end;

    [Test]
    procedure LastUsedRowVersion_StartsAndGrows()
    var
        O: Codeunit "Probe Observer";
        P: Record "PA Rec Row";
        V1: BigInteger;
        V2: BigInteger;
    begin
        V1 := Database.LastUsedRowVersion();
        O.Observe('positive', Format(V1 > 0));
        P.Id := 9001;
        P.Insert();
        V2 := Database.LastUsedRowVersion();
        O.Observe('grows_after_insert', Format(V2 > V1));
        O.Observe('row_version_is_last', Format(P.SystemModifiedAt <> 0DT));
        P.Delete();
        O.Expect('positive', 'Yes');
        O.Expect('grows_after_insert', 'No');
        O.Expect('row_version_is_last', 'Yes');
        O.Verify();
    end;

    [Test]
    procedure LockTimeout_DefaultAndSet()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('default', Format(LockTimeout()));
        LockTimeout(false);
        O.Observe('after_set_false', Format(LockTimeout()));
        LockTimeout(true);
        O.Observe('after_set_true', Format(LockTimeout()));
        O.Expect('default', 'Yes');
        O.Expect('after_set_false', 'No');
        O.Expect('after_set_true', 'Yes');
        O.Verify();
    end;
}
