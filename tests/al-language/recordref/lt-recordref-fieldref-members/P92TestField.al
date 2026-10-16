// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-testfield-method
// Scope: in-scope
// Fixtures used: tables 72200, codeunit 72209 (P92Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: FieldRef.TestField (no value, value of each type) compared with Record.TestField on the same row: text and code
// BC versions: 29 (27 and 28 by CI)

codeunit 72222 "LT P92 TestField"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRefNoValue(var RecRef: RecordRef; No: Integer)
    var
        Fld: FieldRef;
    begin
        Fld := RecRef.Field(No);
        Fld.TestField();
    end;

    [TryFunction]
    local procedure TryRefValue(var RecRef: RecordRef; No: Integer; V: Variant)
    var
        Fld: FieldRef;
    begin
        Fld := RecRef.Field(No);
        Fld.TestField(V);
    end;

    local procedure RefNoValue(var RecRef: RecordRef; No: Integer): Text
    begin
        if TryRefNoValue(RecRef, No) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure RefValue(var RecRef: RecordRef; No: Integer; V: Variant): Text
    begin
        if TryRefValue(RecRef, No, V) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRecNoValue(var Item: Record "LT P92 Item"; No: Integer)
    begin
        case No of
            1:
                Item.TestField(Code);
            2:
                Item.TestField(Name);
            3:
                Item.TestField(Qty);
            4:
                Item.TestField(Amt);
            5:
                Item.TestField(Flag);
            6:
                Item.TestField(Dt);
            7:
                Item.TestField(Kind);
            8:
                Item.TestField(Note);
            10:
                Item.TestField(Cd);
        end;
    end;

    local procedure RecNoValue(var Item: Record "LT P92 Item"; No: Integer): Text
    begin
        if TryRecNoValue(Item, No) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure NoValue_BlankRow_RefVersusRecord()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
        i: Integer;
        R1: Text;
        R2: Text;
    begin
        Helper.SeedItems();
        Item.Get('B1');
        RecRef.GetTable(Item);
        for i := 1 to 10 do
            if i <> 9 then begin
                R1 := RefNoValue(RecRef, i);
                R2 := RecNoValue(Item, i);
                Observer.Observe('ref_' + Format(i), R1);
                Observer.Observe('same_' + Format(i), Format(R1 = R2));
            end;
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure NoValue_FilledRow_Passes()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
    begin
        Helper.SeedItems();
        Item.Get('A2');
        Item.Flag := true;
        Item.Dt := DMY2Date(2, 3, 2020);
        Item.Kind := Item.Kind::Gamma;
        Item.Note := 'x';
        Item.Cd := 'c';
        RecRef.GetTable(Item);
        Observer.Observe('ref_code', RefNoValue(RecRef, 1));
        Observer.Observe('ref_name', RefNoValue(RecRef, 2));
        Observer.Observe('ref_qty', RefNoValue(RecRef, 3));
        Observer.Observe('ref_amt', RefNoValue(RecRef, 4));
        Observer.Observe('ref_flag', RefNoValue(RecRef, 5));
        Observer.Observe('ref_dt', RefNoValue(RecRef, 6));
        Observer.Observe('ref_kind', RefNoValue(RecRef, 7));
        Observer.Observe('ref_note', RefNoValue(RecRef, 8));
        Observer.Observe('ref_cd', RefNoValue(RecRef, 10));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure NoValue_OptionFirstMemberIsEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
    begin
        Helper.SeedItems();
        Item.Get('A1');
        Item.Kind := Item.Kind::Alpha;
        RecRef.GetTable(Item);
        Observer.Observe('alpha_ref', RefNoValue(RecRef, 7));
        Observer.Observe('alpha_rec', RecNoValue(Item, 7));
        Item.Kind := Item.Kind::Beta;
        RecRef.GetTable(Item);
        Observer.Observe('beta_ref', RefNoValue(RecRef, 7));
        Observer.Observe('beta_rec', RecNoValue(Item, 7));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Value_Matching_And_Mismatch_Typed()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
    begin
        Helper.SeedItems();
        Item.Get('A1');
        RecRef.GetTable(Item);
        Observer.Observe('text_equal', RefValue(RecRef, 2, 'Alpha'));
        Observer.Observe('text_case', RefValue(RecRef, 2, 'ALPHA'));
        Observer.Observe('text_diff', RefValue(RecRef, 2, 'Other'));
        Observer.Observe('text_empty', RefValue(RecRef, 2, ''));
        Observer.Observe('code_equal', RefValue(RecRef, 1, 'A1'));
        Observer.Observe('code_case', RefValue(RecRef, 1, 'a1'));
        Observer.Observe('code_diff', RefValue(RecRef, 1, 'A9'));
        Observer.Observe('int_equal', RefValue(RecRef, 3, 10));
        Observer.Observe('int_diff', RefValue(RecRef, 3, 11));
        Observer.Observe('int_zero', RefValue(RecRef, 3, 0));
        Observer.Observe('int_negative', RefValue(RecRef, 3, -10));
        Observer.Observe('dec_equal', RefValue(RecRef, 4, 1.5));
        Observer.Observe('dec_diff', RefValue(RecRef, 4, 1.25));
        Observer.Observe('bool_false_equal', RefValue(RecRef, 5, false));
        Observer.Observe('bool_true_diff', RefValue(RecRef, 5, true));
        Observer.Observe('date_equal_zero', RefValue(RecRef, 6, 0D));
        Observer.Observe('date_diff', RefValue(RecRef, 6, DMY2Date(1, 1, 2021)));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Value_TypeMismatchBetweenVariantAndField()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
    begin
        Helper.SeedItems();
        Item.Get('A1');
        RecRef.GetTable(Item);
        Observer.Observe('text_value_on_int', RefValue(RecRef, 3, '10'));
        Observer.Observe('int_value_on_text', RefValue(RecRef, 2, 10));
        Observer.Observe('decimal_value_on_int', RefValue(RecRef, 3, 10.0));
        Observer.Observe('int_value_on_decimal', RefValue(RecRef, 4, 2));
        Observer.Observe('bool_value_on_int', RefValue(RecRef, 3, true));
        Observer.Observe('date_value_on_text', RefValue(RecRef, 2, 0D));
        Observer.Observe('option_by_int', RefValue(RecRef, 7, 0));
        Observer.Observe('option_by_text', RefValue(RecRef, 7, 'Alpha'));
        Observer.Observe('option_by_int_diff', RefValue(RecRef, 7, 1));
        Observer.Observe('option_by_text_diff', RefValue(RecRef, 7, 'Beta'));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Value_RecordSide_Texts()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
        R1: Text;
    begin
        Helper.SeedItems();
        Item.Get('A1');
        RecRef.GetTable(Item);
        R1 := RefValue(RecRef, 2, 'Other');
        asserterror Item.TestField(Name, 'Other');
        Observer.ObserveError('rec_text_diff');
        Observer.Observe('ref_text_diff', R1);
        R1 := RefValue(RecRef, 3, 11);
        asserterror Item.TestField(Qty, 11);
        Observer.ObserveError('rec_int_diff');
        Observer.Observe('ref_int_diff', R1);
        R1 := RefValue(RecRef, 4, 9);
        asserterror Item.TestField(Amt, 9);
        Observer.ObserveError('rec_dec_diff');
        Observer.Observe('ref_dec_diff', R1);
        R1 := RefValue(RecRef, 7, 'Beta');
        asserterror Item.TestField(Kind, Item.Kind::Beta);
        Observer.ObserveError('rec_opt_diff');
        Observer.Observe('ref_opt_diff', R1);
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TestField_AfterFieldValueChangeOnRecRef()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.Field(1).SetRange('B1');
        RecRef.FindFirst();
        Observer.Observe('blank_name', RefNoValue(RecRef, 2));
        RecRef.Field(2).Value := 'filled';
        Observer.Observe('filled_name', RefNoValue(RecRef, 2));
        RecRef.Field(2).Value := '';
        Observer.Observe('blank_again', RefNoValue(RecRef, 2));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TestField_NoCurrentRecord()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(72200);
        Observer.Observe('fresh_name', RefNoValue(RecRef, 2));
        Observer.Observe('fresh_value', RefValue(RecRef, 2, ''));
        Observer.Observe('fresh_code', RefNoValue(RecRef, 1));
        RecRef.Close();
        Observer.Finish();
    end;
}
