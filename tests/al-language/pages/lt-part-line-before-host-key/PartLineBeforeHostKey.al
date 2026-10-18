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
}
