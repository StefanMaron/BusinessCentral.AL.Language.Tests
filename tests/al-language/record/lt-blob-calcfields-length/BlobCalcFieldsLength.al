// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 74450 below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CalcFields on a Blob field and then HasValue / Length / CreateInStream, with and without content (issue #184 item 23): a fresh row, a row after Get (is the blob loaded without CalcFields), after CalcFields, content written to an OutStream and not yet modified, after Modify, after Clear of the field, FieldRef.CalcField on the blob.
// BC versions: 29 (27 and 28 by CI)

table 74450 "LT BlobCalc Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74451 "LT BlobCalc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Store(Id: Integer; Content: Text)
    var
        Row: Record "LT BlobCalc Row";
        OutS: OutStream;
    begin
        Row.Init();
        Row.Id := Id;
        if Content <> '' then begin
            Row.Data.CreateOutStream(OutS);
            OutS.WriteText(Content);
        end;
        Row.Insert();
    end;

    local procedure ReadBack(var Row: Record "LT BlobCalc Row"): Text
    var
        InS: InStream;
        Result: Text;
    begin
        Row.Data.CreateInStream(InS);
        InS.ReadText(Result);
        exit(Result);
    end;

    [Test]
    procedure BlobCalcFields_WithContent_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
    begin
        Row.DeleteAll();
        Store(1, 'hello');
        Row.Get(1);
        Observer.Observe('get_hasvalue', Format(Row.Data.HasValue()));
        Observer.Observe('get_length', Format(Row.Data.Length()));
        Row.CalcFields(Data);
        Observer.Observe('calc_hasvalue', Format(Row.Data.HasValue()));
        Observer.Observe('calc_length', Format(Row.Data.Length()));
        Observer.Observe('calc_read', ReadBack(Row));
        Observer.Expect('get_hasvalue', 'Yes');
        Observer.Expect('get_length', '11');
        Observer.Expect('calc_hasvalue', 'Yes');
        Observer.Expect('calc_length', '5');
        Observer.Expect('calc_read', 'hello');
        Observer.Verify();
    end;

    [Test]
    procedure BlobCalcFields_WithoutContent_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
    begin
        Row.DeleteAll();
        Store(2, '');
        Row.Get(2);
        Observer.Observe('get_hasvalue', Format(Row.Data.HasValue()));
        Row.CalcFields(Data);
        Observer.Observe('calc_hasvalue', Format(Row.Data.HasValue()));
        Observer.Observe('calc_length', Format(Row.Data.Length()));
        Observer.Observe('calc_read', '[' + ReadBack(Row) + ']');
        Observer.Expect('get_hasvalue', 'No');
        Observer.Expect('calc_hasvalue', 'No');
        Observer.Expect('calc_length', '0');
        Observer.Expect('calc_read', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure BlobCalcFields_UnsavedContent_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
        OutS: OutStream;
    begin
        Row.DeleteAll();
        Store(3, 'stored');
        Row.Get(3);
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText('changed in memory');
        Observer.Observe('mem_length', Format(Row.Data.Length()));
        Row.CalcFields(Data);
        Observer.Observe('after_calc_length', Format(Row.Data.Length()));
        Observer.Observe('after_calc_read', ReadBack(Row));
        Observer.Expect('mem_length', '17');
        Observer.Expect('after_calc_length', '6');
        Observer.Expect('after_calc_read', 'stored');
        Observer.Verify();
    end;

    [Test]
    procedure BlobCalcFields_AfterModifyAndClear_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
        Other: Record "LT BlobCalc Row";
        OutS: OutStream;
    begin
        Row.DeleteAll();
        Store(4, 'one');
        Row.Get(4);
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText('twotwo');
        Row.Modify();
        Other.Get(4);
        Other.CalcFields(Data);
        Observer.Observe('modified_length', Format(Other.Data.Length()));
        Observer.Observe('modified_read', ReadBack(Other));
        Clear(Other.Data);
        Observer.Observe('cleared_hasvalue', Format(Other.Data.HasValue()));
        Other.Modify();
        Other.Get(4);
        Other.CalcFields(Data);
        Observer.Observe('cleared_saved_hasvalue', Format(Other.Data.HasValue()));
        Observer.Observe('cleared_saved_length', Format(Other.Data.Length()));
        Observer.Expect('modified_length', '6');
        Observer.Expect('modified_read', 'twotwo');
        Observer.Expect('cleared_hasvalue', 'No');
        Observer.Expect('cleared_saved_hasvalue', 'No');
        Observer.Expect('cleared_saved_length', '0');
        Observer.Verify();
    end;

    [Test]
    procedure BlobCalcFields_FieldRefCalcField_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Row.DeleteAll();
        Store(5, 'refdata');
        RecRef.Open(Database::"LT BlobCalc Row");
        RecRef.Field(1).SetRange(5);
        RecRef.FindFirst();
        FldRef := RecRef.Field(2);
        Observer.Observe('class', Format(FldRef.Class));
        Observer.Observe('calc_result', Format(FldRef.CalcField()));
        Observer.Observe('type', Format(FldRef.Type));
        RecRef.Close();
        RecRef.Open(Database::"LT BlobCalc Row");
        RecRef.Field(1).SetRange(5);
        RecRef.FindFirst();
        FldRef := RecRef.Field(2);
        FldRef.CalcField();
        Observer.Observe('type_after_calc', Format(FldRef.Type));
        Observer.Observe('value_length_nonzero', Format(Format(FldRef.Value) <> ''));
        Observer.Expect('class', 'Normal');
        Observer.Expect('calc_result', 'Yes');
        Observer.Expect('type', 'BLOB');
        Observer.Expect('type_after_calc', 'BLOB');
        Observer.Expect('value_length_nonzero', 'Yes');
        Observer.Verify();
    end;
}
