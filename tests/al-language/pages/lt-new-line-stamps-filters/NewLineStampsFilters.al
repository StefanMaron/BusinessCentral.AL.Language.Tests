// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enum 74135, tables 74136 and 74137, pages 74138 to 74140, test codeunit 74141
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a list part with SourceTableView where(Type = const(B)) and SubPageLink "Document No." = field("No."). The link field is declared before Type,
//   its TableRelation filters the header on Type (where(Type = field(Type))), and its OnValidate stores the Type it sees in Seen.
//   What the blank line of the part holds after New() (before typing), and what the stored line holds after a field is typed, for an existing
//   header (OpenEdit) and a new header (OpenNew). A second part without SourceTableView is the contrast.
// BC versions: 27, 28, 29 by CI

enum 74135 "LT NL Type"
{
    Extensible = false;

    value(0; A) { }
    value(1; B) { }
}

table 74136 "LT NL Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Type; Enum "LT NL Type") { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 74137 "LT NL Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document No."; Code[10])
        {
            TableRelation = "LT NL Header"."No." where (Type = field(Type));

            trigger OnValidate()
            begin
                Seen := Format(Type);
            end;
        }
        field(2; "Line No."; Integer) { }
        field(3; Type; Enum "LT NL Type") { }
        field(4; Seen; Text[20]) { }
        field(5; Descr; Text[30]) { }
    }

    keys { key(PK; "Document No.", "Line No.") { Clustered = true; } }
}

