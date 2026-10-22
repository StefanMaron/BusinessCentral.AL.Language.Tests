// Batch 6, md:344 [Field] "Type" and the other Field columns, and md:362 [Key, Field] rows of a table that nothing in AL code reaches.
// Observe-only. Table 67307 has one field of each common type; table 67309 is never named in AL code (only its number is used).
// A type is observed as its name and as its ordinal (Format(..., 0, 2)); the ordinal is the question of md:344 (member position or a declared number).

table 67307 "W6 FK Types"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; FInteger; Integer) { }
        field(2; FText; Text[30]) { Caption = 'Text caption'; }
        field(3; FCode; Code[10]) { }
        field(4; FDecimal; Decimal) { }
        field(5; FBoolean; Boolean) { }
        field(6; FDate; Date) { }
        field(7; FTime; Time) { }
        field(8; FDateTime; DateTime) { }
        field(9; FOption; Option) { OptionMembers = A,B,C; }
        field(10; FBigInteger; BigInteger) { }
        field(11; FBlob; Blob) { }
        field(12; FGuid; Guid) { }
        field(13; FDuration; Duration) { }
        field(14; FRecordId; RecordId) { }
        field(15; FMedia; Media) { }
        field(16; FText250; Text[250]) { }
        field(17; FNormalSum; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("W6 FK Types");
        }
        field(18; FFilter; Integer) { FieldClass = FlowFilter; }
        field(19; FKind; Enum "W6 FK Kind") { }
        field(20; FTextBig; Text[2048]) { }
        field(21; FDecimalFiltered; Decimal) { DecimalPlaces = 2 : 5; }
    }

    keys
    {
        key(PK; FInteger) { Clustered = true; }
    }
}

enum 67308 "W6 FK Kind"
{
    Extensible = true;

    value(0; Zero) { }
    value(5; Five) { }
    value(10; Ten) { }
}

table 67309 "W6 FK Never Reached"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; First; Code[20]) { }
        field(2; Second; Integer) { }
        field(3; Third; Text[50]) { }
    }

    keys
    {
        key(PK; First) { Clustered = true; }
        key(K2; Second, Third) { }
    }
}

