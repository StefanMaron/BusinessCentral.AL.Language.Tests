// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-charallowed-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), objects in XTableObjects.al
// Probe (issue 611): what a table field or a table extension modify() does at run time for CharAllowed, DateFormula, MaskType, OptionCaptionML,
// SignDisplacement, SQLDataType, SQLTimestamp, Width, BlankZero, CaptionClass, ClosingDates, OptionCaption, and what the table properties
// LinkedObject, ColumnStoreIndex, DataCaptionFields, DrillDownPageId and LookupPageId report and open. The compile results of the invalid
// values are pinned by the must-not-compile cases 0760-0775. Object id 75010.

codeunit 75010 "LT X Table Props Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        OpenedPage: Text;

    local procedure Seed()
    var
        Row: Record "LT X Props";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Insert();
    end;

    local procedure Check(var Observer: Codeunit "Probe Observer"; Name: Text; var Row: Record "LT X Props"; FieldNumber: Integer; Value: Text)
    begin
        ClearLastError();
        if TryValidate(Row, FieldNumber, Value) then
            Observer.Observe(Name, 'no error: ' + Value)
        else
            Observer.ObserveError(Name);
    end;

    [TryFunction]
    local procedure TryValidate(var Row: Record "LT X Props"; FieldNumber: Integer; Value: Text)
    begin
        case FieldNumber of
            Row.FieldNo(Digits):
                Row.Validate(Digits, CopyStr(Value, 1, 20));
            Row.FieldNo(Picky):
                Row.Validate(Picky, CopyStr(Value, 1, 20));
            Row.FieldNo(DateText):
                Row.Validate(DateText, CopyStr(Value, 1, 30));
        end;
    end;

    local procedure LinkedStep(var Observer: Codeunit "Probe Observer"; Name: Text; var Row: Record "LT X Props Linked"; Step: Integer)
    var
        Helper: Codeunit "LT X Linked Step";
    begin
        ClearLastError();
        Helper.SetStep(Step);
        if Helper.Run(Row) then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure CharAllowed_Validate_AllowedAndDisallowed()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
    begin
        Row.Init();
        Row.Id := 1;
        Row.Validate(Digits, '123');
        Observer.Observe('digits_allowed', Row.Digits);
        Check(Observer, 'digits_disallowed', Row, Row.FieldNo(Digits), '12A');
        Row.Digits := '12A';
        Observer.Observe('digits_assigned_not_checked', Row.Digits);
        Row.Validate(Picky, 'abmpz');
        Observer.Observe('picky_allowed', Row.Picky);
        Check(Observer, 'picky_e_between_ranges', Row, Row.FieldNo(Picky), 'abe');
        Check(Observer, 'picky_uppercase', Row, Row.FieldNo(Picky), 'A');
        Check(Observer, 'picky_q', Row, Row.FieldNo(Picky), 'abq');
        Observer.Finish();
    end;

    [Test]
    procedure CharAllowed_TestPage_AllowedAndDisallowed()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT X Props Card";
    begin
        Card.OpenNew();
        Card.Id.SetValue(1);
        Card.Digits.SetValue('456');
        Observer.Observe('page_digits_allowed', Card.Digits.Value);
        asserterror Card.Digits.SetValue('4x6');
        Observer.ObserveError('page_digits_disallowed');
        Observer.Observe('page_digits_after_error', Card.Digits.Value);
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure DateFormula_TextField_AcceptsFormulaText()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Get(1);
        Row.Validate(DateText, '1M');
        Observer.Observe('validate_1M', Row.DateText);
        Row.Validate(DateText, '<CM+1D>');
        Observer.Observe('validate_CM_1D', Row.DateText);
        Check(Observer, 'validate_garbage', Row, Row.FieldNo(DateText), 'not a formula');
        Row.DateText := 'not a formula';
        Row.Modify();
        Observer.Observe('assigned_garbage', Row.DateText);
        Card.OpenEdit();
        Card.DateText.SetValue('2W');
        Observer.Observe('page_2W', Card.DateText.Value);
        Card.DateText.SetValue('xyz');
        Observer.Observe('page_garbage_value', Card.DateText.Value);
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure MaskType_ConcealedAndNone_ValueUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Get(1);
        Row.Secret := 'pw-1';
        Row.Plain := 'open-1';
        Row.Secret2 := 'pw-2';
        Row.Modify();
        Card.OpenEdit();
        Observer.Observe('page_concealed', Card.Secret.Value);
        Observer.Observe('page_none', Card.Plain.Value);
        Card.Secret.SetValue('pw-3');
        Observer.Observe('page_after_set', Card.Secret.Value);
        Card.Close();
        Row.Get(1);
        Observer.Observe('record_secret', Row.Secret);
        Observer.Observe('record_plain', Row.Plain);
        Observer.Observe('record_secret2', Row.Secret2);
        Observer.Finish();
    end;

    [Test]
    procedure OptionCaptionML_Field_CaptionPerLanguage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Ref: FieldRef;
        RecRef: RecordRef;
        Card: TestPage "LT X Props Card";
        OldLanguage: Integer;
    begin
        Seed();
        Row.Get(1);
        Row.Op := Row.Op::B;
        Row.OptMl := Row.OptMl::C;
        Row.Modify();
        OldLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        Observer.Observe('enu_format', Format(Row.Op));
        Observer.Observe('enu_format_modified_field', Format(Row.OptMl));
        RecRef.GetTable(Row);
        Ref := RecRef.Field(Row.FieldNo(Op));
        Observer.Observe('enu_optioncaption', Ref.OptionCaption);
        Observer.Observe('enu_optionmembers', Ref.OptionMembers);
        Ref := RecRef.Field(Row.FieldNo(OptMl));
        Observer.Observe('enu_optioncaption_modified', Ref.OptionCaption);
        GlobalLanguage(1031);
        Observer.Observe('deu_format', Format(Row.Op));
        Observer.Observe('deu_format_modified_field', Format(Row.OptMl));
        Ref := RecRef.Field(Row.FieldNo(Op));
        Observer.Observe('deu_optioncaption', Ref.OptionCaption);
        Ref := RecRef.Field(Row.FieldNo(OptMl));
        Observer.Observe('deu_optioncaption_modified', Ref.OptionCaption);
        GlobalLanguage(1036);
        Observer.Observe('fra_format_fallback', Format(Row.Op));
        Observer.Observe('fra_format_modified_fallback', Format(Row.OptMl));
        Ref := RecRef.Field(Row.FieldNo(Op));
        Observer.Observe('fra_optioncaption_fallback', Ref.OptionCaption);
        Ref := RecRef.Field(Row.FieldNo(OptMl));
        Observer.Observe('fra_optioncaption_modified_fallback', Ref.OptionCaption);
        GlobalLanguage(1031);
        Card.OpenEdit();
        Observer.Observe('deu_page_op', Card.Op.Value);
        Observer.Observe('deu_page_optml_modified', Card.OptMl.Value);
        Card.Close();
        GlobalLanguage(OldLanguage);
        Observer.Finish();
    end;

    [Test]
    procedure SignDisplacement_Format_NegativeAndPositive()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Get(1);
        Row.Disp := -1234.5;
        Row.Modify();
        Observer.Observe('format_negative', Format(Row.Disp));
        Row.Disp := 1234.5;
        Row.Modify();
        Observer.Observe('format_positive', Format(Row.Disp));
        Row.Disp := 0;
        Row.Modify();
        Observer.Observe('format_zero', Format(Row.Disp));
        Row.Disp := -1234.5;
        Row.Modify();
        Card.OpenEdit();
        Observer.Observe('page_negative', Card.Disp.Value);
        Card.Close();
        Observer.Finish();
    end;

    local procedure SeedSql(var Row: Record "LT X Props Sql")
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.AsInteger := '10';
        Row.AsVarchar := '10';
        Row.AsBigInteger := '10';
        Row.AsDefault := '10';
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.AsInteger := '9';
        Row.AsVarchar := '9';
        Row.AsBigInteger := '9';
        Row.AsDefault := '9';
        Row.Insert();
        Row.Init();
        Row.Id := 3;
        Row.AsVarchar := 'ABC';
        Row.AsDefault := 'ABC';
        Row.Insert();
    end;

    // A database error ends the transaction ("An error occurred and the transaction is stopped"), so each step that may fail is its own test.
    [Test]
    procedure SQLDataType_Code_ReadRowsAndKeys()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props Sql";
    begin
        SeedSql(Row);
        Row.Get(1);
        Observer.Observe('integer_value', Row.AsInteger);
        Observer.Observe('varchar_value', Row.AsVarchar);
        Observer.Observe('bigint_value', Row.AsBigInteger);
        Row.Get(3);
        Observer.Observe('integer_empty_on_row_3', Row.AsInteger);
        Observer.Observe('varchar_text_on_row_3', Row.AsVarchar);
        Row.SetCurrentKey(AsInteger);
        Row.FindFirst();
        Observer.Observe('first_by_integer_key', Format(Row.Id));
        Row.FindLast();
        Observer.Observe('last_by_integer_key', Format(Row.Id));
        Row.SetCurrentKey(AsVarchar);
        Row.FindFirst();
        Observer.Observe('first_by_varchar_key', Format(Row.Id));
        Row.FindLast();
        Observer.Observe('last_by_varchar_key', Format(Row.Id));
        Observer.Finish();
    end;

    [Test]
    procedure SQLDataType_Code_GetRow2()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props Sql";
    begin
        SeedSql(Row);
        asserterror Row.Get(2);
        Observer.ObserveError('get_2_value_9');
        Observer.Finish();
    end;

    [Test]
    procedure SQLDataType_Code_ModifyToZero()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props Sql";
    begin
        SeedSql(Row);
        Row.Get(1);
        Row.AsInteger := '0';
        Row.Modify();
        Row.Get(1);
        Observer.Observe('integer_zero_stored', Row.AsInteger);
        Observer.Finish();
    end;

    [Test]
    procedure SQLDataType_Code_ModifyToLeadingZero()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props Sql";
    begin
        SeedSql(Row);
        Row.Get(1);
        Row.AsInteger := '007';
        Row.Modify();
        Row.Get(1);
        Observer.Observe('integer_leading_zero_stored', Row.AsInteger);
        Observer.Finish();
    end;

    [Test]
    procedure SQLDataType_Code_ModifyToText()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props Sql";
    begin
        SeedSql(Row);
        Row.Get(1);
        Row.AsInteger := 'ABC';
        asserterror Row.Modify();
        Observer.ObserveError('modify_text');
        Observer.Finish();
    end;

    [Test]
    procedure SQLTimestamp_BigIntegerField_ReadsRowVersion()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        First: BigInteger;
        Second: BigInteger;
    begin
        Seed();
        Row.Get(1);
        First := Row.Stamp;
        Observer.Observe('stamp_positive_after_insert', Format(First > 0));
        Row.DateText := '1D';
        Row.Modify();
        Row.Get(1);
        Second := Row.Stamp;
        Observer.Observe('stamp_grows_after_modify', Format(Second > First));
        Row.Get(1);
        Observer.Observe('stamp_stable_without_modify', Format(Row.Stamp = Second));
        Row.Stamp := 5;
        Row.Modify();
        Row.Get(1);
        Observer.Observe('stamp_assignment_ignored', Format(Row.Stamp <> 5));
        Observer.Finish();
    end;

    [Test]
    procedure Width_TextField_ValueNotTruncated()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Get(1);
        Row.Wide := 'abcdefghijklmnopqrstuvwxyz';
        Row.Wide2 := 'abcdefghijklmnopqrstuvwxyz';
        Row.Modify();
        Row.Get(1);
        Observer.Observe('wide_value', Row.Wide);
        Observer.Observe('wide2_value_modified_to_5', Row.Wide2);
        Card.OpenEdit();
        Observer.Observe('page_wide', Card.Wide.Value);
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TableExt_ModifyBlankZero_FormatAndPage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Get(1);
        Observer.Observe('format_zero_blankzero_true_modified_false', Format(Row.Bz));
        Observer.Observe('format_zero_blankzero_false_modified_true', Format(Row.Bz2));
        Card.OpenEdit();
        Observer.Observe('page_zero_modified_false', Card.Bz.Value);
        Observer.Observe('page_zero_modified_true', Card.Bz2.Value);
        Card.Close();
        Row.Bz := 5;
        Row.Bz2 := 5;
        Row.Modify();
        Observer.Observe('format_five_modified_false', Format(Row.Bz));
        Observer.Observe('format_five_modified_true', Format(Row.Bz2));
        Observer.Finish();
    end;

    [Test]
    procedure TableExt_ModifyCaptionClass_ResolvedCaption()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "LT X Caption Subscriber";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Subscriber.Take();
        Card.OpenEdit();
        Observer.Observe('resolver_calls_at_open', Subscriber.Take());
        Observer.Observe('caption_base_modified', Card.CapCls.Caption());
        Observer.Observe('caption_second_modified', Card.CapCls2.Caption());
        Observer.Observe('caption_plain_field', Card.Id.Caption());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TableExt_ModifyClosingDates_FormatAndValidate()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
        D: Date;
    begin
        Seed();
        Row.Get(1);
        D := ClosingDate(DMY2Date(31, 12, 2025));
        Row.Closing := D;
        Row.Closing2 := D;
        Observer.Observe('format_closing_modified_off', Format(Row.Closing));
        Observer.Observe('format_closing_modified_on', Format(Row.Closing2));
        Observer.Observe('is_closing_date', Format(D = ClosingDate(DMY2Date(31, 12, 2025))));
        Row.Modify();
        Row.Get(1);
        Observer.Observe('stored_modified_off', Format(Row.Closing));
        Observer.Observe('stored_modified_on', Format(Row.Closing2));
        Card.OpenEdit();
        Observer.Observe('page_modified_off', Card.Closing.Value);
        Observer.Observe('page_modified_on', Card.Closing2.Value);
        Card.Closing2.SetValue(DMY2Date(1, 2, 2026));
        Observer.Observe('page_set_normal_date', Card.Closing2.Value);
        Card.Closing2.SetValue(D);
        Observer.Observe('page_set_closing_date_modified_on', Card.Closing2.Value);
        Card.Closing.SetValue(D);
        Observer.Observe('page_set_closing_date_modified_off', Card.Closing.Value);
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TableExt_ModifyOptionCaption_FormatAndPage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        RecRef: RecordRef;
        Ref: FieldRef;
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Get(1);
        Row.OptCap := Row.OptCap::B;
        Row.Modify();
        Observer.Observe('format_modified', Format(Row.OptCap));
        RecRef.GetTable(Row);
        Ref := RecRef.Field(Row.FieldNo(OptCap));
        Observer.Observe('fieldref_optioncaption', Ref.OptionCaption);
        Observer.Observe('fieldref_optionmembers', Ref.OptionMembers);
        Card.OpenEdit();
        Observer.Observe('page_value', Card.OptCap.Value);
        Card.OptCap.SetValue('Tres');
        Observer.Observe('page_after_set_caption', Card.OptCap.Value);
        Card.Close();
        Row.Get(1);
        Observer.Observe('record_after_page', Format(Row.OptCap, 0, 2));
                Seed();
        Card.OpenEdit();
        asserterror Card.OptCap.SetValue('Two');
        Observer.ObserveError('page_set_replaced_base_caption');
        Card.Close();