page 74138 "LT NL Lines B"
{
    PageType = ListPart;
    SourceTable = "LT NL Line";
    SourceTableView = where(Type = const(B));
    AutoSplitKey = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field(Type; Rec.Type) { ApplicationArea = All; }
                field(Seen; Rec.Seen) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 74139 "LT NL Lines Plain"
{
    PageType = ListPart;
    SourceTable = "LT NL Line";
    AutoSplitKey = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field(Type; Rec.Type) { ApplicationArea = All; }
                field(Seen; Rec.Seen) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 74140 "LT NL Host"
{
    PageType = Card;
    SourceTable = "LT NL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Type; Rec.Type) { ApplicationArea = All; }
            part(LinesB; "LT NL Lines B")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
            part(LinesPlain; "LT NL Lines Plain")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}

codeunit 74141 "LT New Line Stamps Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure Seed(HeaderNo: Code[10]; HeaderType: Enum "LT NL Type")
    var
        H: Record "LT NL Header";
        L: Record "LT NL Line";
    begin
        L.DeleteAll();
        H.DeleteAll();
        if HeaderNo = '' then
            exit;
        H."No." := HeaderNo;
        H.Type := HeaderType;
        H.Insert();
    end;

    local procedure ObserveLines(Prefix: Text)
    var
        L: Record "LT NL Line";
    begin
        Obs.Observe(Prefix + '.count', Format(L.Count()));
        if L.FindFirst() then
            Obs.Observe(Prefix + '.first', L."Document No." + '|' + Format(L.Type) + '|' + L.Seen + '|' + L.Descr);
    end;

    [TryFunction]
    local procedure TryNewB(var Host: TestPage "LT NL Host")
    begin
        Host.LinesB.New();
    end;

    [TryFunction]
    local procedure TryNewPlain(var Host: TestPage "LT NL Host")
    begin
        Host.LinesPlain.New();
    end;

    [TryFunction]
    local procedure TryReadB(var Host: TestPage "LT NL Host"; var Result: Text)
    begin
        Result := Host.LinesB."Document No.".Value() + '|' + Host.LinesB.Type.Value() + '|' + Host.LinesB.Seen.Value();
    end;

    [TryFunction]
    local procedure TryReadPlain(var Host: TestPage "LT NL Host"; var Result: Text)
    begin
        Result := Host.LinesPlain."Document No.".Value() + '|' + Host.LinesPlain.Type.Value() + '|' + Host.LinesPlain.Seen.Value();
    end;

    [TryFunction]
    local procedure TryTypeB(var Host: TestPage "LT NL Host")
    begin
        Host.LinesB.Descr.SetValue('x');
    end;

    [TryFunction]
    local procedure TryTypePlain(var Host: TestPage "LT NL Host")
    begin
        Host.LinesPlain.Descr.SetValue('x');
    end;

    [TryFunction]
    local procedure TryClose(var Host: TestPage "LT NL Host")
    begin
        Host.Close();
    end;

    local procedure Step(Name: Text; Ok: Boolean)
    begin
        if Ok then
            Obs.Observe(Name, 'ok')
        else begin
            Obs.Observe(Name, GetLastErrorText());
            ClearLastError();
        end;
    end;

    [Test]
    procedure PartB_ExistingHeaderTypeB_NewLine()
    var
        Host: TestPage "LT NL Host";
        Result: Text;
    begin
        Seed('HB', "LT NL Type"::B);
        Host.OpenEdit();
        Step('new', TryNewB(Host));
        if TryReadB(Host, Result) then
            Obs.Observe('draft', Result)
        else
            Step('read', false);
        Step('type', TryTypeB(Host));
        if TryReadB(Host, Result) then
            Obs.Observe('typed', Result)
        else
            Step('read2', false);
        Step('close', TryClose(Host));
        ObserveLines('db');
        Obs.Finish();
    end;

    [Test]
    procedure PartB_ExistingHeaderTypeA_NewLine()
    var
        Host: TestPage "LT NL Host";
        Result: Text;
    begin
        Seed('HA', "LT NL Type"::A);
        Host.OpenEdit();
        Step('new', TryNewB(Host));
        if TryReadB(Host, Result) then
            Obs.Observe('draft', Result)
        else
            Step('read', false);
        Step('type', TryTypeB(Host));
        Step('close', TryClose(Host));
        ObserveLines('db');
        Obs.Expect('new', 'ok');
        Obs.Expect('draft', 'HA|A|A');
        Obs.Expect('type', 'ok');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', 'HA|A|A|x');
        Obs.Expect('
AL Callstack:
"Probe Observer State"(CodeUnit 69163).Raise line 8 - AL Language Coverage Tests by AL Language version 1.0.0.0
"Probe Observer"(CodeUnit 69160).Finish line 6 - AL Language Coverage Tests by AL Language version 1.0.0.0
"LT New Line Stamps Filters"(CodeUnit 74141).PartB_ExistingHeaderTypeA_NewLine line 16 - AL Language Coverage Tests by AL Language version 1.0.0.0

', '');
        Obs.Verify();
    end;

    [Test]
    procedure PartPlain_ExistingHeaderTypeB_NewLine()
    var
        Host: TestPage "LT NL Host";
        Result: Text;
    begin
        Seed('HB', "LT NL Type"::B);
        Host.OpenEdit();
        Step('new', TryNewPlain(Host));
        if TryReadPlain(Host, Result) then
            Obs.Observe('draft', Result)
        else
            Step('read', false);
        Step('type', TryTypePlain(Host));
        Step('close', TryClose(Host));
        ObserveLines('db');
        Obs.Finish();
    end;

    [Test]
    procedure PartPlain_ExistingHeaderTypeA_NewLine()
    var
        Host: TestPage "LT NL Host";
        Result: Text;
    begin
        Seed('HA', "LT NL Type"::A);
        Host.OpenEdit();
        Step('new', TryNewPlain(Host));
        if TryReadPlain(Host, Result) then
            Obs.Observe('draft', Result)
        else
            Step('read', false);
        Step('type', TryTypePlain(Host));
        Step('close', TryClose(Host));
        ObserveLines('db');
        Obs.Expect('new', 'ok');
        Obs.Expect('draft', 'HA|A|A');
        Obs.Expect('type', 'ok');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', 'HA|A|A|x');
        Obs.Expect('
AL Callstack:
"Probe Observer State"(CodeUnit 69163).Raise line 8 - AL Language Coverage Tests by AL Language version 1.0.0.0
"Probe Observer"(CodeUnit 69160).Finish line 6 - AL Language Coverage Tests by AL Language version 1.0.0.0
"LT New Line Stamps Filters"(CodeUnit 74141).PartPlain_ExistingHeaderTypeA_NewLine line 16 - AL Language Coverage Tests by AL Language version 1.0.0.0

', '');
        Obs.Verify();
    end;

    [Test]
    procedure PartB_OpenNewHeader_TypeThenNo()
    var
        Host: TestPage "LT NL Host";
        Result: Text;
    begin
        Seed('', "LT NL Type"::A);
        Host.OpenNew();
        Host.Type.SetValue('B');
        Host."No.".SetValue('HN');
        Step('type', TryTypeB(Host));
        if TryReadB(Host, Result) then
            Obs.Observe('typed', Result)
        else
            Step('read', false);
        Step('close', TryClose(Host));
        ObserveLines('db');
        Obs.Expect('type', 'ok');
        Obs.Expect('typed', '|A|A');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', '|A|A|x');
        Obs.Expect('
AL Callstack:
"Probe Observer State"(CodeUnit 69163).Raise line 8 - AL Language Coverage Tests by AL Language version 1.0.0.0
"Probe Observer"(CodeUnit 69160).Finish line 6 - AL Language Coverage Tests by AL Language version 1.0.0.0
"LT New Line Stamps Filters"(CodeUnit 74141).PartB_OpenNewHeader_TypeThenNo line 16 - AL Language Coverage Tests by AL Language version 1.0.0.0

', '');
        Obs.Verify();
    end;

    [Test]
    procedure PartB_OpenNewHeader_NoThenType()
    var
        Host: TestPage "LT NL Host";
        Result: Text;
    begin
        Seed('', "LT NL Type"::A);
        Host.OpenNew();
        Host."No.".SetValue('HN');
        Host.Type.SetValue('B');
        Step('type', TryTypeB(Host));
        if TryReadB(Host, Result) then
            Obs.Observe('typed', Result)
        else
            Step('read', false);
        Step('close', TryClose(Host));
        ObserveLines('db');
        Obs.Expect('type', 'ok');
        Obs.Expect('typed', 'HN|A|A');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', 'HN|A|A|x');
        Obs.Expect('
AL Callstack:
"Probe Observer State"(CodeUnit 69163).Raise line 8 - AL Language Coverage Tests by AL Language version 1.0.0.0
"Probe Observer"(CodeUnit 69160).Finish line 6 - AL Language Coverage Tests by AL Language version 1.0.0.0
"LT New Line Stamps Filters"(CodeUnit 74141).PartB_OpenNewHeader_NoThenType line 16 - AL Language Coverage Tests by AL Language version 1.0.0.0

', '');
        Obs.Verify();
    end;
}