codeunit 67310 "W6 Field Key Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TypeText(FieldName: Text): Text
    var
        FieldRec: Record Field;
    begin
        FieldRec.SetRange(TableNo, Database::"W6 FK Types");
        FieldRec.SetRange(FieldName, FieldName);
        if not FieldRec.FindFirst() then
            exit('<no row>');
        exit(Format(FieldRec.Type) + '/' + Format(FieldRec.Type, 0, 2));
    end;

    [Test]
    procedure Field_Type_NameAndOrdinal_PerDeclaredType()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('FInteger', TypeText('FInteger'));
        Observer.Observe('FText', TypeText('FText'));
        Observer.Observe('FCode', TypeText('FCode'));
        Observer.Observe('FDecimal', TypeText('FDecimal'));
        Observer.Observe('FBoolean', TypeText('FBoolean'));
        Observer.Observe('FDate', TypeText('FDate'));
        Observer.Observe('FTime', TypeText('FTime'));
        Observer.Observe('FDateTime', TypeText('FDateTime'));
        Observer.Observe('FOption', TypeText('FOption'));
        Observer.Observe('FBigInteger', TypeText('FBigInteger'));
        Observer.Observe('FBlob', TypeText('FBlob'));
        Observer.Observe('FGuid', TypeText('FGuid'));
        Observer.Observe('FDuration', TypeText('FDuration'));
        Observer.Observe('FRecordId', TypeText('FRecordId'));
        Observer.Observe('FMedia', TypeText('FMedia'));
        Observer.Observe('FKind', TypeText('FKind'));
        Observer.Observe('FNormalSum', TypeText('FNormalSum'));
        Observer.Observe('SystemId', TypeText('$systemId'));
        Observer.Observe('SystemCreatedAt', TypeText('SystemCreatedAt'));
        Observer.Observe('SystemCreatedBy', TypeText('SystemCreatedBy'));
        Observer.Expect('FInteger', 'Integer/34559');
        Observer.Expect('FText', 'Text/31488');
        Observer.Expect('FCode', 'Code/31489');
        Observer.Expect('FDecimal', 'Decimal/12799');
        Observer.Expect('FBoolean', 'Boolean/34047');
        Observer.Expect('FDate', 'Date/11775');
        Observer.Expect('FTime', 'Time/11776');
        Observer.Expect('FDateTime', 'DateTime/37375');
        Observer.Expect('FOption', 'Option/35583');
        Observer.Expect('FBigInteger', 'BigInteger/36095');
        Observer.Expect('FBlob', 'BLOB/33793');
        Observer.Expect('FGuid', 'GUID/37119');
        Observer.Expect('FDuration', 'Duration/36863');
        Observer.Expect('FRecordId', 'RecordID/4988');
        Observer.Expect('FMedia', 'Media/26207');
        Observer.Expect('FKind', 'Option/35583');
        Observer.Expect('FNormalSum', 'Integer/34559');
        Observer.Expect('SystemId', 'GUID/37119');
        Observer.Expect('SystemCreatedAt', 'DateTime/37375');
        Observer.Expect('SystemCreatedBy', 'GUID/37119');
        Observer.Verify();
    end;

    [Test]
    procedure Field_Type_ComparedWithMembers()
    var
        FieldRec: Record Field;
        Observer: Codeunit "Probe Observer";
    begin
        FieldRec.SetRange(TableNo, Database::"W6 FK Types");
        FieldRec.SetRange(FieldName, 'FInteger');
        FieldRec.FindFirst();
        Observer.Observe('integer_equals_member_Integer', Format(FieldRec.Type = FieldRec.Type::Integer));
        Observer.Observe('integer_ordinal_of_member_Integer', Format(FieldRec.Type::Integer, 0, 2));
        Observer.Observe('blob_ordinal_of_member_BLOB', Format(FieldRec.Type::BLOB, 0, 2));
        Observer.Observe('text_ordinal_of_member_Text', Format(FieldRec.Type::Text, 0, 2));
        Observer.Observe('code_ordinal_of_member_Code', Format(FieldRec.Type::Code, 0, 2));
        Observer.Observe('option_ordinal_of_member_Option', Format(FieldRec.Type::Option, 0, 2));
        Observer.Observe('guid_ordinal_of_member_GUID', Format(FieldRec.Type::GUID, 0, 2));
        FieldRec.SetRange(FieldName);
        FieldRec.SetRange(Type, FieldRec.Type::Blob);
        Observer.Observe('count_of_blob_fields', Format(FieldRec.Count()));
        FieldRec.SetRange(Type, FieldRec.Type::Integer);
        Observer.Observe('count_of_integer_fields', Format(FieldRec.Count()));
        FieldRec.SetRange(Type, FieldRec.Type::Text);
        Observer.Observe('count_of_text_fields', Format(FieldRec.Count()));
        Observer.Expect('integer_equals_member_Integer', 'Yes');
        Observer.Expect('integer_ordinal_of_member_Integer', '34559');
        Observer.Expect('blob_ordinal_of_member_BLOB', '33793');
        Observer.Expect('text_ordinal_of_member_Text', '31488');
        Observer.Expect('code_ordinal_of_member_Code', '31489');
        Observer.Expect('option_ordinal_of_member_Option', '35583');
        Observer.Expect('guid_ordinal_of_member_GUID', '37119');
        Observer.Expect('count_of_blob_fields', '1');
        Observer.Expect('count_of_integer_fields', '3');
#if BC29PLUS
        Observer.Expect('count_of_text_fields', '7');
