// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-fielderror-method
// Scope: in-scope
// Fixtures used: tables 72200, codeunit 72209 (P92Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: FieldRef.FieldError with and without text compared with Record.FieldError: text and code
// BC versions: 29 (27 and 28 by CI)

codeunit 72223 "LT P92 FieldError"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRef(var RecRef: RecordRef; No: Integer; Msg: Text; WithMsg: Boolean)
    var
        Fld: FieldRef;
    begin
        Fld := RecRef.Field(No);
        if WithMsg then
            Fld.FieldError(Msg)
        else
            Fld.FieldError();
    end;

    [TryFunction]
    local procedure TryRec(var Item: Record "LT P92 Item"; No: Integer; Msg: Text; WithMsg: Boolean)
    begin
        case No of
            1:
                if WithMsg then
                    Item.FieldError(Code, Msg)
                else
                    Item.FieldError(Code);
            2:
                if WithMsg then
                    Item.FieldError(Name, Msg)
                else
                    Item.FieldError(Name);
            3:
                if WithMsg then
                    Item.FieldError(Qty, Msg)
                else
                    Item.FieldError(Qty);
            4:
                if WithMsg then
                    Item.FieldError(Amt, Msg)
                else
                    Item.FieldError(Amt);
            5:
                if WithMsg then
                    Item.FieldError(Flag, Msg)
                else
                    Item.FieldError(Flag);
            6:
                if WithMsg then
                    Item.FieldError(Dt, Msg)
                else
                    Item.FieldError(Dt);
            7:
                if WithMsg then
                    Item.FieldError(Kind, Msg)
                else
                    Item.FieldError(Kind);
        end;
    end;

    local procedure Ref(var RecRef: RecordRef; No: Integer; Msg: Text; WithMsg: Boolean): Text
    begin
        if TryRef(RecRef, No, Msg, WithMsg) then
            exit('no error');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure RecT(var Item: Record "LT P92 Item"; No: Integer; Msg: Text; WithMsg: Boolean): Text
    begin
        if TryRec(Item, No, Msg, WithMsg) then
            exit('no error');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure FieldError_NoText_PerType()
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
        Item.Get('A1');
        Item.Flag := true;
        Item.Dt := DMY2Date(2, 3, 2020);
        Item.Kind := Item.Kind::Beta;
        RecRef.GetTable(Item);
        for i := 1 to 7 do begin
            R1 := Ref(RecRef, i, '', false);
            R2 := RecT(Item, i, '', false);
            Observer.Observe('ref_' + Format(i), R1);
            Observer.Observe('same_' + Format(i), Format(R1 = R2));
        end;
        Observer.Observe('rec_2', RecT(Item, 2, '', false));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FieldError_WithText_PerType()
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
        Item.Get('A1');
        RecRef.GetTable(Item);
        for i := 1 to 7 do begin
            R1 := Ref(RecRef, i, 'custom text', true);
            R2 := RecT(Item, i, 'custom text', true);
            Observer.Observe('ref_' + Format(i), R1);
            Observer.Observe('same_' + Format(i), Format(R1 = R2));
        end;
        Observer.Observe('rec_2', RecT(Item, 2, 'custom text', true));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FieldError_TextEdgeCases()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
    begin
        Helper.SeedItems();
        Item.Get('A1');
        RecRef.GetTable(Item);
        Observer.Observe('ref_empty_text', Ref(RecRef, 2, '', true));
        Observer.Observe('rec_empty_text', RecT(Item, 2, '', true));
        Observer.Observe('ref_space_text', Ref(RecRef, 2, ' ', true));
        Observer.Observe('ref_percent', Ref(RecRef, 2, '100% %1 done', true));
        Observer.Observe('rec_percent', RecT(Item, 2, '100% %1 done', true));
        Observer.Observe('ref_period_end', Ref(RecRef, 2, 'ends with period.', true));
        Observer.Observe('ref_newline', Ref(RecRef, 2, 'line1' + '\' + 'line2', true));
        Observer.Observe('ref_unicode', Ref(RecRef, 2, 'Gr' + Format(CopyStr('ü', 1, 1)) + 'n', true));
        Observer.Observe('ref_long', Ref(RecRef, 2, PadStr('', 300, 'L'), true));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FieldError_OnTemporaryAndPartialRow()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(72200, true);
        RecRef.Field(1).Value := 'TMP';
        RecRef.Insert();
        Observer.Observe('temp_ref', Ref(RecRef, 2, '', false));
        Observer.Observe('temp_ref_text', Ref(RecRef, 2, 'tmp text', true));
        RecRef.Close();
        RecRef.Open(72200);
        Observer.Observe('empty_current_ref', Ref(RecRef, 2, '', false));
        Observer.Observe('empty_current_ref_text', Ref(RecRef, 2, 'x', true));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FieldError_KeyAppearsInText()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
    begin
        Helper.SeedPairs();
        RecRef.Open(72201);
        RecRef.Field(4).SetRange(30);
        RecRef.FindFirst();
        Observer.Observe('composite_key', RefPair(RecRef, 3));
        RecRef.Field(4).SetRange(40);
        RecRef.FindFirst();
        Observer.Observe('paren_key', RefPair(RecRef, 3));
        RecRef.Close();
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryPair(var RecRef: RecordRef; No: Integer)
    var
        Fld: FieldRef;
    begin
        Fld := RecRef.Field(No);
        Fld.FieldError('bad');
    end;

    local procedure RefPair(var RecRef: RecordRef; No: Integer): Text
    begin
        if TryPair(RecRef, No) then
            exit('no error');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure FieldError_AsserterrorForm()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Item: Record "LT P92 Item";
    begin
        Helper.SeedItems();
        Item.Get('A1');
        RecRef.GetTable(Item);
        Fld := RecRef.Field(2);
        asserterror Fld.FieldError();
        Observer.ObserveError('ref_none');
        asserterror Fld.FieldError('with text');
        Observer.ObserveError('ref_text');
        asserterror Item.FieldError(Name);
        Observer.ObserveError('rec_none');
        asserterror Item.FieldError(Name, 'with text');
        Observer.ObserveError('rec_text');
        RecRef.Close();
        Observer.Finish();
    end;
}
