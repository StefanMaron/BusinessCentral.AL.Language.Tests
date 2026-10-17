// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enum 74065, tables 74066 and 74067, test codeunit 74068
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TableRelation ... where(F = filter(A | "B C")): a filter() text with a double-quoted enum or option member that holds a space, on an enum field and an
//   option field of the related table, next to filter("B C"), const("B C"), filter(A | D) and filter(<> "B C"). (filter() on a Code or Text field with unquoted
//   or quoted values does not compile: AL0186.) Validate of the field with the code of a row whose
//   value is A, "B C", D, a prefix of "B C", an empty code and a code that does not exist: accepted or the related-table error.
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
        Obs.Finish();
    end;

    [Test]
    procedure Validate_ByOpt_QuotedFilter()
    begin
        ProbeField(3);
        Obs.Finish();
    end;

    [Test]
    procedure Validate_ByQuotedOnly_QuotedFilter()
    begin
        ProbeField(4);
        Obs.Finish();
    end;

    [Test]
    procedure Validate_ByPlain_QuotedFilter()
    begin
        ProbeField(5);
        Obs.Finish();
    end;

    [Test]
    procedure Validate_ByConst_QuotedFilter()
    begin
        ProbeField(6);
        Obs.Finish();
    end;

    [Test]
    procedure Validate_ByNot_QuotedFilter()
    begin
        ProbeField(7);
        Obs.Finish();
    end;
}