#else
        Observer.Expect('count_of_text_fields', '3');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Field_OtherColumns_Len_Class_TypeName_FieldCaption_Enabled()
    var
        FieldRec: Record Field;
        Observer: Codeunit "Probe Observer";
    begin
        FieldRec.SetRange(TableNo, Database::"W6 FK Types");
        FieldRec.SetRange(FieldName, 'FText');
        FieldRec.FindFirst();
        Observer.Observe('FText_len', Format(FieldRec.Len));
        Observer.Observe('FText_class', Format(FieldRec.Class));
        Observer.Observe('FText_type_name', FieldRec."Type Name");
        Observer.Observe('FText_caption', FieldRec."Field Caption");
        Observer.Observe('FText_enabled', Format(FieldRec.Enabled));
        Observer.Observe('FText_no', Format(FieldRec."No."));
        Observer.Observe('FText_table_name', FieldRec.TableName);
        FieldRec.SetRange(FieldName, 'FCode');
        FieldRec.FindFirst();
        Observer.Observe('FCode_len', Format(FieldRec.Len));
        Observer.Observe('FCode_type_name', FieldRec."Type Name");
        FieldRec.SetRange(FieldName, 'FText250');
        FieldRec.FindFirst();
        Observer.Observe('FText250_len', Format(FieldRec.Len));
        FieldRec.SetRange(FieldName, 'FTextBig');
        FieldRec.FindFirst();
        Observer.Observe('FTextBig_len', Format(FieldRec.Len));
        Observer.Observe('FTextBig_type', Format(FieldRec.Type));
        FieldRec.SetRange(FieldName, 'FInteger');
        FieldRec.FindFirst();
        Observer.Observe('FInteger_len', Format(FieldRec.Len));
        Observer.Observe('FInteger_type_name', FieldRec."Type Name");
        FieldRec.SetRange(FieldName, 'FDecimal');
        FieldRec.FindFirst();
        Observer.Observe('FDecimal_len', Format(FieldRec.Len));
        Observer.Observe('FDecimal_type_name', FieldRec."Type Name");
        FieldRec.SetRange(FieldName, 'FBoolean');
        FieldRec.FindFirst();
        Observer.Observe('FBoolean_len', Format(FieldRec.Len));
        Observer.Observe('FBoolean_type_name', FieldRec."Type Name");
        FieldRec.SetRange(FieldName, 'FNormalSum');
        FieldRec.FindFirst();
        Observer.Observe('FNormalSum_class', Format(FieldRec.Class));
        Observer.Expect('FText_len', '30');
        Observer.Expect('FText_class', 'Normal');
        Observer.Expect('FText_type_name', 'Text30');
        Observer.Expect('FText_caption', 'Text caption');
        Observer.Expect('FText_enabled', 'Yes');
        Observer.Expect('FText_no', '2');
        Observer.Expect('FText_table_name', 'W6 FK Types');
        Observer.Expect('FCode_len', '10');
        Observer.Expect('FCode_type_name', 'Code10');
        Observer.Expect('FText250_len', '250');
        Observer.Expect('FTextBig_len', '2048');
        Observer.Expect('FTextBig_type', 'Text');
        Observer.Expect('FInteger_len', '4');
        Observer.Expect('FInteger_type_name', 'Integer');
        Observer.Expect('FDecimal_len', '12');
        Observer.Expect('FDecimal_type_name', 'Decimal');
        Observer.Expect('FBoolean_len', '4');
        Observer.Expect('FBoolean_type_name', 'Boolean');
        Observer.Expect('FNormalSum_class', 'FlowField');
        Observer.Verify();
    end;

    [Test]
    procedure Field_And_Key_Rows_OfATableNothingReaches()
    var
        FieldRec: Record Field;
        KeyRec: Record "Key";
        Names: Text;
        Keys: Text;
        Observer: Codeunit "Probe Observer";
    begin
        FieldRec.SetRange(TableNo, 67309);
        Observer.Observe('field_row_count', Format(FieldRec.Count()));
        if FieldRec.FindSet() then
            repeat
                Names += FieldRec.FieldName + ';';
            until FieldRec.Next() = 0;
        Observer.Observe('field_names', Names);
        KeyRec.SetRange(TableNo, 67309);
        Observer.Observe('key_row_count', Format(KeyRec.Count()));
        if KeyRec.FindSet() then
            repeat
                Keys += Format(KeyRec."No.") + ':' + KeyRec.Key + ';';
            until KeyRec.Next() = 0;
        Observer.Observe('keys', Keys);
#if BC29PLUS
        Observer.Expect('field_row_count', '12');
#else
        Observer.Expect('field_row_count', '8');
#endif
#if BC29PLUS
        Observer.Expect('field_names', 'First;Second;Third;$systemId;SystemCreatedAt;SystemCreatedBy;SystemModifiedAt;SystemModifiedBy;SystemCreatedByUserName;SystemCreatedByFullName;SystemModifiedByUserName;SystemModifiedByFullName;');
#else
        Observer.Expect('field_names', 'First;Second;Third;$systemId;SystemCreatedAt;SystemCreatedBy;SystemModifiedAt;SystemModifiedBy;');
#endif
        Observer.Expect('key_row_count', '3');
        Observer.Expect('keys', '1:First;2:Second,Third;3:$systemId;');
        Observer.Verify();
    end;

    [Test]
    procedure Field_And_Key_Rows_OfANumberWithNoTable()
    var
        FieldRec: Record Field;
        KeyRec: Record "Key";
        Observer: Codeunit "Probe Observer";
    begin
        FieldRec.SetRange(TableNo, 67399);
        KeyRec.SetRange(TableNo, 67399);
        Observer.Observe('field_row_count', Format(FieldRec.Count()));
        Observer.Observe('key_row_count', Format(KeyRec.Count()));
        Observer.Observe('field_is_empty', Format(FieldRec.IsEmpty()));
        Observer.Observe('key_is_empty', Format(KeyRec.IsEmpty()));
        Observer.Expect('field_row_count', '0');
        Observer.Expect('key_row_count', '0');
        Observer.Expect('field_is_empty', 'Yes');
        Observer.Expect('key_is_empty', 'Yes');
        Observer.Verify();
    end;
}
