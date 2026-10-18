// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own tables 79005, 79018, enum 79019
// Facts: Text + Guid concatenation and MaxStrLen of a Guid; an Option compared with a Decimal; the bytes OutStream.Write produces for value types not pinned elsewhere (Code, Option, Enum, DateFormula, RecordId, Variant, Label, BigText, Record, JsonObject); the Field table row of the rowversion field (No. 0, name timestamp) on an own table and on Customer.
// BC versions: 27.5+

table 79005 "LT AJ Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Opt; Option) { OptionMembers = A,B,C; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 79018 "LT AJ Ts"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

enum 79019 "LT AJ Enum"
{
    Extensible = true;
    value(0; A) { }
    value(7; Seven) { }
}

codeunit 79013 "LT AJ Misc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LabelValue: Label 'Lbl', Locked = true;

    [Test]
    procedure Guid_TextConcatenationAndMaxStrLen()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        Empty: Guid;
        T: Text;
        Long: Text[40];
        Cd: Code[40];
    begin
        Evaluate(G, '{11111111-2222-3333-4444-555555555555}');
        T := 'x' + Format(G);
        Observer.Observe('x + Format(G)', T);
        T := 'x' + G;
        Observer.Observe('x + G', T);
        Observer.Observe('x + G length', Format(StrLen(T)));
        T := G + 'x';
        Observer.Observe('G + x', T);
        T := 'x' + Empty;
        Observer.Observe('x + empty guid', T);
        Observer.Observe('MaxStrLen(G)', Format(MaxStrLen(G)));
        Observer.Observe('MaxStrLen(empty)', Format(MaxStrLen(Empty)));
        Long := G;
        Observer.Observe('Text[40] := G', Long);
        Cd := G;
        Observer.Observe('Code[40] := G', Cd);
        Observer.Observe('StrLen(Format(G))', Format(StrLen(Format(G))));
        Observer.Finish();
    end;

    [Test]
    procedure Option_ComparedWithDecimal()
    var
        Observer: Codeunit "Probe Observer";
        Opt: Option A,B,C;
        Item: Record "LT AJ Item";
    begin
        Opt := Opt::B;
        Observer.Observe('B = 1.0', Format(Opt = 1.0));
        Observer.Observe('B = 1', Format(Opt = 1));
        Observer.Observe('B = 0.0', Format(Opt = 0.0));
        Observer.Observe('B = 1.5', Format(Opt = 1.5));
        Observer.Observe('B <> 1.5', Format(Opt <> 1.5));
        Observer.Observe('B > 0.5', Format(Opt > 0.5));
        Observer.Observe('B > 1.0', Format(Opt > 1.0));
        Observer.Observe('B >= 1.0', Format(Opt >= 1.0));
        Observer.Observe('B < 1.5', Format(Opt < 1.5));
        Observer.Observe('B < 1.0', Format(Opt < 1.0));
        Observer.Observe('B <= 0.9', Format(Opt <= 0.9));
        Observer.Observe('0.5 < B', Format(0.5 < Opt));
        Observer.Observe('1.0 = B', Format(1.0 = Opt));
        Item.Opt := Item.Opt::C;
        Observer.Observe('field C = 2.0', Format(Item.Opt = 2.0));
        Observer.Observe('field C > 1.5', Format(Item.Opt > 1.5));
        Observer.Observe('field C = 2.5', Format(Item.Opt = 2.5));
        Observer.Observe('field C < 2.5', Format(Item.Opt < 2.5));
        Observer.Finish();
    end;

    [Test]
    procedure OutStream_Write_OtherValueTypes_Bytes()
    var
        Observer: Codeunit "Probe Observer";
        C: Code[10];
        Opt: Option A,B,C;
        E: Enum "LT AJ Enum";
        DF: DateFormula;
        RId: RecordId;
        V: Variant;
        Bt: BigText;
        Cu: Record "LT AJ Item";
        Jo: JsonObject;
        Tmp: Codeunit "Temp Blob";
    begin
        C := 'ab';
        Observer.Observe('Code[10] ab', Dump(Tmp, 'Code', C));
        Opt := Opt::C;
        Observer.Observe('Option C', Dump(Tmp, 'Option', Opt));
        E := E::Seven;
        Observer.Observe('Enum Seven', Dump(Tmp, 'Enum', E.AsInteger()));
        Evaluate(DF, '<1M>');
        Observer.Observe('DateFormula 1M', Dump(Tmp, 'DateFormula', DF));
        Cu.Id := 5;
        RId := Cu.RecordId();
        Observer.Observe('RecordId', Dump(Tmp, 'RecordId', RId));
        Clear(RId);
        Observer.Observe('RecordId empty', Dump(Tmp, 'RecordId', RId));
        V := 42;
        Observer.Observe('Variant 42', Dump(Tmp, 'Variant', V));
        V := 'hi';
        Observer.Observe('Variant hi', Dump(Tmp, 'Variant', V));
        V := 1.5;
        Observer.Observe('Variant 1.5', Dump(Tmp, 'Variant', V));
        Clear(V);
        Observer.Observe('Variant empty', Dump(Tmp, 'Variant', V));
        Observer.Observe('Label', Dump(Tmp, 'Label', LabelValue));
        Bt.AddText('abc');
        Observer.Observe('BigText abc', Dump(Tmp, 'BigText', Bt));
        Cu.Id := 5;
        Cu.Txt := 'q';
        Observer.Observe('Record', Dump(Tmp, 'Record', Cu));
        Jo.ReadFrom('{"a":1}');
        Observer.Observe('JsonObject', Dump(Tmp, 'JsonObject', Jo));
        Observer.Finish();
    end;

    local procedure Dump(var Tmp: Codeunit "Temp Blob"; Kind: Text; Value: Variant): Text
    var
        Result: Text;
    begin
        Clear(Tmp);
        ClearLastError();
        if not TryWrite(Tmp, Kind, Value) then
            exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Result := Hex(Tmp);
        exit(Result);
    end;

    [TryFunction]
    local procedure TryWrite(var Tmp: Codeunit "Temp Blob"; Kind: Text; Value: Variant)
    var
        O: OutStream;
        C: Code[10];
        Opt: Option A,B,C;
        E: Enum "LT AJ Enum";
        DF: DateFormula;
        RId: RecordId;
        Bt: BigText;
        Cu: Record "LT AJ Item";
        Jo: JsonObject;
        Txt: Text;
        Ordinal: Integer;
    begin
        Tmp.CreateOutStream(O);
        case Kind of
            'Code':
                begin
                    C := Value;
                    O.Write(C);
                end;
            'Option':
                begin
                    Opt := Value;
                    O.Write(Opt);
                end;
            'Enum':
                begin
                    Ordinal := Value;
                    E := Enum::"LT AJ Enum".FromInteger(Ordinal);
                    O.Write(E);
                end;
            'DateFormula':
                begin
                    DF := Value;
                    O.Write(DF);
                end;
            'RecordId':
                begin
                    RId := Value;
                    O.Write(RId);
                end;
            'Variant':
                O.Write(Value);
            'Label':
                begin
                    Txt := Value;
                    O.Write(LabelValue);
                end;
            'BigText':
                begin
                    Bt := Value;
                    O.Write(Bt);
                end;
            'Record':
                begin
                    Cu := Value;
                    O.Write(Cu);
                end;
            'JsonObject':
                begin
                    Jo := Value;
                    O.Write(Jo);
                end;
        end;
    end;

    local procedure Hex(var Tmp: Codeunit "Temp Blob"): Text
    var
        I: InStream;
        B: Byte;
        Digits: Text;
        Result: Text;
        Count: Integer;
    begin
        Digits := '0123456789ABCDEF';
        Tmp.CreateInStream(I);
        while (not I.EOS()) and (Count < 200) do begin
            I.Read(B);
            Result += CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1) + ' ';
            Count += 1;
        end;
        exit(Format(Count) + ':' + Result);
    end;

    [Test]
    procedure FieldTable_RowVersionField_OwnTableAndCustomer()
    var
        Observer: Codeunit "Probe Observer";
        Fld: Record Field;
    begin
        Observer.Observe('own Get(0)', Describe(Fld, Database::"LT AJ Ts"));
        Observer.Observe('Customer Get(0)', Describe(Fld, Database::Customer));
        Fld.Reset();
        Fld.SetRange(TableNo, Database::"LT AJ Ts");
        Fld.SetRange("No.", 0);
        Observer.Observe('own filter count', Format(Fld.Count()));
        Fld.SetRange("No.");
        Observer.Observe('own all count', Format(Fld.Count()));
        Fld.FindFirst();
        Observer.Observe('own first no.', Format(Fld."No."));
        Fld.Reset();
        Fld.SetRange(TableNo, Database::Customer);
        Fld.SetRange("No.", 0);
        Observer.Observe('Customer filter count', Format(Fld.Count()));
        Fld.Reset();
        Fld.SetRange(TableNo, Database::Customer);
        Fld.SetRange(FieldName, 'timestamp');
        Observer.Observe('Customer by name count', Format(Fld.Count()));
        Fld.Reset();
        Fld.SetRange(TableNo, Database::Customer);
        Fld.FindFirst();
        Observer.Observe('Customer first no.', Format(Fld."No."));
        Observer.Finish();
    end;

    local procedure Describe(var Fld: Record Field; TableNumber: Integer): Text
    begin
        Clear(Fld);
        if not Fld.Get(TableNumber, 0) then
            exit('not found');
        exit(StrSubstNo('TableNo=%1|No=%2|Name=%3|Type=%4|Class=%5|Len=%6|Enabled=%7|Obsolete=%8|TypeName=%9|FieldCaption=%10', Fld.TableNo, Fld."No.", Fld.FieldName, Fld.Type, Fld.Class, Fld.Len, Fld.Enabled, Fld.ObsoleteState, Fld."Type Name", Fld."Field Caption"));
    end;
}
