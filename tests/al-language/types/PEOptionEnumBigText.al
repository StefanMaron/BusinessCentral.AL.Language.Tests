// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-enum-assignment-compatibility
// https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/bigtext/bigtext-read-method
// Scope: in-scope
// Fixtures used: self-contained enums 69170 and 69171, table 69170, codeunits 69170 (Option to Enum) and 69171 (BigText.Read)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// Option to Enum (probes-needed.md "An Option assigned to an Enum"; Base Application's Electronic Document Format does Get(Code, UsageOption)):
// - An Option value is taken as its ORDINAL: Option member 1 gives the enum member whose ordinal is 1, member 7 the enum member with ordinal 7
//   (enum values 0, 1, 7, 9). This holds with and without AssignmentCompatibility on the enum; the blank Option member ' ' (ordinal 0) gives
//   the enum member with ordinal 0.
// - An ordinal the enum does not have raises NO error: the enum then holds that ordinal, Format shows the number ('2', '8') and AsInteger gives it.
// - A field assignment, Validate, a procedure argument, SetRange / SetFilter, FieldRef.Value and Get(Code, Opt) on an Enum key take the Option the same way.
//   Get(Code, Opt) with an ordinal that has no row answers "The ... does not exist. Identification fields and values: Code='X',Usage='Three'" (DB:RecordNotFound),
//   or false when the result is used.
// - Evaluate(Enum, Format(Option)), Evaluate(Enum, '1') and Evaluate(Enum, 'Seven') succeed.
//
// BigText.Read(InStream) (probes-needed.md "BigText.Read"): answers true; REPLACES the text the BigText holds (a second Read of the same, drained stream
// leaves it empty). UTF8 stream: a byte order mark (EF BB BF) is dropped, multi-byte characters decode; UTF16 stream: little endian, a byte order mark is dropped;
// Windows stream: bytes are Windows-1252 (0x80 reads as U+20AC); the DEFAULT stream (CreateInStream without an encoding) reads the same bytes as Windows-1252, not UTF-8
// (the UTF-8 bytes of an euro sign read as three characters 226 8218 172). CR LF is kept.
// BC versions: 27.5

enum 69170 "PE Kind"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
    value(7; Seven) { }
    value(9; Nine) { }
}

enum 69171 "PE Plain Kind"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
    value(7; Seven) { }
    value(9; Nine) { }
}

table 69170 "PE Usage Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Usage; Enum "PE Kind") { }
        field(3; Plain; Enum "PE Plain Kind") { }
        field(4; Info; Text[50]) { }
    }

    keys
    {
        key(PK; "Code", Usage) { Clustered = true; }
    }
}

