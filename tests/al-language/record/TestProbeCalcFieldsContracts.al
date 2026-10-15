// Observe-only probes (writer A). Rows: CalcFields error layouts and codes, FlowField type mismatches, recursion,
// SetAutoCalcFields with Reset/Clear, SystemRowVersion min/max, BigInteger/Integer FlowFields.
table 69806 "PA Cf Src"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Amount; Decimal) { }
        field(4; Big; BigInteger) { }
        field(5; IntAmt; Integer) { }
        field(6; Txt; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 69807 "PA Cf Head"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Grp; Code[10]) { }
        field(2; Plain; Integer) { }
        field(10; SumAmt; Decimal) { FieldClass = FlowField; CalcFormula = sum("PA Cf Src".Amount where(Grp = field(Grp))); }
        field(11; CntSrc; Integer) { FieldClass = FlowField; CalcFormula = count("PA Cf Src" where(Grp = field(Grp))); }
        field(12; MinBig; BigInteger) { FieldClass = FlowField; CalcFormula = min("PA Cf Src".Big where(Grp = field(Grp))); }
        field(13; SumBigIntoInt; Integer) { FieldClass = FlowField; CalcFormula = sum("PA Cf Src".Big where(Grp = field(Grp))); }
        field(14; AvgIntIntoBig; BigInteger) { FieldClass = FlowField; CalcFormula = average("PA Cf Src".IntAmt where(Grp = field(Grp))); }
        field(15; LookupTxt; Text[20]) { FieldClass = FlowField; CalcFormula = lookup("PA Cf Src".Txt where(Id = field(Plain))); }
        field(16; ExistSrc; Boolean) { FieldClass = FlowField; CalcFormula = exist("PA Cf Src" where(Grp = field(Grp))); }
        field(17; MaxIntAmt; Integer) { FieldClass = FlowField; CalcFormula = max("PA Cf Src".IntAmt where(Grp = field(Grp))); }
        field(18; SumIntAmtIntoDec; Decimal) { FieldClass = FlowField; CalcFormula = sum("PA Cf Src".IntAmt where(Grp = field(Grp))); }
    }
    keys { key(PK; Grp) { Clustered = true; } }
}

