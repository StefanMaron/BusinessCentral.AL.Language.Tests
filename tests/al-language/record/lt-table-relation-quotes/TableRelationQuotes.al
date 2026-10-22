// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enum 74065, tables 74066 and 74067, test codeunit 74068
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TableRelation ... where(F = filter(A | "B C")): a filter() text with a double-quoted enum or option member that holds a space, on an enum field and an
//   option field of the related table, next to filter("B C"), const("B C"), filter(A | D) and filter(<> "B C"). (filter() on a Code or Text field with unquoted
//   or quoted values does not compile: AL0186.) Validate of the field with the code of a row whose
//   value is A, "B C", D, a prefix of "B C", an empty code and a code that does not exist: accepted or the related-table error.
// Writer QO (al-runtime-rs assumption table-relation-quotes): the quoted member "B C" inside a range and an & of filter(): filter(A.."B C"),
//   filter("B C"..D), filter("B C"..), filter(<> A & <> "B C") on the enum field and filter(A.."B C"), filter("B C"..D),
//   filter(<> "B C" & <> D) on the option field (own table 87082, QO_ tests in codeunit 74068). Validate with each seeded code, an empty
//   code and a missing one: accepted, or the error text and code.
// Writer QP (al-runtime-rs ask): quoted members in the CONDITIONS of TableRelation arms (own tables 87155-87157, QP_ tests in codeunit
//   74068). Field Arms: if (Type = const("B C")) T1 else if (Type = filter(<> "B C" & <> D)) T2; field BlankOr: if (Type = filter(" " | A))
//   T1 else T2. Type is an Option " ",A,"B C",D. Validate with a code of T1, a code of T2, an empty code and a missing code for every Type:
//   accepted, or the error text and code.
// BC versions: 27, 28, 29 by CI

enum 74065 "LT TQ Kind"
{
    Extensible = false;

    value(0; A) { }
    value(1; "B C") { }
    value(2; D) { }
}

