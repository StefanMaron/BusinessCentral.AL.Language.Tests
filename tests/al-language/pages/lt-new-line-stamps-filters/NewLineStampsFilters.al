// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enum 74135, tables 74136 and 74137, pages 74138 to 74140, test codeunit 74141
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a list part with SourceTableView where(Type = const(B)) and SubPageLink "Document No." = field("No."). The link field is declared before Type,
//   its TableRelation filters the header on Type (where(Type = field(Type))), and its OnValidate stores the Type it sees in Seen.
//   What the blank line of the part holds after New() (before typing), and what the stored line holds after a field is typed, for an existing
//   header (OpenEdit) and a new header (OpenNew). A second part without SourceTableView is the contrast.
//   Not pinned: New() on a part whose host header has Type B (HB) aborts the page with FormAbortException (the Document No. relation is validated
//   before Type is stamped: "cannot be found in the related table"); the exception is not catchable, so no test can assert it.
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
        Obs.Verify();
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
        Obs.Verify();
    end;

    // Writer PY-B (2026-10-20): why the line keeps a blank link when Type is typed before No. on a new header: what the header table
    // holds after each step, what the card shows, and the link filter of each part.
    local procedure Headers(): Text
    var
        H: Record "LT NL Header";
        Rows: Text;
    begin
        if H.FindSet() then
            repeat
                Rows += '[' + H."No." + '|' + Format(H.Type) + ']';
            until H.Next() = 0;
        exit(Format(H.Count()) + ' ' + Rows);
    end;

    local procedure Snapshot(Prefix: Text; var Host: TestPage "LT NL Host")
    begin
        Obs.Observe(Prefix + '.headers', Headers());
        Obs.Observe(Prefix + '.card', '[' + Host."No.".Value() + '|' + Host.Type.Value() + ']');
        Obs.Observe(Prefix + '.filter_b', '[' + Host.LinesB.Filter.GetFilter("Document No.") + ']');
        Obs.Observe(Prefix + '.filter_plain', '[' + Host.LinesPlain.Filter.GetFilter("Document No.") + ']');
    end;

    [TryFunction]
    local procedure TryHostNo(var Host: TestPage "LT NL Host"; Value: Text)
    begin
        Host."No.".SetValue(Value);
    end;

    [TryFunction]
    local procedure TryHostType(var Host: TestPage "LT NL Host"; Value: Text)
    begin
        Host.Type.SetValue(Value);
    end;

    [Test]
    procedure PYB_OpenNew_TypeThenNo_Steps()
    var
        Host: TestPage "LT NL Host";
    begin
        Seed('', "LT NL Type"::A);
        Host.OpenNew();
        Snapshot('open', Host);
        Step('set_type', TryHostType(Host, 'B'));
        Snapshot('after_type', Host);
        Step('set_no', TryHostNo(Host, 'HN'));
        Snapshot('after_no', Host);
        Step('line', TryTypePlain(Host));
        ObserveLines('after_line');
        Step('close', TryClose(Host));
        Obs.Observe('after_close.headers', Headers());
        ObserveLines('after_close');
        Obs.Expect('open.headers', '0 ');
        Obs.Expect('open.card', '[|A]');
        Obs.Expect('open.filter_b', '['''']');
        Obs.Expect('open.filter_plain', '['''']');
        Obs.Expect('set_type', 'ok');
        Obs.Expect('after_type.headers', '1 [|A]');
        Obs.Expect('after_type.card', '[|B]');
        Obs.Expect('after_type.filter_b', '['''']');
        Obs.Expect('after_type.filter_plain', '['''']');
        Obs.Expect('set_no', 'ok');
        Obs.Expect('after_no.headers', '1 [|A]');
        Obs.Expect('after_no.card', '[|B]');
        Obs.Expect('after_no.filter_b', '['''']');
        Obs.Expect('after_no.filter_plain', '['''']');
        Obs.Expect('line', 'ok');
        Obs.Expect('after_line.count', '0');
        Obs.Expect('close', 'ok');
        Obs.Expect('after_close.headers', '1 [|B]');
        Obs.Expect('after_close.count', '1');
        Obs.Expect('after_close.first', '|A|A|x');
        Obs.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_NoThenType_Steps()
    var
        Host: TestPage "LT NL Host";
    begin
        Seed('', "LT NL Type"::A);
        Host.OpenNew();
        Step('set_no', TryHostNo(Host, 'HN'));
        Snapshot('after_no', Host);
        Step('set_type', TryHostType(Host, 'B'));
        Snapshot('after_type', Host);
        Step('line', TryTypePlain(Host));
        ObserveLines('after_line');
        Step('close', TryClose(Host));
        Obs.Observe('after_close.headers', Headers());
        ObserveLines('after_close');
        Obs.Expect('set_no', 'ok');
        Obs.Expect('after_no.headers', '0 ');
        Obs.Expect('after_no.card', '[HN|A]');
        Obs.Expect('after_no.filter_b', '[HN]');
        Obs.Expect('after_no.filter_plain', '[HN]');
        Obs.Expect('set_type', 'ok');
        Obs.Expect('after_type.headers', '1 [HN|A]');
        Obs.Expect('after_type.card', '[HN|B]');
        Obs.Expect('after_type.filter_b', '[HN]');
        Obs.Expect('after_type.filter_plain', '[HN]');
        Obs.Expect('line', 'ok');
        Obs.Expect('after_line.count', '0');
        Obs.Expect('close', 'ok');
        Obs.Expect('after_close.headers', '1 [HN|B]');
        Obs.Expect('after_close.count', '1');
        Obs.Expect('after_close.first', 'HN|A|A|x');
        Obs.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_TypeA_ThenNo_Steps()
    var
        Host: TestPage "LT NL Host";
    begin
        Seed('', "LT NL Type"::A);
        Host.OpenNew();
        Step('set_type', TryHostType(Host, 'A'));
        Snapshot('after_type', Host);
        Step('set_no', TryHostNo(Host, 'HN'));
        Snapshot('after_no', Host);
        Step('close', TryClose(Host));
        Obs.Observe('after_close.headers', Headers());
        Obs.Expect('set_type', 'ok');
        Obs.Expect('after_type.headers', '1 [|A]');
        Obs.Expect('after_type.card', '[|A]');
        Obs.Expect('after_type.filter_b', '['''']');
        Obs.Expect('after_type.filter_plain', '['''']');
        Obs.Expect('set_no', 'ok');
        Obs.Expect('after_no.headers', '1 [|A]');
        Obs.Expect('after_no.card', '[|A]');
        Obs.Expect('after_no.filter_b', '['''']');
        Obs.Expect('after_no.filter_plain', '['''']');
        Obs.Expect('close', 'ok');
        Obs.Expect('after_close.headers', '1 [|A]');
        Obs.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_TypeThenNo_ThenNext()
    var
        Host: TestPage "LT NL Host";
    begin
        Seed('', "LT NL Type"::A);
        Host.OpenNew();
        Step('set_type', TryHostType(Host, 'B'));
        Step('set_no', TryHostNo(Host, 'HN'));
        Obs.Observe('next', Format(Host.Next()));
        Obs.Observe('after_next.headers', Headers());
        Obs.Observe('after_next.card', '[' + Host."No.".Value() + '|' + Host.Type.Value() + ']');
        Step('close', TryClose(Host));
        Obs.Observe('after_close.headers', Headers());
        Obs.Expect('set_type', 'ok');
        Obs.Expect('set_no', 'ok');
        Obs.Expect('next', 'No');
        Obs.Expect('after_next.headers', '1 [|B]');
        Obs.Expect('after_next.card', '[|B]');
        Obs.Expect('close', 'ok');
        Obs.Expect('after_close.headers', '1 [|B]');
        Obs.Verify();
    end;

}
