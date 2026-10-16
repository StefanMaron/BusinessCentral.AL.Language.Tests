// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P89 Rec (74625), enum LT P89 Color (74626)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74630 "LT P89 Is Misc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsBinary() then
            R += 'Binary,';
        if V.IsWideChar() then
            R += 'WideChar,';
        if V.IsChar() then
            R += 'Char,';
        if V.IsText() then
            R += 'Text,';
        if V.IsCode() then
            R += 'Code,';
        if V.IsInteger() then
            R += 'Integer,';
        if V.IsBigInteger() then
            R += 'BigInteger,';
        if V.IsByte() then
            R += 'Byte,';
        if V.IsOption() then
            R += 'Option,';
        if V.IsDecimal() then
            R += 'Decimal,';
        if V.IsBoolean() then
            R += 'Boolean,';
        exit(R);
    end;

    [Test]
    procedure Binary_OnManyVariants()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Ins: InStream;
        Outs: OutStream;
        TB: TextBuilder;
        V: Variant;
        I: Integer;
        T: Text;
        Bl: Boolean;
        Bi: BigInteger;
        D: Decimal;
    begin
        V := I; Observer.Observe('integer', Format(V.IsBinary()));
        V := T; Observer.Observe('text', Format(V.IsBinary()));
        V := Bl; Observer.Observe('boolean', Format(V.IsBinary()));
        V := Bi; Observer.Observe('biginteger', Format(V.IsBinary()));
        V := D; Observer.Observe('decimal', Format(V.IsBinary()));
        V := Rec; Observer.Observe('record', Format(V.IsBinary()));
        V := Rec.Data; Observer.Observe('blobfield_value', Format(V.IsBinary()));
        Rec.Data.CreateInStream(Ins);
        V := Ins; Observer.Observe('instream', Format(V.IsBinary()));
        Rec.Data.CreateOutStream(Outs);
        V := Outs; Observer.Observe('outstream', Format(V.IsBinary()));
        V := TB; Observer.Observe('textbuilder', Format(V.IsBinary()));
        Clear(V); Observer.Observe('empty', Format(V.IsBinary()));
        Observer.Observe('empty_flags', Flags(V));
        Observer.Finish();
    end;

    [Test]
    procedure Binary_FromBlobFieldRef()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        RecRef: RecordRef;
        FRef: FieldRef;
        V: Variant;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Insert();
        RecRef.GetTable(Rec);
        FRef := RecRef.Field(2);
        V := FRef.Value;
        Observer.Observe('fieldref_value_binary', Format(V.IsBinary()));
        Observer.Observe('fieldref_value_flags', Flags(V));
        V := FRef;
        Observer.Observe('fieldref_binary', Format(V.IsBinary()));
        Observer.Observe('fieldref_flags', Flags(V));
        Observer.Finish();
    end;

    [Test]
    procedure WideChar_Variants()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Ch: Char;
        By: Byte;
        I: Integer;
        T: Text;
        C: Code[10];
        Bi: BigInteger;
    begin
        V := Ch; Observer.Observe('char0', Flags(V));
        Ch := 65; V := Ch; Observer.Observe('char65', Flags(V));
        Ch := 256; V := Ch; Observer.Observe('char256', Flags(V));
        Ch := 65535; V := Ch; Observer.Observe('char65535', Flags(V));
        By := 65; V := By; Observer.Observe('byte65', Flags(V));
        I := 65; V := I; Observer.Observe('integer65', Flags(V));
        Bi := 65; V := Bi; Observer.Observe('biginteger65', Flags(V));
        T := 'A'; V := T; Observer.Observe('text_A', Flags(V));
        C := 'A'; V := C; Observer.Observe('code_A', Flags(V));
        V := 'A'; Observer.Observe('literal_A', Flags(V));
        V := 'AB'; Observer.Observe('literal_AB', Flags(V));
        Observer.Observe('wide_char65', Format(V.IsWideChar()));
        Observer.Finish();
    end;

    [Test]
    procedure NearTypes_TextVsCode_IntegerVsBigInteger()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        T: Text;
        T10: Text[10];
        C10: Code[10];
        C20: Code[20];
        I: Integer;
        Bi: BigInteger;
        D: Decimal;
        O: Option A,B,C;
        E: Enum "LT P89 Color";
    begin
        T := 'abc'; V := T; Observer.Observe('text', Flags(V));
        T10 := 'abc'; V := T10; Observer.Observe('text10', Flags(V));
        C10 := 'abc'; V := C10; Observer.Observe('code10', Flags(V));
        C20 := 'abc'; V := C20; Observer.Observe('code20', Flags(V));
        V := Format(C10); Observer.Observe('format_code', Flags(V));
        V := CopyStr(T, 1, 2); Observer.Observe('copystr_text', Flags(V));
        V := CopyStr(C10, 1, 2); Observer.Observe('copystr_code', Flags(V));
        V := UpperCase(C10); Observer.Observe('uppercase_code', Flags(V));
        I := 5; V := I; Observer.Observe('integer', Flags(V));
        Bi := 5; V := Bi; Observer.Observe('biginteger', Flags(V));
        V := I + Bi; Observer.Observe('int_plus_bigint', Flags(V));
        V := I * 2; Observer.Observe('int_times_2', Flags(V));
        V := I / 2; Observer.Observe('int_div_2', Flags(V));
        V := I div 2; Observer.Observe('int_div_keyword', Flags(V));
        V := D + I; Observer.Observe('dec_plus_int', Flags(V));
        V := Round(1.5, 1); Observer.Observe('round_literal', Flags(V));
        V := Abs(I); Observer.Observe('abs_int', Flags(V));
        V := Abs(Bi); Observer.Observe('abs_bigint', Flags(V));
        O := O::B; V := O; Observer.Observe('option', Flags(V));
        E := E::Green; V := E; Observer.Observe('enum', Flags(V));
        V := O::B; Observer.Observe('option_literal', Flags(V));
        Observer.Finish();
    end;

}
