// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-field-method
// Scope: in-scope
// Fixtures used: tables 72200-72201, codeunit 72209 (P92Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: RecordRef.Field and FieldExist by number, missing numbers, FieldIndex, system fields, FieldRef copies refer to the same field
// BC versions: 29 (27 and 28 by CI)

codeunit 72211 "LT P92 Fields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryField(var RecRef: RecordRef; No: Integer; var NameOut: Text)
    var
        Fld: FieldRef;
    begin
        Fld := RecRef.Field(No);
        NameOut := Fld.Name();
    end;

    local procedure FieldName(var RecRef: RecordRef; No: Integer): Text
    var
        N: Text;
    begin
        if TryField(RecRef, No, N) then
            exit(N);
        exit('error|' + GetLastErrorCode());
    end;

    [Test]
    procedure FieldExist_ByNumber()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.Open(72200);
        for i := 0 to 12 do
            Observer.Observe('exist_' + Format(i), Format(RecRef.FieldExist(i)));
        Observer.Observe('exist_neg1', Format(RecRef.FieldExist(-1)));
        Observer.Observe('exist_big', Format(RecRef.FieldExist(99999)));
        Observer.Observe('exist_systemid', Format(RecRef.FieldExist(2000000000)));
        Observer.Observe('exist_createdat', Format(RecRef.FieldExist(2000000001)));
        Observer.Observe('exist_createdby', Format(RecRef.FieldExist(2000000002)));
        Observer.Observe('exist_modifiedat', Format(RecRef.FieldExist(2000000003)));
        Observer.Observe('exist_modifiedby', Format(RecRef.FieldExist(2000000004)));
        Observer.Observe('exist_2000000005', Format(RecRef.FieldExist(2000000005)));
        Observer.Observe('exist_maxint', Format(RecRef.FieldExist(2147483647)));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Field_ByNumberNames()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.Open(72200);
        for i := 1 to 10 do
            Observer.Observe('name_' + Format(i), FieldName(RecRef, i));
        Observer.Observe('name_systemid', FieldName(RecRef, 2000000000));
        Observer.Observe('name_createdat', FieldName(RecRef, 2000000001));
        Observer.Observe('name_modifiedat', FieldName(RecRef, 2000000003));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FieldRef_CopyRefersToSameField()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Fld2: FieldRef;
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.FindFirst();
        Fld := RecRef.Field(2);
        Fld2 := Fld;
        Observer.Observe('copy_number', Format(Fld2.Number()));
        Fld2.Value := 'Changed';
        Observer.Observe('via_original', Format(Fld.Value));
        Observer.Observe('via_recref', Format(RecRef.Field(2).Value));
        Fld.Value := 'Again';
        Observer.Observe('via_copy', Format(Fld2.Value));
        RecRef.FindLast();
        Observer.Observe('after_find_last_original', Format(Fld.Value));
        Observer.Observe('after_find_last_copy', Format(Fld2.Value));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FieldRef_Uninitialized()
    var
        Observer: Codeunit "Probe Observer";
        Fld: FieldRef;
        Dummy: Text;
        N: Integer;
    begin
        asserterror Dummy := Fld.Name();
        Observer.ObserveError('name');
        asserterror N := Fld.Number();
        Observer.ObserveError('number');
        asserterror Dummy := Format(Fld.Value);
        Observer.ObserveError('value');
        asserterror Dummy := Fld.Caption();
        Observer.ObserveError('caption');
        asserterror Fld.TestField();
        Observer.ObserveError('testfield');
        asserterror Fld.FieldError();
        Observer.ObserveError('fielderror');
        Observer.Finish();
    end;

    [Test]
    procedure FieldExist_ClosedRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        B: Boolean;
    begin
        asserterror B := RecRef.FieldExist(1);
        Observer.ObserveError('closed_fieldexist');
        RecRef.Open(72200);
        RecRef.Close();
        asserterror B := RecRef.FieldExist(1);
        Observer.ObserveError('after_close_fieldexist');
        Observer.Finish();
    end;
}