Observer.Finish();
    end;

    [Test]
    procedure TableProperties_Metadata_LookupDrillDownDataCaption()
    var
        Observer: Codeunit "Probe Observer";
        Meta: Record "Table Metadata";
    begin
        Meta.Get(Database::"LT X Props");
        Observer.Observe('props_lookup_page_is_target', Format(Meta.LookupPageID = Page::"LT X Lookup Target"));
        Observer.Observe('props_drilldown_page_is_target', Format(Meta.DrillDownPageId = Page::"LT X Drill Target"));
        Observer.Observe('props_data_caption_fields', Meta.DataCaptionFields);
        Observer.Observe('props_linked_object', Format(Meta.LinkedObject));
        Meta.Get(Database::"LT X Props Linked");
        Observer.Observe('linked_linked_object', Format(Meta.LinkedObject));
        Observer.Observe('linked_lookup_page', Format(Meta.LookupPageID));
        Meta.Get(Database::"LT X Props Column Store");
        Observer.Observe('columnstore_linked_object', Format(Meta.LinkedObject));
        Observer.Finish();
    end;

    [Test]
    procedure TableExt_DataCaptionFields_TestPageCaption()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Get(1);
        Row.DateText := '1M';
        Row.Modify();
        Card.OpenEdit();
        Observer.Observe('page_caption', Card.Caption());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LookupTargetHandler')]
    procedure TableExt_LookupPageId_FieldLookupOpensIt()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Init();
        Row.Id := 2;
        Row.Insert();
        OpenedPage := '';
        Card.OpenEdit();
        Card.Rel.Lookup();
        Observer.Observe('opened_page', OpenedPage);
        Observer.Observe('related_value_after_lookup', Card.Rel.Value);
        Card.Close();
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure LookupTargetHandler(var Target: TestPage "LT X Lookup Target")
    begin
        OpenedPage := 'LT X Lookup Target';
        Target.GoToKey(2);
        Target.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('DrillTargetHandler')]
    procedure TableExt_DrillDownPageId_FlowFieldDrillDownOpensIt()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        OpenedPage := '';
        Card.OpenEdit();
        Card.Cnt.DrillDown();
        Observer.Observe('opened_page', OpenedPage);
        Card.Close();
        Observer.Finish();
    end;

    [PageHandler]
    procedure DrillTargetHandler(var Target: TestPage "LT X Drill Target")
    begin
        OpenedPage := 'LT X Drill Target';
        Target.Close();
    end;

    [Test]
    procedure AllowInCustomizations_Table_FieldsStillUsable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
    begin
        Seed();
        Row.Get(1);
        Row.DateText := 'x';
        Row.Modify();
        Row.Get(1);
        Observer.Observe('base_never_field_id', Format(Row.Id));
        Observer.Observe('modified_field', Row.DateText);
        Observer.Finish();
    end;

    [Test]
    procedure ColumnStoreIndex_Table_ReadsUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props Column Store";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Amount := 10.5;
        Row.Note := 'a';
        Row.Insert();
        Row.Id := 2;
        Row.Amount := 20;
        Row.Insert();
        Row.CalcSums(Amount);
        Observer.Observe('sum', Format(Row.Amount));
        Observer.Observe('count', Format(Row.Count()));
        Row.Get(2);
        Observer.Observe('row2_amount', Format(Row.Amount));
        Row.Amount := 21;
        Row.Modify();
        Row.Get(2);
        Observer.Observe('row2_amount_after_modify', Format(Row.Amount));
        Row.Delete();
        Observer.Observe('count_after_delete', Format(Row.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure LinkedObject_Table_InsertAndReadBehavior()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props Linked";
    begin
        Row.Id := 1;
        Row.Note := 'a';
        LinkedStep(Observer, 'insert_1', Row, 1);
        LinkedStep(Observer, 'count', Row, 2);
        Row.Id := 2;
        LinkedStep(Observer, 'insert_2', Row, 1);
        Observer.Finish();
    end;

    [Test]
    procedure ReportColumn_OptionCaptionML_CaptionPerLanguage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
        OldLanguage: Integer;
        Language: Integer;
        Name: Text;
    begin
        Seed();
        Row.Get(1);
        Row.Op := Row.Op::B;
        Row.Modify();
        OldLanguage := GlobalLanguage();
        foreach Language in LanguageList() do begin
            GlobalLanguage(Language);
            Clear(TempBlob);
            TempBlob.CreateOutStream(OutStr);
            Report.SaveAs(Report::"LT X Option Report", '', ReportFormat::Xml, OutStr);
            TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
            Result := '';
            while not InStr.EOS() do begin
                InStr.ReadText(Line);
                if Line.Trim().StartsWith('<Column ') then
                    Result += '[' + Line.Trim() + ']';
            end;
            case Language of
                1033:
                    Name := 'enu';
                1031:
                    Name := 'deu';
                else
                    Name := 'fra';
            end;
            Observer.Observe(Name + '_columns', Result);
        end;
        GlobalLanguage(OldLanguage);
        Observer.Finish();
    end;

    local procedure LanguageList() Languages: List of [Integer]
    begin
        Languages.Add(1033);
        Languages.Add(1031);
        Languages.Add(1036);
    end;
}