codeunit 69170 "PE Option Enum Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure OptionToEnum_ByOrdinal()
    var
        Opt: Option "None",One,Two,Three,Four,Five,Six,Seven,Eight,Nine;
        K: Enum "PE Kind";
        Observer: Codeunit "Probe Observer";
    begin
        Opt := Opt::One;
        K := Opt;
        Observer.Observe('one_name', Format(K));
        Observer.Observe('one_ordinal', Format(K.AsInteger()));
        Opt := Opt::Seven;
        K := Opt;
        Observer.Observe('seven_name', Format(K));
        Observer.Observe('seven_ordinal', Format(K.AsInteger()));
        Opt := Opt::Nine;
        K := Opt;
        Observer.Observe('nine_name', Format(K));
        Opt := Opt::None;
        K := Opt;
        Observer.Observe('zero_name', Format(K));
        Observer.Observe('zero_ordinal', Format(K.AsInteger()));
        Observer.Expect('one_name', 'One');
        Observer.Expect('one_ordinal', '1');
        Observer.Expect('seven_name', 'Seven');
        Observer.Expect('seven_ordinal', '7');
        Observer.Expect('nine_name', 'Nine');
        Observer.Expect('zero_name', 'None');
        Observer.Expect('zero_ordinal', '0');
        Observer.Verify();
    end;

    [Test]
    procedure OptionToEnum_OrdinalTheEnumLacks()
    var
        Opt: Option "None",One,Two,Three,Four,Five,Six,Seven,Eight,Nine;
        K: Enum "PE Kind";
        Observer: Codeunit "Probe Observer";
    begin
        K := K::Seven;
        Opt := Opt::Two;
        K := Opt;
        Observer.Observe('ordinal2_text', '[' + Format(K) + ']');
        Observer.Observe('ordinal2_ordinal', Format(K.AsInteger()));
        Opt := Opt::Eight;
        K := Opt;
        Observer.Observe('ordinal8_text', '[' + Format(K) + ']');
        Observer.Observe('ordinal8_ordinal', Format(K.AsInteger()));
        Observer.Observe('ordinal8_equals_none', Format(K = K::None));
        Observer.Expect('ordinal2_text', '[2]');
        Observer.Expect('ordinal2_ordinal', '2');
        Observer.Expect('ordinal8_text', '[8]');
        Observer.Expect('ordinal8_ordinal', '8');
        Observer.Expect('ordinal8_equals_none', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure OptionToEnum_BlankMember()
    var
        Opt: Option " ",One;
        K: Enum "PE Kind";
        Observer: Codeunit "Probe Observer";
    begin
        K := K::Seven;
        Opt := Opt::" ";
        K := Opt;
        Observer.Observe('blank_option_name', Format(K));
        Observer.Observe('blank_option_ordinal', Format(K.AsInteger()));
        Observer.Observe('blank_option_text', '[' + Format(Opt) + ']');
        Observer.Expect('blank_option_name', 'None');
        Observer.Expect('blank_option_ordinal', '0');
        Observer.Expect('blank_option_text', '[ ]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionToEnum_ValueTextForms()
    var
        K: Enum "PE Kind";
        Opt: Option "None",One,Two;
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Opt := Opt::One;
        Ok := Evaluate(K, Format(Opt));
        Observer.Observe('evaluate_option_text_ok', Format(Ok));
        Observer.Observe('evaluate_option_text_value', Format(K));
        Ok := Evaluate(K, '1');
        Observer.Observe('evaluate_ordinal_text_ok', Format(Ok));
        Observer.Observe('evaluate_ordinal_text_value', Format(K));
        Ok := Evaluate(K, 'Seven');
        Observer.Observe('evaluate_name_ok', Format(Ok));
        Observer.Observe('evaluate_name_value', Format(K.AsInteger()));
        Observer.Expect('evaluate_option_text_ok', 'Yes');
        Observer.Expect('evaluate_option_text_value', 'One');
        Observer.Expect('evaluate_ordinal_text_ok', 'Yes');
        Observer.Expect('evaluate_ordinal_text_value', 'One');
        Observer.Expect('evaluate_name_ok', 'Yes');
        Observer.Expect('evaluate_name_value', '7');
        Observer.Verify();
    end;

    [Test]
    procedure OptionToEnum_PlainEnumWithoutAssignmentCompatibility()
    var
        Opt: Option "None",One,Two,Three,Four,Five,Six,Seven;
        K: Enum "PE Plain Kind";
        Observer: Codeunit "Probe Observer";
    begin
        Opt := Opt::Seven;
        K := Opt;
        Observer.Observe('seven_name', Format(K));
        Observer.Observe('seven_ordinal', Format(K.AsInteger()));
        Observer.Expect('seven_name', 'Seven');
        Observer.Expect('seven_ordinal', '7');
        Observer.Verify();
    end;

    [Test]
    procedure OptionToEnum_FieldAssignmentAndValidate()
    var
        Row: Record "PE Usage Row";
        Opt: Option "None",One,Two,Three,Four,Five,Six,Seven;
        Observer: Codeunit "Probe Observer";
    begin
        Opt := Opt::Seven;
        Row.Usage := Opt;
        Observer.Observe('field_assign', Format(Row.Usage));
        Row.Plain := Opt;
        Observer.Observe('field_assign_plain', Format(Row.Plain));
        Row.Usage := Row.Usage::None;
        Row.Validate(Usage, Opt);
        Observer.Observe('field_validate', Format(Row.Usage));
        Observer.Expect('field_assign', 'Seven');
        Observer.Expect('field_assign_plain', 'Seven');
        Observer.Expect('field_validate', 'Seven');
        Observer.Verify();
    end;

    [Test]
    procedure OptionToEnum_ProcedureArgument()
    var
        Opt: Option "None",One,Two,Three,Four,Five,Six,Seven;
        Observer: Codeunit "Probe Observer";
    begin
        Opt := Opt::Seven;
        Observer.Observe('argument', TakeEnum(Opt));
        Observer.Expect('argument', 'Seven/7');
        Observer.Verify();
    end;

    local procedure TakeEnum(K: Enum "PE Kind"): Text
    begin
        exit(Format(K) + '/' + Format(K.AsInteger()));
    end;

    [Test]
    procedure OptionToEnum_InPrimaryKeyGet()
    var
        Row: Record "PE Usage Row";
        Found: Record "PE Usage Row";
        Opt: Option "None",One,Two,Three,Four,Five,Six,Seven;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Code := 'X';
        Row.Usage := Row.Usage::Seven;
        Row.Info := 'seven';
        Row.Insert();
        Row.Usage := Row.Usage::One;
        Row.Info := 'one';
        Row.Insert();
        Opt := Opt::Seven;
        Observer.Observe('get_found', Format(Found.Get('X', Opt)));
        Observer.Observe('get_info', Found.Info);
        Opt := Opt::One;
        Observer.Observe('get_one_found', Format(Found.Get('X', Opt)));
        Observer.Observe('get_one_info', Found.Info);
        Opt := Opt::Three;
        asserterror Found.Get('X', Opt);
        Observer.ObserveError('get_ordinal3');
        Opt := Opt::Two;
        Observer.Observe('get_two_found', Format(Found.Get('X', Opt)));
        Observer.Expect('get_found', 'Yes');
        Observer.Expect('get_info', 'seven');
        Observer.Expect('get_one_found', 'Yes');
        Observer.Expect('get_one_info', 'one');
        Observer.Expect('get_ordinal3|text', 'The PE Usage Row does not exist. Identification fields and values: Code=''X'',Usage=''Three''');
        Observer.Expect('get_ordinal3|code', 'DB:RecordNotFound');
        Observer.Expect('get_two_found', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure OptionToEnum_SetRangeAndFilter()
    var
        Row: Record "PE Usage Row";
        Opt: Option "None",One,Two,Three,Four,Five,Six,Seven;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Code := 'Y';
        Row.Usage := Row.Usage::Seven;
        Row.Insert();
        Opt := Opt::Seven;
        Row.SetRange(Usage, Opt);
        Observer.Observe('setrange_count', Format(Row.Count()));
        Observer.Observe('setrange_filter', Row.GetFilter(Usage));
        Row.SetFilter(Usage, '%1', Opt);
        Observer.Observe('setfilter_count', Format(Row.Count()));
        Observer.Expect('setrange_count', '1');
        Observer.Expect('setrange_filter', 'Seven');
        Observer.Expect('setfilter_count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure OptionToEnum_FieldRefValue()
    var
        Row: Record "PE Usage Row";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Opt: Option "None",One,Two,Three,Four,Five,Six,Seven;
        Observer: Codeunit "Probe Observer";
    begin
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(Row.FieldNo(Usage));
        Opt := Opt::Seven;
        FldRef.Value := Opt;
        Observer.Observe('fieldref_value', Format(FldRef.Value));
        Observer.Observe('fieldref_enum_name', Format(Row.Usage));
        RecRef.SetTable(Row);
        Observer.Observe('record_after_settable', Format(Row.Usage));
        Observer.Expect('fieldref_value', 'Seven');
        Observer.Expect('fieldref_enum_name', 'None');
        Observer.Expect('record_after_settable', 'Seven');
        Observer.Verify();
    end;
}

codeunit 69171 "PE BigText Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Blob(var TempBlob: Codeunit "Temp Blob"; B1: Integer; B2: Integer; B3: Integer; B4: Integer; B5: Integer; B6: Integer; B7: Integer)
    var
        Out: OutStream;
        B: Byte;
        Bytes: List of [Integer];
        V: Integer;
    begin
        TempBlob.CreateOutStream(Out);
        Bytes.Add(B1);
        Bytes.Add(B2);
        Bytes.Add(B3);
        Bytes.Add(B4);
        Bytes.Add(B5);
        Bytes.Add(B6);
        Bytes.Add(B7);
        foreach V in Bytes do
            if V >= 0 then begin
                B := V;
                Out.Write(B);
            end;
    end;

    [Test]
    procedure Read_Utf8_NoBom_NonAscii()
    var
        TempBlob: Codeunit "Temp Blob";
        In1: InStream;
        Big: BigText;
        Sub: Text;
        Len: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        // 'h', U+00E9 (C3 A9), U+20AC (E2 82 AC)
        Blob(TempBlob, 104, 195, 169, 226, 130, 172, -1);
        TempBlob.CreateInStream(In1, TextEncoding::UTF8);
        Len := Big.Read(In1);
        Observer.Observe('return', Format(Len));
        Observer.Observe('length', Format(Big.Length()));
        Big.GetSubText(Sub, 1, Big.Length());
        Observer.Observe('text_codes', Codes(Sub));
        Observer.Expect('return', 'Yes');
        Observer.Expect('length', '3');
        Observer.Expect('text_codes', '104 233 8364 ');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Utf8_WithBom()
    var
        TempBlob: Codeunit "Temp Blob";
        In1: InStream;
        Big: BigText;
        Sub: Text;
        Len: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        // EF BB BF 'a' 'b'
        Blob(TempBlob, 239, 187, 191, 97, 98, -1, -1);
        TempBlob.CreateInStream(In1, TextEncoding::UTF8);
        Len := Big.Read(In1);
        Observer.Observe('return', Format(Len));
        Observer.Observe('length', Format(Big.Length()));
        Big.GetSubText(Sub, 1, Big.Length());
        Observer.Observe('text_codes', Codes(Sub));
        Observer.Expect('return', 'Yes');
        Observer.Expect('length', '2');
        Observer.Expect('text_codes', '97 98 ');
        Observer.Verify();
    end;

    [Test]
    procedure Read_DefaultEncodingStream_Utf8Bytes()
    var
        TempBlob: Codeunit "Temp Blob";
        In1: InStream;
        Big: BigText;
        Sub: Text;
        Len: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Blob(TempBlob, 104, 195, 169, 226, 130, 172, -1);
        TempBlob.CreateInStream(In1);
        Len := Big.Read(In1);
        Observer.Observe('return', Format(Len));
        Observer.Observe('length', Format(Big.Length()));
        Big.GetSubText(Sub, 1, Big.Length());
        Observer.Observe('text_codes', Codes(Sub));
        Observer.Expect('return', 'Yes');
        Observer.Expect('length', '6');
        Observer.Expect('text_codes', '104 8220 20 203 233 188 ');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Utf16_NoBom_AndWithBom()
    var
        TempBlob: Codeunit "Temp Blob";
        In1: InStream;
        Big: BigText;
        Sub: Text;
        Len: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        // 'a' 'b' as UTF-16 little endian
        Blob(TempBlob, 97, 0, 98, 0, -1, -1, -1);
        TempBlob.CreateInStream(In1, TextEncoding::UTF16);
        Len := Big.Read(In1);
        Observer.Observe('nobom_return', Format(Len));
        Observer.Observe('nobom_length', Format(Big.Length()));
        Big.GetSubText(Sub, 1, Big.Length());
        Observer.Observe('nobom_text_codes', Codes(Sub));
        // FF FE 'a' 'b'
        Clear(TempBlob);
        Blob(TempBlob, 255, 254, 97, 0, 98, 0, -1);
        TempBlob.CreateInStream(In1, TextEncoding::UTF16);
        Clear(Big);
        Len := Big.Read(In1);
        Observer.Observe('bom_return', Format(Len));
        Observer.Observe('bom_length', Format(Big.Length()));
        Big.GetSubText(Sub, 1, Big.Length());
        Observer.Observe('bom_text_codes', Codes(Sub));
        Observer.Expect('nobom_return', 'Yes');
        Observer.Expect('nobom_length', '2');
        Observer.Expect('nobom_text_codes', '97 98 ');
        Observer.Expect('bom_return', 'Yes');
        Observer.Expect('bom_length', '2');
        Observer.Expect('bom_text_codes', '97 98 ');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Utf8BytesAsWindows1252()
    var
        TempBlob: Codeunit "Temp Blob";
        In1: InStream;
        Big: BigText;
        Sub: Text;
        Len: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        // E9 (e acute in Windows-1252), 80 (euro in Windows-1252)
        Blob(TempBlob, 233, 128, -1, -1, -1, -1, -1);
        TempBlob.CreateInStream(In1, TextEncoding::Windows);
        Len := Big.Read(In1);
        Observer.Observe('return', Format(Len));
        Big.GetSubText(Sub, 1, Big.Length());
        Observer.Observe('text_codes', Codes(Sub));
        Observer.Expect('return', 'Yes');
        Observer.Expect('text_codes', '233 8364 ');
        Observer.Verify();
    end;

    [Test]
    procedure Read_IntoBigTextThatHasText_ReplaceOrAppend()
    var
        TempBlob: Codeunit "Temp Blob";
        In1: InStream;
        Big: BigText;
        Sub: Text;
        Len: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Big.AddText('old');
        Blob(TempBlob, 110, 101, 119, -1, -1, -1, -1);
        TempBlob.CreateInStream(In1, TextEncoding::UTF8);
        Len := Big.Read(In1);
        Observer.Observe('return', Format(Len));
        Observer.Observe('length', Format(Big.Length()));
        Big.GetSubText(Sub, 1, Big.Length());
        Observer.Observe('text', Sub);
        Observer.Expect('return', 'Yes');
        Observer.Expect('length', '3');
        Observer.Expect('text', 'new');
        Observer.Verify();
    end;

    [Test]
    procedure Read_EmptyStream_AndTwice()
    var
        TempBlob: Codeunit "Temp Blob";
        In1: InStream;
        Big: BigText;
        Sub: Text;
        Len: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        TempBlob.CreateInStream(In1, TextEncoding::UTF8);
        Len := Big.Read(In1);
        Observer.Observe('empty_return', Format(Len));
        Observer.Observe('empty_length', Format(Big.Length()));
        Blob(TempBlob, 97, 98, 99, -1, -1, -1, -1);
        TempBlob.CreateInStream(In1, TextEncoding::UTF8);
        Len := Big.Read(In1);
        Observer.Observe('first_return', Format(Len));
        Len := Big.Read(In1);
        Observer.Observe('second_return_same_stream', Format(Len));
        Observer.Observe('second_length', Format(Big.Length()));
        Big.GetSubText(Sub, 2, 2);
        Observer.Observe('subtext_2_2', Sub);
        Observer.Observe('textpos_c', Format(Big.TextPos('c')));
        Observer.Expect('empty_return', 'Yes');
        Observer.Expect('empty_length', '0');
        Observer.Expect('first_return', 'Yes');
        Observer.Expect('second_return_same_stream', 'Yes');
        Observer.Expect('second_length', '0');
        Observer.Expect('subtext_2_2', '');
        Observer.Expect('textpos_c', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Read_MultipleLinesAndCrLf()
    var
        TempBlob: Codeunit "Temp Blob";
        In1: InStream;
        Big: BigText;
        Sub: Text;
        Observer: Codeunit "Probe Observer";
    begin
        // 'a' CR LF 'b'
        Blob(TempBlob, 97, 13, 10, 98, -1, -1, -1);
        TempBlob.CreateInStream(In1, TextEncoding::UTF8);
        Big.Read(In1);
        Observer.Observe('length', Format(Big.Length()));
        Big.GetSubText(Sub, 1, Big.Length());
        Observer.Observe('text_codes', Codes(Sub));
        Observer.Expect('length', '4');
        Observer.Expect('text_codes', '97 13 10 98 ');
        Observer.Verify();
    end;

    local procedure Codes(Value: Text): Text
    var
        i: Integer;
        Result: Text;
        C: Char;
        V: Integer;
    begin
        for i := 1 to StrLen(Value) do begin
            C := Value[i];
            V := C;
            Result += Format(V) + ' ';
        end;
        exit(Result);
    end;
}
