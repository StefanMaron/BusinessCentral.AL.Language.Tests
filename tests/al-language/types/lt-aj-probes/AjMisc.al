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
        Observer: Codeunit "Probe Observer";
        LabelValue: Label 'Lbl', Locked = true;

    [Test]
    procedure Guid_TextConcatenationAndMaxStrLen()
    var
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
    procedure OutStream_Write_Code_Option_Enum_DateFormula()
    var
        C: Code[10];
        Opt: Option A,B,C;
        E: Enum "LT AJ Enum";
        DF: DateFormula;
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
        Observer.Finish();
    end;

    [Test]
    procedure OutStream_Write_RecordId_And_Label()
    var
        RId: RecordId;
        Cu: Record "LT AJ Item";
        Tmp: Codeunit "Temp Blob";
    begin
        Cu.Id := 5;
        RId := Cu.RecordId();
        Observer.Observe('RecordId', Dump(Tmp, 'RecordId', RId));
        Clear(RId);
        Observer.Observe('RecordId empty', Dump(Tmp, 'RecordId', RId));
        Observer.Observe('Label', Dump(Tmp, 'Label', LabelValue));
        Observer.Finish();
    end;

    [Test]
    procedure OutStream_Write_Variant()
    var
        V: Variant;
        Tmp: Codeunit "Temp Blob";
    begin
        V := 42;
        Observer.Observe('Variant 42', Dump(Tmp, 'Variant', V));
        V := 'hi';
        Observer.Observe('Variant hi', Dump(Tmp, 'Variant', V));
        V := 1.5;
        Observer.Observe('Variant 1.5', Dump(Tmp, 'Variant', V));
        V := true;
        Observer.Observe('Variant true', Dump(Tmp, 'Variant', V));
        Clear(V);
        Observer.Observe('Variant empty', Dump(Tmp, 'Variant', V));
        Observer.Finish();
    end;

    [Test]
    procedure OutStream_Write_BigText_Record_JsonObject()
    var
        Bt: BigText;
        Cu: Record "LT AJ Item";
        Jo: JsonObject;
        Tmp: Codeunit "Temp Blob";
    begin
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
    procedure FieldTable_OwnTable_AllRows()
    begin
        Observer.Observe('Get(0)', Describe(Database::"LT AJ Ts", 0));
        Observer.Observe('rows', ListRows(Database::"LT AJ Ts", ''));
        Observer.Finish();
    end;

    [Test]
    procedure FieldTable_Customer_RowVersionField()
    var
        Fld: Record Field;
    begin
        Observer.Observe('Get(0)', Describe(Database::Customer, 0));
        Observer.Observe('by name timestamp', ListRows(Database::Customer, 'timestamp'));
        Fld.SetRange(TableNo, Database::Customer);
        Fld.SetRange("No.", 0);
        Observer.Observe('No. = 0 count', Format(Fld.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure FieldTable_Customer_FirstRows()
    var
        Fld: Record Field;
        Seen: Text;
        Index: Integer;
    begin
        Fld.SetRange(TableNo, Database::Customer);
        Fld.SetCurrentKey(TableNo, "No.");
        if Fld.FindSet() then
            repeat
                Index += 1;
                if Index <= 3 then
                    Seen += Format(Fld."No.") + ':' + Fld.FieldName + ';';
            until Fld.Next() = 0;
        Observer.Observe('first three', Seen);
        Observer.Finish();
    end;

    local procedure ListRows(TableNumber: Integer; NameFilter: Text): Text
    var
        Fld: Record Field;
        Result: Text;
    begin
        Fld.SetRange(TableNo, TableNumber);
        if NameFilter <> '' then
            Fld.SetRange(FieldName, NameFilter);
        if Fld.FindSet() then
            repeat
                Result += Format(Fld."No.") + ':' + Fld.FieldName + ':' + Format(Fld.Type) + ':' + Format(Fld.Class) + ':' + Format(Fld.Len) + ';';
            until Fld.Next() = 0;
        exit(Result);
    end;

    local procedure Describe(TableNumber: Integer; FieldNumber: Integer): Text
    var
        Fld: Record Field;
    begin
        if not Fld.Get(TableNumber, FieldNumber) then
            exit('not found');
        exit(StrSubstNo('TableNo=%1|No=%2|Name=%3|Type=%4|Class=%5|Len=%6|Enabled=%7|Obsolete=%8', Fld.TableNo, Fld."No.", Fld.FieldName, Fld.Type, Fld.Class, Fld.Len, Fld.Enabled, Fld.ObsoleteState));
    end;
}