table 74066 "LT TQ Ref"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Kind; Enum "LT TQ Kind") { }
        field(3; Opt; Option) { OptionMembers = A,"B C",D; }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 74067 "LT TQ Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; "By Kind"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Kind = filter(A | "B C")); }
        field(3; "By Opt"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Opt = filter(A | "B C")); }
        field(4; "By Quoted Only"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Kind = filter("B C")); }
        field(5; "By Plain"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Kind = filter(A | D)); }
        field(6; "By Const"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Kind = const("B C")); }
        field(7; "By Not"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Kind = filter(<> "B C")); }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 87082 "LT QO TQ Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; "Kind Range AB"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Kind = filter(A .. "B C")); }
        field(3; "Kind Range BD"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Kind = filter("B C" .. D)); }
        field(4; "Kind And"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Kind = filter(<> A & <> "B C")); }
        field(5; "Opt Range AB"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Opt = filter(A .. "B C")); }
        field(6; "Opt Range BD"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Opt = filter("B C" .. D)); }
        field(7; "Opt And"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Opt = filter(<> "B C" & <> D)); }
        field(8; "Kind Open"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Kind = filter("B C" ..)); }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 87155 "LT QP TQ T1"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 87156 "LT QP TQ T2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 87157 "LT QP TQ Arm Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Type; Option) { OptionMembers = " ",A,"B C",D; }
        field(3; Arms; Code[10])
        {
            TableRelation = if (Type = const("B C")) "LT QP TQ T1"."Code"
            else if (Type = filter(<> "B C" & <> D)) "LT QP TQ T2"."Code";
        }
        field(4; BlankOr; Code[10])
        {
            TableRelation = if (Type = filter(" " | A)) "LT QP TQ T1"."Code"
            else "LT QP TQ T2"."Code";
        }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 74068 "LT Table Relation Quotes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure Seed()
    var
        R: Record "LT TQ Ref";
    begin
        R.DeleteAll();
        AddRef('R1', "LT TQ Kind"::A, 0);
        AddRef('R2', "LT TQ Kind"::"B C", 1);
        AddRef('R3', "LT TQ Kind"::D, 2);
        AddRef('R4', "LT TQ Kind"::A, 2);
        AddRef('R5', "LT TQ Kind"::D, 0);
    end;

    local procedure AddRef(Code: Code[10]; Kind: Enum "LT TQ Kind"; Opt: Option A,"B C",D)
    var
        R: Record "LT TQ Ref";
    begin
        R.Code := Code;
        R.Kind := Kind;
        R.Opt := Opt;
        R.Insert();
    end;

    [TryFunction]
    local procedure TryValidate(FieldNo: Integer; Value: Text)
    var
        S: Record "LT TQ Src";
    begin
        case FieldNo of
            2:
                S.Validate("By Kind", CopyStr(Value, 1, 10));
            3:
                S.Validate("By Opt", CopyStr(Value, 1, 10));
            4:
                S.Validate("By Quoted Only", CopyStr(Value, 1, 10));
            5:
                S.Validate("By Plain", CopyStr(Value, 1, 10));
            6:
                S.Validate("By Const", CopyStr(Value, 1, 10));
            7:
                S.Validate("By Not", CopyStr(Value, 1, 10));
        end;
    end;

    local procedure ProbeField(FieldNo: Integer)
    var
        Codes: List of [Text];
        C: Text;
    begin
        Seed();
        Codes.Add('R1');
        Codes.Add('R2');
        Codes.Add('R3');
        Codes.Add('R4');
        Codes.Add('R5');
        Codes.Add('');
        Codes.Add('NOPE');
        foreach C in Codes do
            if TryValidate(FieldNo, C) then
                Obs.Observe('v_' + C, 'ok')
            else begin
                Obs.Observe('v_' + C, GetLastErrorText());
                ClearLastError();
            end;
    end;

    [Test]
    procedure Validate_ByKind_QuotedFilter()
    begin
        ProbeField(2);
        Obs.Expect('v_R1', 'ok');
        Obs.Expect('v_R2', 'ok');
        Obs.Expect('v_R3', 'The field By Kind of table LT TQ Src contains a value (R3) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R4', 'ok');
        Obs.Expect('v_R5', 'The field By Kind of table LT TQ Src contains a value (R5) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE', 'The field By Kind of table LT TQ Src contains a value (NOPE) that cannot be found in the related table (LT TQ Ref).');
        Obs.Verify();
    end;

    [Test]
    procedure Validate_ByOpt_QuotedFilter()
    begin
        ProbeField(3);
        Obs.Expect('v_R1', 'ok');
        Obs.Expect('v_R2', 'ok');
        Obs.Expect('v_R3', 'The field By Opt of table LT TQ Src contains a value (R3) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R4', 'The field By Opt of table LT TQ Src contains a value (R4) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R5', 'ok');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE', 'The field By Opt of table LT TQ Src contains a value (NOPE) that cannot be found in the related table (LT TQ Ref).');
        Obs.Verify();
    end;

    [Test]
    procedure Validate_ByQuotedOnly_QuotedFilter()
    begin
        ProbeField(4);
        Obs.Expect('v_R1', 'The field By Quoted Only of table LT TQ Src contains a value (R1) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R2', 'ok');
        Obs.Expect('v_R3', 'The field By Quoted Only of table LT TQ Src contains a value (R3) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R4', 'The field By Quoted Only of table LT TQ Src contains a value (R4) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R5', 'The field By Quoted Only of table LT TQ Src contains a value (R5) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE', 'The field By Quoted Only of table LT TQ Src contains a value (NOPE) that cannot be found in the related table (LT TQ Ref).');
        Obs.Verify();
    end;

    [Test]
    procedure Validate_ByPlain_QuotedFilter()
    begin
        ProbeField(5);
        Obs.Expect('v_R1', 'ok');
        Obs.Expect('v_R2', 'The field By Plain of table LT TQ Src contains a value (R2) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R3', 'ok');
        Obs.Expect('v_R4', 'ok');
        Obs.Expect('v_R5', 'ok');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE', 'The field By Plain of table LT TQ Src contains a value (NOPE) that cannot be found in the related table (LT TQ Ref).');
        Obs.Verify();
    end;

    [Test]
    procedure Validate_ByConst_QuotedFilter()
    begin
        ProbeField(6);
        Obs.Expect('v_R1', 'The field By Const of table LT TQ Src contains a value (R1) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R2', 'ok');
        Obs.Expect('v_R3', 'The field By Const of table LT TQ Src contains a value (R3) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R4', 'The field By Const of table LT TQ Src contains a value (R4) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R5', 'The field By Const of table LT TQ Src contains a value (R5) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE', 'The field By Const of table LT TQ Src contains a value (NOPE) that cannot be found in the related table (LT TQ Ref).');
        Obs.Verify();
    end;

    [Test]
    procedure Validate_ByNot_QuotedFilter()
    begin
        ProbeField(7);
        Obs.Expect('v_R1', 'ok');
        Obs.Expect('v_R2', 'The field By Not of table LT TQ Src contains a value (R2) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R3', 'ok');
        Obs.Expect('v_R4', 'ok');
        Obs.Expect('v_R5', 'ok');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE', 'The field By Not of table LT TQ Src contains a value (NOPE) that cannot be found in the related table (LT TQ Ref).');
        Obs.Verify();
    end;

    // Writer QO: Validate of a field of table 87082 (FieldNo 2-8) with each code.
    [TryFunction]
    local procedure QoTryValidate(FieldNo: Integer; Value: Text)
    var
        S: Record "LT QO TQ Src";
        V: Code[10];
    begin
        V := CopyStr(Value, 1, 10);
        case FieldNo of
            2:
                S.Validate("Kind Range AB", V);
            3:
                S.Validate("Kind Range BD", V);
            4:
                S.Validate("Kind And", V);
            5:
                S.Validate("Opt Range AB", V);
            6:
                S.Validate("Opt Range BD", V);
            7:
                S.Validate("Opt And", V);
            8:
                S.Validate("Kind Open", V);
        end;
    end;

    local procedure QoProbeField(FieldNo: Integer)
    var
        Codes: List of [Text];
        C: Text;
    begin
        Seed();
        Codes.Add('R1');
        Codes.Add('R2');
        Codes.Add('R3');
        Codes.Add('R4');
        Codes.Add('R5');
        Codes.Add('');
        Codes.Add('NOPE');
        foreach C in Codes do
            if QoTryValidate(FieldNo, C) then
                Obs.Observe('v_' + C, 'ok')
            else
                Obs.ObserveError('v_' + C);
    end;

    [Test]
    procedure QO_Validate_KindRange_QuotedUpper()
    begin
        QoProbeField(2);
        Obs.Expect('v_R1', 'ok');
        Obs.Expect('v_R2', 'ok');
        Obs.Expect('v_R3|text', 'The field Kind Range AB of table LT QO TQ Src contains a value (R3) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R3|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_R4', 'ok');
        Obs.Expect('v_R5|text', 'The field Kind Range AB of table LT QO TQ Src contains a value (R5) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R5|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE|text', 'The field Kind Range AB of table LT QO TQ Src contains a value (NOPE) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_NOPE|code', 'DB:NothingInsideFilter');
        Obs.Verify();
    end;

    [Test]
    procedure QO_Validate_KindRange_QuotedLower()
    begin
        QoProbeField(3);
        Obs.Expect('v_R1|text', 'The field Kind Range BD of table LT QO TQ Src contains a value (R1) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R1|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_R2', 'ok');
        Obs.Expect('v_R3', 'ok');
        Obs.Expect('v_R4|text', 'The field Kind Range BD of table LT QO TQ Src contains a value (R4) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R4|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_R5', 'ok');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE|text', 'The field Kind Range BD of table LT QO TQ Src contains a value (NOPE) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_NOPE|code', 'DB:NothingInsideFilter');
        Obs.Verify();
    end;

    [Test]
    procedure QO_Validate_KindAnd_Quoted()
    begin
        QoProbeField(4);
        Obs.Expect('v_R1|text', 'The field Kind And of table LT QO TQ Src contains a value (R1) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R1|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_R2|text', 'The field Kind And of table LT QO TQ Src contains a value (R2) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R2|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_R3', 'ok');
        Obs.Expect('v_R4|text', 'The field Kind And of table LT QO TQ Src contains a value (R4) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R4|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_R5', 'ok');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE|text', 'The field Kind And of table LT QO TQ Src contains a value (NOPE) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_NOPE|code', 'DB:NothingInsideFilter');
        Obs.Verify();
    end;

    [Test]
    procedure QO_Validate_OptRange_QuotedUpper()
    begin
        QoProbeField(5);
        Obs.Expect('v_R1', 'ok');
        Obs.Expect('v_R2', 'ok');
        Obs.Expect('v_R3|text', 'The field Opt Range AB of table LT QO TQ Src contains a value (R3) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R3|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_R4|text', 'The field Opt Range AB of table LT QO TQ Src contains a value (R4) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R4|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_R5', 'ok');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE|text', 'The field Opt Range AB of table LT QO TQ Src contains a value (NOPE) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_NOPE|code', 'DB:NothingInsideFilter');
        Obs.Verify();
    end;

    [Test]
    procedure QO_Validate_OptRange_QuotedLower()
    begin
        QoProbeField(6);
        Obs.Expect('v_R1|text', 'The field Opt Range BD of table LT QO TQ Src contains a value (R1) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R1|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_R2', 'ok');
        Obs.Expect('v_R3', 'ok');
        Obs.Expect('v_R4', 'ok');
        Obs.Expect('v_R5|text', 'The field Opt Range BD of table LT QO TQ Src contains a value (R5) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R5|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE|text', 'The field Opt Range BD of table LT QO TQ Src contains a value (NOPE) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_NOPE|code', 'DB:NothingInsideFilter');
        Obs.Verify();
    end;

    [Test]
    procedure QO_Validate_OptAnd_Quoted()
    begin
        QoProbeField(7);
        Obs.Expect('v_R1', 'ok');
        Obs.Expect('v_R2|text', 'The field Opt And of table LT QO TQ Src contains a value (R2) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R2|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_R3|text', 'The field Opt And of table LT QO TQ Src contains a value (R3) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R3|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_R4|text', 'The field Opt And of table LT QO TQ Src contains a value (R4) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R4|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_R5', 'ok');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE|text', 'The field Opt And of table LT QO TQ Src contains a value (NOPE) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_NOPE|code', 'DB:NothingInsideFilter');
        Obs.Verify();
    end;

    [Test]
    procedure QO_Validate_KindOpenRange_Quoted()
    begin
        QoProbeField(8);
        Obs.Expect('v_R1|text', 'The field Kind Open of table LT QO TQ Src contains a value (R1) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R1|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_R2', 'ok');
        Obs.Expect('v_R3', 'ok');
        Obs.Expect('v_R4|text', 'The field Kind Open of table LT QO TQ Src contains a value (R4) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_R4|code', 'DB:NothingInsideFilter');
        Obs.Expect('v_R5', 'ok');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE|text', 'The field Kind Open of table LT QO TQ Src contains a value (NOPE) that cannot be found in the related table (LT TQ Ref).');
        Obs.Expect('v_NOPE|code', 'DB:NothingInsideFilter');
        Obs.Verify();
    end;

    local procedure QpSeedArms()
    var
        A: Record "LT QP TQ T1";
        B: Record "LT QP TQ T2";
    begin
        A.DeleteAll();
        B.DeleteAll();
        A.Code := 'X1';
        A.Insert();
        B.Code := 'Y1';
        B.Insert();
    end;

    [TryFunction]
    local procedure QpTryValidateArm(FieldNo: Integer; TypeValue: Integer; Value: Text)
    var
        S: Record "LT QP TQ Arm Src";
    begin
        S.Type := TypeValue;
        case FieldNo of
            3:
                S.Validate(Arms, CopyStr(Value, 1, 10));
            4:
                S.Validate(BlankOr, CopyStr(Value, 1, 10));
        end;
    end;

    local procedure QpProbeArms(FieldNo: Integer; TypeValue: Integer)
    var
        Codes: List of [Text];
        C: Text;
    begin
        QpSeedArms();
        Codes.Add('X1');
        Codes.Add('Y1');
        Codes.Add('');
        Codes.Add('NOPE');
        foreach C in Codes do begin
            ClearLastError();
            if QpTryValidateArm(FieldNo, TypeValue, C) then
                Obs.Observe('v_' + C, 'ok')
            else
                Obs.ObserveError('v_' + C);
        end;
    end;

    [Test]
    procedure QP_Arms_TypeBlank()
    begin
        QpProbeArms(3, 0);
        Obs.Expect('v_X1|text', 'The field Arms of table LT QP TQ Arm Src contains a value (X1) that cannot be found in the related table (LT QP TQ T2).');
        Obs.Expect('v_X1|code', 'DB:PrimRecordNotFound');
        Obs.Expect('v_Y1', 'ok');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE|text', 'The field Arms of table LT QP TQ Arm Src contains a value (NOPE) that cannot be found in the related table (LT QP TQ T2).');
        Obs.Expect('v_NOPE|code', 'DB:PrimRecordNotFound');
        Obs.Verify();
    end;

    [Test]
    procedure QP_Arms_TypeA()
    begin
        QpProbeArms(3, 1);
        Obs.Expect('v_X1|text', 'The field Arms of table LT QP TQ Arm Src contains a value (X1) that cannot be found in the related table (LT QP TQ T2).');
        Obs.Expect('v_X1|code', 'DB:PrimRecordNotFound');
        Obs.Expect('v_Y1', 'ok');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE|text', 'The field Arms of table LT QP TQ Arm Src contains a value (NOPE) that cannot be found in the related table (LT QP TQ T2).');
        Obs.Expect('v_NOPE|code', 'DB:PrimRecordNotFound');
        Obs.Verify();
    end;

    [Test]
    procedure QP_Arms_TypeBC()
    begin
        QpProbeArms(3, 2);
        Obs.Expect('v_X1', 'ok');
        Obs.Expect('v_Y1|text', 'The field Arms of table LT QP TQ Arm Src contains a value (Y1) that cannot be found in the related table (LT QP TQ T1).');
        Obs.Expect('v_Y1|code', 'DB:PrimRecordNotFound');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE|text', 'The field Arms of table LT QP TQ Arm Src contains a value (NOPE) that cannot be found in the related table (LT QP TQ T1).');
        Obs.Expect('v_NOPE|code', 'DB:PrimRecordNotFound');
        Obs.Verify();
    end;

    [Test]
    procedure QP_Arms_TypeD()
    begin
        QpProbeArms(3, 3);
        Obs.Expect('v_X1', 'ok');
        Obs.Expect('v_Y1', 'ok');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE', 'ok');
        Obs.Verify();
    end;

    [Test]
    procedure QP_BlankOr_TypeBlank()
    begin
        QpProbeArms(4, 0);
        Obs.Expect('v_X1', 'ok');
        Obs.Expect('v_Y1|text', 'The field BlankOr of table LT QP TQ Arm Src contains a value (Y1) that cannot be found in the related table (LT QP TQ T1).');
        Obs.Expect('v_Y1|code', 'DB:PrimRecordNotFound');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE|text', 'The field BlankOr of table LT QP TQ Arm Src contains a value (NOPE) that cannot be found in the related table (LT QP TQ T1).');
        Obs.Expect('v_NOPE|code', 'DB:PrimRecordNotFound');
        Obs.Verify();
    end;

    [Test]
    procedure QP_BlankOr_TypeA()
    begin
        QpProbeArms(4, 1);
        Obs.Expect('v_X1', 'ok');
        Obs.Expect('v_Y1|text', 'The field BlankOr of table LT QP TQ Arm Src contains a value (Y1) that cannot be found in the related table (LT QP TQ T1).');
        Obs.Expect('v_Y1|code', 'DB:PrimRecordNotFound');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE|text', 'The field BlankOr of table LT QP TQ Arm Src contains a value (NOPE) that cannot be found in the related table (LT QP TQ T1).');
        Obs.Expect('v_NOPE|code', 'DB:PrimRecordNotFound');
        Obs.Verify();
    end;

    [Test]
    procedure QP_BlankOr_TypeBC()
    begin
        QpProbeArms(4, 2);
        Obs.Expect('v_X1|text', 'The field BlankOr of table LT QP TQ Arm Src contains a value (X1) that cannot be found in the related table (LT QP TQ T2).');
        Obs.Expect('v_X1|code', 'DB:PrimRecordNotFound');
        Obs.Expect('v_Y1', 'ok');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE|text', 'The field BlankOr of table LT QP TQ Arm Src contains a value (NOPE) that cannot be found in the related table (LT QP TQ T2).');
        Obs.Expect('v_NOPE|code', 'DB:PrimRecordNotFound');
        Obs.Verify();
    end;

    [Test]
    procedure QP_BlankOr_TypeD()
    begin
        QpProbeArms(4, 3);
        Obs.Expect('v_X1|text', 'The field BlankOr of table LT QP TQ Arm Src contains a value (X1) that cannot be found in the related table (LT QP TQ T2).');
        Obs.Expect('v_X1|code', 'DB:PrimRecordNotFound');
        Obs.Expect('v_Y1', 'ok');
        Obs.Expect('v_', 'ok');
        Obs.Expect('v_NOPE|text', 'The field BlankOr of table LT QP TQ Arm Src contains a value (NOPE) that cannot be found in the related table (LT QP TQ T2).');
        Obs.Expect('v_NOPE|code', 'DB:PrimRecordNotFound');
        Obs.Verify();
    end;
}
