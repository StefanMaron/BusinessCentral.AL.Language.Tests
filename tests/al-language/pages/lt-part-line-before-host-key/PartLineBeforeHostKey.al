// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 67573 and 67576, pages 67577 and 67578, log codeunit 67579, test codeunit 67582
// Probe: a document page (header "No." is the key) with a lines ListPart linked by SourceTableLink. A line is entered while the header key is still blank, then the key is typed. Which table triggers run (header and line: OnInsert, OnValidate), in which order, which page triggers run, what the card and the part show afterwards and what is stored. The same with the key typed first, for comparison (issue 581 item 2).
// BC versions: 27+ (the key-typed-after-a-line test: 28+; BC 27 raises an uncatchable NullReferenceException there)

table 67573 "LT DL Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Codeunit "LT DL Log";
            begin
                Log.Add('H.OnValidate(No.):' + "No.");
            end;
        }
        field(2; Name; Text[30])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Codeunit "LT DL Log";
            begin
                Log.Add('H.OnValidate(Name):' + Name + ' key=' + "No.");
            end;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('H.OnInsert:' + "No.");
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('H.OnModify:' + "No.");
    end;
}

table 67576 "LT DL Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "LT DL Header";

            trigger OnValidate()
            var
                Log: Codeunit "LT DL Log";
            begin
                Log.Add('L.OnValidate(Document No.):' + "Document No.");
            end;
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(3; Description; Text[30])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Codeunit "LT DL Log";
            begin
                Log.Add('L.OnValidate(Description):' + Description + ' key=' + "Document No." + '/' + Format("Line No."));
            end;
        }
        field(4; Quantity; Decimal)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Codeunit "LT DL Log";
            begin
                Log.Add('L.OnValidate(Quantity):' + Format(Quantity) + ' key=' + "Document No." + '/' + Format("Line No."));
            end;
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('L.OnInsert:' + "Document No." + '/' + Format("Line No."));
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('L.OnModify:' + "Document No." + '/' + Format("Line No."));
    end;
}

codeunit 67579 "LT DL Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit('[' + Result + ']');
    end;
}

page 67578 "LT DL Lines"
{
    PageType = ListPart;
    SourceTable = "LT DL Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('LP.OnNewRecord:' + Rec."Document No.");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('LP.OnInsertRecord:' + Rec."Document No." + '/' + Format(Rec."Line No."));
        exit(true);
    end;
}

page 67577 "LT DL Document"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
            part(Lines; "LT DL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('HP.OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('HP.OnInsertRecord:' + Rec."No.");
        exit(true);
    end;
}

// Writer PY-B (2026-10-20): page shapes for the count of a part's OnNewRecord at host OpenNew and New (pages 85183-85190, all log into
// "LT DL Log" and are used by test codeunit 67582 only).
page 85183 "LT PYB DL Lines NoSplit"
{
    PageType = ListPart;
    SourceTable = "LT DL Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('NP.OnNewRecord:' + Rec."Document No." + ' below=' + Format(BelowxRec));
    end;
}

page 85184 "LT PYB DL Lines B"
{
    PageType = ListPart;
    SourceTable = "LT DL Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('BP.OnNewRecord:' + Rec."Document No." + ' below=' + Format(BelowxRec));
    end;
}

page 85185 "LT PYB DL Doc NoTrigger"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
            part(Lines; "LT DL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}

page 85186 "LT PYB DL Doc Unlinked"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "LT DL Lines")
            {
                ApplicationArea = All;
            }
        }
    }
}

page 85187 "LT PYB DL Doc NoSplit"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "LT PYB DL Lines NoSplit")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}

page 85188 "LT PYB DL Doc Two"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "LT DL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
            part(LinesB; "LT PYB DL Lines B")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}

page 85189 "LT PYB DL Card"
{
    PageType = Card;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT DL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}

page 85190 "LT PYB DL Doc Const"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "LT DL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = const('D9');
            }
        }
    }
}