codeunit 69812 "PA CalcFields Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        S: Record "PA Cf Src";
        H: Record "PA Cf Head";
    begin
        S.DeleteAll();
        H.DeleteAll();
        S.Id := 1;
        S.Grp := 'G';
        S.Amount := 10.5;
        Evaluate(S.Big, '5000000000');
        S.IntAmt := 4;
        S.Txt := 'one';
        S.Insert();
        S.Id := 2;
        S.Amount := 2;
        S.Big := 7;
        S.IntAmt := 7;
        S.Txt := 'two';
        S.Insert();
        H.Grp := 'G';
        H.Plain := 2;
        H.Insert();
    end;

    [Test]
    procedure CalcFields_OnNonFlowField()
    var
        O: Codeunit "Probe Observer";
        H: Record "PA Cf Head";
    begin
        Seed();
        H.Get('G');
        asserterror H.CalcFields(Plain);
        O.ObserveError('calcfields_on_normal_field');
        asserterror H.CalcFields(Grp);
        O.ObserveError('calcfields_on_key_field');
        O.Expect('calcfields_on_normal_field|text', 'The Plain field in the PA Cf Head table must be a FlowField.');
        O.Expect('calcfields_on_normal_field|code', 'DB:Ok');
        O.Expect('calcfields_on_key_field|text', 'The Grp field in the PA Cf Head table must be a FlowField.');
        O.Expect('calcfields_on_key_field|code', 'DB:Ok');
        O.Verify();
    end;

    [Test]
    procedure CalcFields_Values()
    var
        O: Codeunit "Probe Observer";
        H: Record "PA Cf Head";
    begin
        Seed();
        H.Get('G');
        H.CalcFields(SumAmt, CntSrc, ExistSrc, MaxIntAmt, LookupTxt);
        O.Observe('sum', Format(H.SumAmt));
        O.Observe('count', Format(H.CntSrc));
        O.Observe('exist', Format(H.ExistSrc));
        O.Observe('max_int', Format(H.MaxIntAmt));
        O.Observe('lookup_txt_plain_2', H.LookupTxt);
        O.Expect('sum', '12.5');
        O.Expect('count', '2');
        O.Expect('exist', 'Yes');
        O.Expect('max_int', '7');
        O.Expect('lookup_txt_plain_2', 'two');
        O.Verify();
    end;

    [Test]
    procedure CalcFields_BigIntegerIntoInteger()
    var
        O: Codeunit "Probe Observer";
        H: Record "PA Cf Head";
    begin
        Seed();
        H.Get('G');
        O.Observe('sum_big_into_int', TryCalc(H, 13));
        O.Observe('avg_int_into_big', TryCalc(H, 14));
        O.Observe('min_big', TryCalc(H, 12));
        O.Expect('sum_big_into_int', 'ERR:The following fields must have the same type:\r\\r\Field: SumBigIntoInt <-- Big\r\Table: PA Cf Head <-- PA Cf Src\r\Type: Integer <-- BigInteger/DB:TypeMisMatch');
        O.Expect('avg_int_into_big', 'ERR:The following fields must have the same type:\r\\r\Field: AvgIntIntoBig <-- IntAmt\r\Table: PA Cf Head <-- PA Cf Src\r\Type: BigInteger <-- Integer/DB:TypeMisMatch');
        O.Expect('min_big', '7');
        O.Verify();
    end;

    local procedure TryCalc(var H: Record "PA Cf Head"; No: Integer): Text
    var
        Res: Text;
    begin
        if TryCalcF(H, No, Res) then
            exit(Res);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryCalcF(var H: Record "PA Cf Head"; No: Integer; var Res: Text)
    begin
        case No of
            12:
                begin
                    H.CalcFields(MinBig);
                    Res := Format(H.MinBig);
                end;
            13:
                begin
                    H.CalcFields(SumBigIntoInt);
                    Res := Format(H.SumBigIntoInt);
                end;
            14:
                begin
                    H.CalcFields(AvgIntIntoBig);
                    Res := Format(H.AvgIntIntoBig);
                end;
        end;
    end;

    [Test]
    procedure CalcFields_ErrorCodeEmpty()
    var
        O: Codeunit "Probe Observer";
        H: Record "PA Cf Head";
    begin
        Seed();
        H.Get('G');
        asserterror H.CalcFields(Plain);
        O.Observe('code_is_empty', Format(GetLastErrorCode() = ''));
        O.Observe('code', '[' + GetLastErrorCode() + ']');
        O.Observe('text', GetLastErrorText());
        O.Expect('code_is_empty', 'No');
        O.Expect('code', '[DB:Ok]');
        O.Expect('text', 'The Plain field in the PA Cf Head table must be a FlowField.');
        O.Verify();
    end;

    [Test]
    procedure SetAutoCalcFields_ThenResetAndClear()
    var
        O: Codeunit "Probe Observer";
        H: Record "PA Cf Head";
    begin
        Seed();
        H.SetAutoCalcFields(SumAmt);
        H.Get('G');
        O.Observe('get_with_auto', Format(H.SumAmt));
        Clear(H);
        H.Get('G');
        O.Observe('get_after_clear', Format(H.SumAmt));
        H.SetAutoCalcFields(SumAmt);
        H.Reset();
        H.Get('G');
        O.Observe('get_after_reset', Format(H.SumAmt));
        H.SetAutoCalcFields(SumAmt);
        H.SetAutoCalcFields();
        H.Get('G');
        O.Observe('get_after_setautocalcfields_empty', Format(H.SumAmt));
        H.SetAutoCalcFields(SumAmt);
        H.FindFirst();
        O.Observe('findfirst_with_auto', Format(H.SumAmt));
        H.Reset();
        H.FindFirst();
        O.Observe('findfirst_after_reset', Format(H.SumAmt));
        O.Expect('get_with_auto', '12.5');
        O.Expect('get_after_clear', '12.5');
        O.Expect('get_after_reset', '12.5');
        O.Expect('get_after_setautocalcfields_empty', '0');
        O.Expect('findfirst_with_auto', '12.5');
        O.Expect('findfirst_after_reset', '12.5');
        O.Verify();
    end;

    [Test]
    procedure CalcFields_RecordFormatIncludesFlowFieldsLast()
    var
        O: Codeunit "Probe Observer";
        H: Record "PA Cf Head";
        Tb: Text;
    begin
        Seed();
        H.Get('G');
        H.CalcFields(SumAmt, CntSrc);
        Tb[1] := 9;
        O.Observe('format_record', Format(H).Replace(Tb, '<TAB>'));
        O.Expect('format_record', 'G<TAB>2<TAB>12.5<TAB>2<TAB>0<TAB>0<TAB>0<TAB><TAB>No<TAB>0<TAB>0');
        O.Verify();
    end;

    [Test]
    procedure CalcFields_MissingSource_EmptyResults()
    var
        O: Codeunit "Probe Observer";
        H: Record "PA Cf Head";
    begin
        Seed();
        H.Grp := 'NONE';
        H.Plain := 99;
        H.Insert();
        H.CalcFields(SumAmt, CntSrc, ExistSrc, MaxIntAmt, LookupTxt, MinBig);
        O.Observe('sum', Format(H.SumAmt));
        O.Observe('count', Format(H.CntSrc));
        O.Observe('exist', Format(H.ExistSrc));
        O.Observe('max', Format(H.MaxIntAmt));
        O.Observe('lookup', '[' + H.LookupTxt + ']');
        O.Observe('minbig', Format(H.MinBig));
        O.Expect('sum', '0');
        O.Expect('count', '0');
        O.Expect('exist', 'No');
        O.Expect('max', '0');
        O.Expect('lookup', '[]');
        O.Expect('minbig', '0');
        O.Verify();
    end;
}
