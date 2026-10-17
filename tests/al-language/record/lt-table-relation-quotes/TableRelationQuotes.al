// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enum 74065, tables 74066 and 74067, test codeunit 74068
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TableRelation ... where(F = filter(A | "B C")): a filter() text with a double-quoted identifier that holds a space, on an enum field, a Code field and
//   a Text field of the related table, next to filter(A | 'B C'), const('B C') and filter(A | D). Validate of the field with the code of a row whose
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
        field(3; Tag; Code[10]) { }
        field(4; Txt; Text[20]) { }
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
        field(3; "By Tag"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Tag = filter(A | "B C")); }
        field(4; "By Txt"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Txt = filter(A | "B C")); }
        field(5; "By Single"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Tag = filter(A | 'B C')); }
        field(6; "By Const"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Tag = const('B C')); }
        field(7; "By Plain"; Code[10]) { TableRelation = "LT TQ Ref"."Code" where (Tag = filter(A | D)); }
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
        AddRef('R1', "LT TQ Kind"::A, 'A', 'A');
        AddRef('R2', "LT TQ Kind"::"B C", 'B C', 'B C');
        AddRef('R3', "LT TQ Kind"::D, 'D', 'D');
        AddRef('R5', "LT TQ Kind"::A, 'B', 'B');
    end;

    local procedure AddRef(Code: Code[10]; Kind: Enum "LT TQ Kind"; Tag: Code[10]; Txt: Text[20])
    var
        R: Record "LT TQ Ref";
    begin
        R.Code := Code;
        R.Kind := Kind;
        R.Tag := Tag;
        R.Txt := Txt;
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
                S.Validate("By Tag", CopyStr(Value, 1, 10));
            4:
                S.Validate("By Txt", CopyStr(Value, 1, 10));
            5:
                S.Validate("By Single", CopyStr(Value, 1, 10));
            6:
                S.Validate("By Const", CopyStr(Value, 1, 10));
            7:
                S.Validate("By Plain", CopyStr(Value, 1, 10));
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
    procedure Validate_ByTag_QuotedFilter()
    begin
        ProbeField(3);
        Obs.Finish();
    end;

    [Test]
    procedure Validate_ByTxt_QuotedFilter()
    begin
        ProbeField(4);
        Obs.Finish();
    end;

    [Test]
    procedure Validate_BySingle_QuotedFilter()
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
    procedure Validate_ByPlain_QuotedFilter()
    begin
        ProbeField(7);
        Obs.Finish();
    end;
}