codeunit 67582 "LT DL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Header: Record "LT DL Header";
        Line: Record "LT DL Line";
        Log: Codeunit "LT DL Log";
    begin
        Line.DeleteAll();
        Header.DeleteAll();
        Log.Reset();
    end;

    [TryFunction]
    local procedure TryOpenNew(var Host: TestPage "LT DL Document")
    begin
        Host.OpenNew();
    end;

    [TryFunction]
    local procedure TryNewLine(var Host: TestPage "LT DL Document")
    begin
        Host.Lines.New();
    end;

    [TryFunction]
    local procedure TryDescription(var Host: TestPage "LT DL Document"; Value: Text)
    begin
        Host.Lines.Description.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryQuantity(var Host: TestPage "LT DL Document"; Value: Decimal)
    begin
        Host.Lines.Quantity.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryKey(var Host: TestPage "LT DL Document"; Value: Text)
    begin
        Host."No.".SetValue(Value);
    end;

    [TryFunction]
    local procedure TryName(var Host: TestPage "LT DL Document"; Value: Text)
    begin
        Host.Name.SetValue(Value);
    end;

    local procedure Step(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    var
        Log: Codeunit "LT DL Log";
    begin
        Observer.Observe(Name, Format(Ok));
        if not Ok then
            Observer.ObserveError(Name + '_error');
        Observer.Observe(Name + '_log', Log.Dump());
        Log.Reset();
    end;

    local procedure Stored(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Header: Record "LT DL Header";
        Line: Record "LT DL Line";
        Rows: Text;
    begin
        Observer.Observe(Name + '_headers', Format(Header.Count()));
        if Header.FindSet() then
            repeat
                Rows += '[' + Header."No." + '|' + Header.Name + ']';
            until Header.Next() = 0;
        Observer.Observe(Name + '_header_rows', Rows);
        Rows := '';
        Observer.Observe(Name + '_lines', Format(Line.Count()));
        if Line.FindSet() then
            repeat
                Rows += '[' + Line."Document No." + '|' + Format(Line."Line No.") + '|' + Line.Description + '|' + Format(Line.Quantity) + ']';
            until Line.Next() = 0;
        Observer.Observe(Name + '_line_rows', Rows);
    end;

    local procedure Card(var Observer: Codeunit "Probe Observer"; Name: Text; var Host: TestPage "LT DL Document")
    begin
        Observer.Observe(Name + '_card_no', '[' + Host."No.".Value() + ']');
        Observer.Observe(Name + '_card_name', '[' + Host.Name.Value() + ']');
        Observer.Observe(Name + '_part_description', '[' + Host.Lines.Description.Value() + ']');
        Observer.Observe(Name + '_part_quantity', '[' + Host.Lines.Quantity.Value() + ']');
    end;

#if BC28PLUS // BC 27 raises an uncatchable CLR exception when the key is typed after a line was entered (a NullReferenceException that neither a TryFunction nor asserterror catches, so BC 27 cannot be pinned here)
    [Test]
    procedure PartLine_EnteredBeforeHostKey_ThenKeyTyped()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        Step(Observer, 'open_new', TryOpenNew(Host));
        Step(Observer, 'new_line', TryNewLine(Host));
        Step(Observer, 'description_before_key', TryDescription(Host, 'first'));
        Step(Observer, 'quantity_before_key', TryQuantity(Host, 3));
        Stored(Observer, 'before_key');
        Step(Observer, 'type_key', TryKey(Host, 'D1'));
        Card(Observer, 'after_key', Host);
        Stored(Observer, 'after_key');
        Step(Observer, 'type_name', TryName(Host, 'Doc one'));
        Stored(Observer, 'after_name');
        Step(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', 'Yes');
        Observer.Expect('open_new_log', '[HP.OnNewRecord | L.OnValidate(Document No.): | LP.OnNewRecord: | LP.OnNewRecord: | L.OnValidate(Document No.): | LP.OnNewRecord:]');
        Observer.Expect('new_line', 'Yes');
        Observer.Expect('new_line_log', '[HP.OnInsertRecord: | H.OnInsert: | L.OnValidate(Document No.): | LP.OnNewRecord: | LP.OnNewRecord: | L.OnValidate(Document No.): | LP.OnNewRecord: | L.OnValidate(Document No.): | LP.OnNewRecord:]');
        Observer.Expect('description_before_key', 'Yes');
        Observer.Expect('description_before_key_log', '[L.OnValidate(Description):first key=/0]');
        Observer.Expect('quantity_before_key', 'Yes');
        Observer.Expect('quantity_before_key_log', '[LP.OnInsertRecord:/20000 | L.OnInsert:/20000 | L.OnValidate(Quantity):3 key=/20000]');
        Observer.Expect('before_key_headers', '1');
        Observer.Expect('before_key_header_rows', '[|]');
        Observer.Expect('before_key_lines', '1');
        Observer.Expect('before_key_line_rows', '[|20000|first|0]');
        Observer.Expect('type_key', 'Yes');
        Observer.Expect('type_key_log', '[L.OnModify:/20000 | H.OnValidate(No.):D1]');
        Observer.Expect('after_key_card_no', '[]');
        Observer.Expect('after_key_card_name', '[]');
        Observer.Expect('after_key_part_description', '[first]');
        Observer.Expect('after_key_part_quantity', '[3.00]');
        Observer.Expect('after_key_headers', '1');
        Observer.Expect('after_key_header_rows', '[|]');
        Observer.Expect('after_key_lines', '1');
        Observer.Expect('after_key_line_rows', '[|20000|first|3]');
        Observer.Expect('type_name', 'Yes');
        Observer.Expect('type_name_log', '[H.OnValidate(Name):Doc one key=]');
        Observer.Expect('after_name_headers', '1');
        Observer.Expect('after_name_header_rows', '[|]');
        Observer.Expect('after_name_lines', '1');
        Observer.Expect('after_name_line_rows', '[|20000|first|3]');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[H.OnModify:]');
        Observer.Expect('after_close_headers', '1');
        Observer.Expect('after_close_header_rows', '[|Doc one]');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|20000|first|3]');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure PartLine_EnteredAfterHostKey_Baseline()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        Step(Observer, 'open_new', TryOpenNew(Host));
        Step(Observer, 'type_key', TryKey(Host, 'D2'));
        Stored(Observer, 'after_key');
        Step(Observer, 'new_line', TryNewLine(Host));
        Step(Observer, 'description', TryDescription(Host, 'second'));
        Step(Observer, 'quantity', TryQuantity(Host, 4));
        Card(Observer, 'after_line', Host);
        Stored(Observer, 'after_line');
        Step(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', 'Yes');
        Observer.Expect('open_new_log', '[HP.OnNewRecord | L.OnValidate(Document No.): | LP.OnNewRecord: | LP.OnNewRecord: | L.OnValidate(Document No.): | LP.OnNewRecord:]');
        Observer.Expect('type_key', 'Yes');
        Observer.Expect('type_key_log', '[H.OnValidate(No.):D2 | L.OnValidate(Document No.): | LP.OnNewRecord: | LP.OnNewRecord: | L.OnValidate(Document No.): | LP.OnNewRecord:]');
        Observer.Expect('after_key_headers', '0');
        Observer.Expect('after_key_header_rows', '');
        Observer.Expect('after_key_lines', '0');
        Observer.Expect('after_key_line_rows', '');
        Observer.Expect('new_line', 'Yes');
        Observer.Expect('new_line_log', '[HP.OnInsertRecord:D2 | H.OnInsert:D2 | L.OnValidate(Document No.):D2 | LP.OnNewRecord:D2 | LP.OnNewRecord:D2 | L.OnValidate(Document No.):D2 | LP.OnNewRecord:D2 | L.OnValidate(Document No.):D2 | LP.OnNewRecord:D2]');
        Observer.Expect('description', 'Yes');
        Observer.Expect('description_log', '[L.OnValidate(Description):second key=D2/0]');
        Observer.Expect('quantity', 'Yes');
        Observer.Expect('quantity_log', '[LP.OnInsertRecord:D2/20000 | L.OnInsert:D2/20000 | L.OnValidate(Quantity):4 key=D2/20000]');
        Observer.Expect('after_line_card_no', '[D2]');
        Observer.Expect('after_line_card_name', '[]');
        Observer.Expect('after_line_part_description', '[second]');
        Observer.Expect('after_line_part_quantity', '[4.00]');
        Observer.Expect('after_line_headers', '1');
        Observer.Expect('after_line_header_rows', '[D2|]');
        Observer.Expect('after_line_lines', '1');
        Observer.Expect('after_line_line_rows', '[D2|20000|second|0]');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[L.OnModify:D2/20000]');
        Observer.Expect('after_close_headers', '1');
        Observer.Expect('after_close_header_rows', '[D2|]');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[D2|20000|second|4]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryClose(var Host: TestPage "LT DL Document")
    begin
        Host.Close();
    end;

    // Writer PY-B (2026-10-20): how often a part's OnNewRecord runs while its host opens new, by page shape.
    local procedure SeedLine(DocNo: Code[20]; LineNo: Integer)
    var
        Line: Record "LT DL Line";
    begin
        Line."Document No." := DocNo;
        Line."Line No." := LineNo;
        Line.Description := 'seeded';
        Line.Insert();
    end;

    local procedure TakeLog(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Log: Codeunit "LT DL Log";
    begin
        Observer.Observe(Name, Log.Dump());
        Log.Reset();
    end;

    [Test]
    procedure PYB_OpenNew_Document_LogOnly()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[HP.OnNewRecord | L.OnValidate(Document No.): | LP.OnNewRecord: | LP.OnNewRecord: | L.OnValidate(Document No.): | LP.OnNewRecord:]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_HostWithoutOnNewRecord()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc NoTrigger";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[L.OnValidate(Document No.): | LP.OnNewRecord: | LP.OnNewRecord: | L.OnValidate(Document No.): | LP.OnNewRecord:]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_UnlinkedPart()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc Unlinked";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[LP.OnNewRecord: | LP.OnNewRecord: | LP.OnNewRecord:]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_UnlinkedPart_WithRows()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc Unlinked";
    begin
        Seed();
        SeedLine('X1', 10000);
        SeedLine('X1', 20000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_PartWithoutAutoSplitKey()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc NoSplit";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[L.OnValidate(Document No.): | NP.OnNewRecord: below=Yes | NP.OnNewRecord: below=Yes | L.OnValidate(Document No.): | NP.OnNewRecord: below=Yes]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_TwoLinkedParts()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc Two";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[L.OnValidate(Document No.): | LP.OnNewRecord: | LP.OnNewRecord: | L.OnValidate(Document No.): | LP.OnNewRecord: | L.OnValidate(Document No.): | BP.OnNewRecord: below=Yes | BP.OnNewRecord: below=Yes | L.OnValidate(Document No.): | BP.OnNewRecord: below=Yes]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_CardHost()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Card";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[L.OnValidate(Document No.): | LP.OnNewRecord: | LP.OnNewRecord: | L.OnValidate(Document No.): | LP.OnNewRecord:]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_ConstLinkedPart()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc Const";
    begin
        Seed();
        Observer.Observe('open_new', Format(TryOpenConst(Host)));
        Observer.ObserveError('open_new_error');
        TakeLog(Observer, 'open_new_log');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryOpenConst(var Host: TestPage "LT PYB DL Doc Const")
    begin
        Host.OpenNew();
    end;

    [Test]
    procedure PYB_OpenEdit_HostWithoutLines()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
        Header: Record "LT DL Header";
    begin
        Seed();
        Header."No." := 'D8';
        Header.Insert();
        Host.OpenEdit();
        TakeLog(Observer, 'open_edit');
        Host.New();
        TakeLog(Observer, 'host_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Finish();
    end;

    [Test]
    procedure PYB_OpenNew_ThenHostNew()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.New();
        TakeLog(Observer, 'host_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Finish();
    end;

    [Test]
    procedure PYB_OpenNew_LinkedPart_BlankKeyRowsExist()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        SeedLine('', 10000);
        SeedLine('', 20000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Observer.Observe('part_first_description', Host.Lines.Description.Value());
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[HP.OnNewRecord]');
        Observer.Expect('part_first_description', 'seeded');
        Observer.Expect('close', '[HP.OnInsertRecord: | H.OnInsert:]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenEdit_ThenHostNew()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
        Header: Record "LT DL Header";
    begin
        Seed();
        Header."No." := 'D5';
        Header.Insert();
        SeedLine('D5', 10000);
        Host.OpenEdit();
        TakeLog(Observer, 'open_edit');
        Host.New();
        TakeLog(Observer, 'host_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_edit', '[]');
        Observer.Expect('host_new', '[HP.OnNewRecord]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenView_ExistingHost()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
        Header: Record "LT DL Header";
    begin
        Seed();
        Header."No." := 'D6';
        Header.Insert();
        Host.OpenView();
        TakeLog(Observer, 'open_view');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_view', '[LP.OnNewRecord:D6]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_NameTypedFirst_ThenKey_ThenLine()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        Step(Observer, 'open_new', TryOpenNew(Host));
        Step(Observer, 'type_name', TryName(Host, 'N1'));
        Stored(Observer, 'after_name');
        Step(Observer, 'type_key', TryKey(Host, 'D7'));
        Observer.Observe('after_key_card_no', '[' + Host."No.".Value() + ']');
        Stored(Observer, 'after_key');
        Step(Observer, 'new_line', TryNewLine(Host));
        Step(Observer, 'description', TryDescription(Host, 'x'));
        Stored(Observer, 'after_line');
        Step(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', 'Yes');
        Observer.Expect('open_new_log', '[HP.OnNewRecord | L.OnValidate(Document No.): | LP.OnNewRecord: | LP.OnNewRecord: | L.OnValidate(Document No.): | LP.OnNewRecord:]');
        Observer.Expect('type_name', 'Yes');
        Observer.Expect('type_name_log', '[HP.OnInsertRecord: | H.OnInsert: | L.OnValidate(Document No.): | LP.OnNewRecord: | LP.OnNewRecord: | L.OnValidate(Document No.): | LP.OnNewRecord: | H.OnValidate(Name):N1 key= | L.OnValidate(Document No.): | LP.OnNewRecord: | LP.OnNewRecord: | L.OnValidate(Document No.): | LP.OnNewRecord:]');
        Observer.Expect('after_name_headers', '1');
        Observer.Expect('after_name_header_rows', '[|]');
        Observer.Expect('after_name_lines', '0');
        Observer.Expect('after_name_line_rows', '');
        Observer.Expect('type_key', 'Yes');
        Observer.Expect('type_key_log', '[H.OnValidate(No.):D7]');
        Observer.Expect('after_key_card_no', '[]');
        Observer.Expect('after_key_headers', '1');
        Observer.Expect('after_key_header_rows', '[|]');
        Observer.Expect('after_key_lines', '0');
        Observer.Expect('after_key_line_rows', '');
        Observer.Expect('new_line', 'Yes');
        Observer.Expect('new_line_log', '[L.OnValidate(Document No.): | LP.OnNewRecord:]');
        Observer.Expect('description', 'Yes');
        Observer.Expect('description_log', '[L.OnValidate(Description):x key=/0]');
        Observer.Expect('after_line_headers', '1');
        Observer.Expect('after_line_header_rows', '[|]');
        Observer.Expect('after_line_lines', '0');
        Observer.Expect('after_line_line_rows', '');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[LP.OnInsertRecord:/20000 | L.OnInsert:/20000]');
        Observer.Expect('after_close_headers', '1');
        Observer.Expect('after_close_header_rows', '[|]');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|20000|x|0]');
        Observer.Verify();
    end;

}
