// Probes: md:120 (hidden part and OnInit), md:121 (part close triggers, OnQueryClosePage refusing), md:123 (New / Next on a part with Editable = false),
// md:124 (Visible / Enabled of a part), md:125 (part position after the host or provider moves), md:126 (pending part row saved before the host moves),
// md:127 (SubPageView and SubPageLink on the same field).

table 69236 "W1 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; HdrId; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if Name = 'refuse' then
            Error('W1 insert refused');
    end;

    trigger OnModify()
    begin
        if Name = 'refuse' then
            Error('W1 modify refused');
    end;
}

codeunit 69247 "W1 Part Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        RefuseClose: Boolean;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure SetRefuseClose(NewValue: Boolean)
    begin
        RefuseClose := NewValue;
    end;

    procedure GetRefuseClose(): Boolean
    begin
        exit(RefuseClose);
    end;
}

page 69327 "W1 Line Part"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Line";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(HdrId; Rec.HdrId) { }
                field(Name; Rec.Name) { }
            }
        }
    }

    var
        Log: Codeunit "W1 Part Log";

    trigger OnInit()
    begin
        Log.Add('p.OnInit');
    end;

    trigger OnOpenPage()
    begin
        Log.Add('p.OnOpenPage');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('p.OnQueryClosePage(' + Format(CloseAction) + ')');
        exit(not Log.GetRefuseClose());
    end;

    trigger OnClosePage()
    begin
        Log.Add('p.OnClosePage');
    end;
}

page 69328 "W1 Part Host"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Hdr";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            part(Lines; "W1 Line Part")
            {
                SubPageLink = HdrId = field(Id);
            }
            part(ReadOnlyPart; "W1 Line Part")
            {
                Editable = false;
                SubPageLink = HdrId = field(Id);
            }
            part(DisabledPart; "W1 Line Part")
            {
                Enabled = false;
                SubPageLink = HdrId = field(Id);
            }
            part(EnabledExprPart; "W1 Line Part")
            {
                Enabled = EnabledVar;
                SubPageLink = HdrId = field(Id);
            }
            part(VisibleExprPart; "W1 Line Part")
            {
                Visible = VisibleVar;
                SubPageLink = HdrId = field(Id);
            }
            group(HiddenGroup)
            {
                Visible = false;
                part(PartInHiddenGroup; "W1 Line Part")
                {
                    SubPageLink = HdrId = field(Id);
                }
            }
        }
    }

    var
        EnabledVar: Boolean;
        VisibleVar: Boolean;

    trigger OnInit()
    begin
        VisibleVar := true;
    end;
}

page 69329 "W1 Part Host Expr"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Hdr";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            part(Lines; "W1 Line Part")
            {
                Visible = ShowPart;
                SubPageLink = HdrId = field(Id);
            }
        }
    }

    var
        ShowPart: Boolean;
        Log: Codeunit "W1 Part Log";

    trigger OnInit()
    begin
        Log.Add('h.OnInit');
    end;

    trigger OnOpenPage()
    begin
        Log.Add('h.OnOpenPage');
    end;
}

page 69330 "W1 Part Host Static"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Hdr";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            part(Lines; "W1 Line Part")
            {
                Visible = false;
                SubPageLink = HdrId = field(Id);
            }
        }
    }

    var
        Log: Codeunit "W1 Part Log";

    trigger OnInit()
    begin
        Log.Add('h.OnInit');
    end;

    trigger OnOpenPage()
    begin
        Log.Add('h.OnOpenPage');
    end;
}

page 69331 "W1 Part Host Shown"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Hdr";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            part(Lines; "W1 Line Part")
            {
                SubPageLink = HdrId = field(Id);
            }
        }
    }

    var
        Log: Codeunit "W1 Part Log";

    trigger OnInit()
    begin
        Log.Add('h.OnInit');
    end;

    trigger OnOpenPage()
    begin
        Log.Add('h.OnOpenPage');
    end;
}

page 69332 "W1 Part Host View"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Hdr";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            part(Lines; "W1 Line Part")
            {
                SubPageView = where(HdrId = const(2));
                SubPageLink = HdrId = field(Id);
            }
        }
    }
}

page 69333 "W1 Part Host Prov"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Hdr";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            part(Lines; "W1 Line Part")
            {
                SubPageLink = HdrId = field(Id);
            }
            part(Detail; "W1 Line Part")
            {
                Provider = Lines;
                SubPageLink = HdrId = field(Id);
            }
        }
    }
}

codeunit 69306 "W1 Parts Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "W1 Part Log";

    local procedure Seed()
    var
        Hdr: Record "W1 Hdr";
        Line: Record "W1 Line";
    begin
        Hdr.DeleteAll();
        Line.DeleteAll();
        Hdr.Id := 1;
        Hdr.Insert();
        Hdr.Id := 2;
        Hdr.Insert();
        Hdr.Id := 3;
        Hdr.Insert();
        InsertLine(11, 1, 'a');
        InsertLine(12, 1, 'b');
        InsertLine(13, 1, 'c');
        InsertLine(21, 3, 'x');
        InsertLine(22, 3, 'y');
        InsertLine(31, 11, 'd1');
        InsertLine(32, 11, 'd2');
        InsertLine(33, 12, 'e1');
        InsertLine(41, 2, 'h2');
        InsertLine(90, 0, 'blank-linked');
        Log.SetRefuseClose(false);
        Log.Take();
    end;

    local procedure InsertLine(Id: Integer; HdrId: Integer; Name: Text)
    var
        Line: Record "W1 Line";
    begin
        Line.Init();
        Line.Id := Id;
        Line.HdrId := HdrId;
        Line.Name := CopyStr(Name, 1, MaxStrLen(Line.Name));
        Line.Insert();
    end;

    local procedure LinesRows(var Host: TestPage "W1 Part Host"): Text
    var
        Result: Text;
    begin
        if Host.Lines.First() then
            repeat
                Result += Host.Lines.Id.Value() + ' ';
            until not Host.Lines.Next();
        exit(Result);
    end;

    local procedure ViewRows(var Host: TestPage "W1 Part Host View"): Text
    var
        Result: Text;
    begin
        if Host.Lines.First() then
            repeat
                Result += Host.Lines.Id.Value() + ' ';
            until not Host.Lines.Next();
        exit(Result);
    end;

    // ---------- md:120 ----------

    [Test]
    procedure Part_HiddenByExpressionOrStatically_OnInit()
    var
        Expr: TestPage "W1 Part Host Expr";
        Static: TestPage "W1 Part Host Static";
        Shown: TestPage "W1 Part Host Shown";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Expr.OpenEdit();
        Observer.Observe('visible_expression_false', Log.Take());
        Expr.Close();
        Observer.Observe('visible_expression_false_close', Log.Take());
        Static.OpenEdit();
        Observer.Observe('visible_false', Log.Take());
        Static.Close();
        Observer.Observe('visible_false_close', Log.Take());
        Shown.OpenEdit();
        Observer.Observe('visible_contrast', Log.Take());
        Shown.Close();
        Observer.Observe('visible_contrast_close', Log.Take());
        Observer.Expect('visible_expression_false', 'h.OnInit;p.OnInit;h.OnOpenPage;p.OnOpenPage;');
        Observer.Expect('visible_expression_false_close', 'p.OnQueryClosePage(None);p.OnClosePage;');
        Observer.Expect('visible_false', 'h.OnInit;h.OnOpenPage;');
        Observer.Expect('visible_false_close', '');
        Observer.Expect('visible_contrast', 'h.OnInit;p.OnInit;h.OnOpenPage;p.OnOpenPage;');
        Observer.Expect('visible_contrast_close', 'p.OnQueryClosePage(None);p.OnClosePage;');
        Observer.Verify();
    end;

    // ---------- md:121 ----------

    [TryFunction]
    local procedure TryCloseHost(var Host: TestPage "W1 Part Host")
    begin
        Host.Close();
    end;

    [Test]
    procedure PartOnQueryClosePage_ReturnsFalse_WhenTheHostCloses()
    var
        Host: TestPage "W1 Part Host";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Host.OpenEdit();
        Log.Take();
        Log.SetRefuseClose(true);
        if TryCloseHost(Host) then
            Observer.Observe('close_refused_by_part', 'ok')
        else
            Observer.ObserveError('close_refused_by_part');
        Observer.Observe('log', Log.Take());
        Log.SetRefuseClose(false);
        if TryCloseHost(Host) then
            Observer.Observe('close_again', 'ok')
        else
            Observer.ObserveError('close_again');
        Observer.Observe('log_again', Log.Take());
        Observer.Expect('close_refused_by_part', 'ok');
        Observer.Expect('log', 'p.OnQueryClosePage(None);');
        Observer.Expect('close_again|text', 'The TestPage is not open.');
        Observer.Expect('close_again|code', 'TestPageNotOpened');
        Observer.Expect('log_again', '');
        Observer.Verify();
    end;

    // ---------- md:123 ----------

    [TryFunction]
    local procedure TryNewOnReadOnlyPart(var Host: TestPage "W1 Part Host")
    begin
        Host.ReadOnlyPart.New();
    end;

    [TryFunction]
    local procedure TryNextOnReadOnlyPart(var Host: TestPage "W1 Part Host"; var Moved: Boolean)
    begin
        Moved := Host.ReadOnlyPart.Next();
    end;

    [TryFunction]
    local procedure TryNewOnEditablePart(var Host: TestPage "W1 Part Host")
    begin
        Host.Lines.New();
    end;

    [Test]
    procedure ReadOnlyPart_New_And_NextOntoTheBlankLine()
    var
        Host: TestPage "W1 Part Host";
        Observer: Codeunit "Probe Observer";
        Moved: Boolean;
    begin
        Seed();
        Host.OpenEdit();
        Host.GoToKey(1);
        Log.Take();
        Observer.Observe('readonly_last', Format(Host.ReadOnlyPart.Last()));
        Observer.Observe('readonly_last_id', Host.ReadOnlyPart.Id.Value());
        if TryNextOnReadOnlyPart(Host, Moved) then begin
            Observer.Observe('readonly_next', Format(Moved));
            Observer.Observe('readonly_next_id', Host.ReadOnlyPart.Id.Value());
        end else
            Observer.ObserveError('readonly_next');
        if TryNewOnReadOnlyPart(Host) then begin
            Observer.Observe('readonly_new', 'ok');
            Observer.Observe('readonly_new_id', Host.ReadOnlyPart.Id.Value());
        end else
            Observer.ObserveError('readonly_new');
        if TryNewOnEditablePart(Host) then begin
            Observer.Observe('editable_new', 'ok');
            Observer.Observe('editable_new_id', Host.Lines.Id.Value());
        end else
            Observer.ObserveError('editable_new');
        Observer.Observe('log', Log.Take());
        Host.Close();
        Observer.Expect('readonly_last', 'Yes');
        Observer.Expect('readonly_last_id', '13');
        Observer.Expect('readonly_next', 'No');
        Observer.Expect('readonly_next_id', '13');
        Observer.Expect('readonly_new', 'ok');
        Observer.Expect('readonly_new_id', '0');
        Observer.Expect('editable_new', 'ok');
        Observer.Expect('editable_new_id', '0');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    // ---------- md:124 ----------

    [TryFunction]
    local procedure TryHiddenGroupPart(var Host: TestPage "W1 Part Host"; var Result: Boolean; AskVisible: Boolean)
    begin
        if AskVisible then
            Result := Host.PartInHiddenGroup.Visible()
        else
            Result := Host.PartInHiddenGroup.Enabled();
    end;

    [Test]
    procedure Part_Visible_And_Enabled()
    var
        Host: TestPage "W1 Part Host";
        Observer: Codeunit "Probe Observer";
        Flag: Boolean;
    begin
        Seed();
        Host.OpenEdit();
        Observer.Observe('Lines_enabled', Format(Host.Lines.Enabled()));
        Observer.Observe('Lines_visible', Format(Host.Lines.Visible()));
        Observer.Observe('ReadOnlyPart_enabled', Format(Host.ReadOnlyPart.Enabled()));
        Observer.Observe('ReadOnlyPart_visible', Format(Host.ReadOnlyPart.Visible()));
        Observer.Observe('DisabledPart_enabled', Format(Host.DisabledPart.Enabled()));
        Observer.Observe('DisabledPart_visible', Format(Host.DisabledPart.Visible()));
        Observer.Observe('EnabledExprPart_enabled', Format(Host.EnabledExprPart.Enabled()));
        Observer.Observe('VisibleExprPart_visible', Format(Host.VisibleExprPart.Visible()));
        Observer.Observe('VisibleExprPart_enabled', Format(Host.VisibleExprPart.Enabled()));
        if TryHiddenGroupPart(Host, Flag, true) then
            Observer.Observe('PartInHiddenGroup_visible', 'no error, ' + Format(Flag))
        else
            Observer.ObserveError('PartInHiddenGroup_visible');
        if TryHiddenGroupPart(Host, Flag, false) then
            Observer.Observe('PartInHiddenGroup_enabled', 'no error, ' + Format(Flag))
        else
            Observer.ObserveError('PartInHiddenGroup_enabled');
        Host.Close();
        Observer.Expect('Lines_enabled', 'Yes');
        Observer.Expect('Lines_visible', 'Yes');
        Observer.Expect('ReadOnlyPart_enabled', 'Yes');
        Observer.Expect('ReadOnlyPart_visible', 'Yes');
        Observer.Expect('DisabledPart_enabled', 'No');
        Observer.Expect('DisabledPart_visible', 'Yes');
        Observer.Expect('EnabledExprPart_enabled', 'No');
        Observer.Expect('VisibleExprPart_visible', 'Yes');
        Observer.Expect('VisibleExprPart_enabled', 'Yes');
        Observer.Expect('PartInHiddenGroup_visible|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('PartInHiddenGroup_visible|code', 'TestPartNotFound');
        Observer.Expect('PartInHiddenGroup_enabled|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('PartInHiddenGroup_enabled|code', 'TestPartNotFound');
        Observer.Verify();
    end;

    // ---------- md:125 ----------

    [Test]
    procedure Part_Position_WhenTheHostReturnsToARow()
    var
        Host: TestPage "W1 Part Host";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Host.OpenEdit();
        Host.GoToKey(1);
        Observer.Observe('host1_part_row', Host.Lines.Id.Value());
        Host.Lines.Last();
        Observer.Observe('host1_part_after_last', Host.Lines.Id.Value());
        Host.GoToKey(3);
        Observer.Observe('host3_part_row', Host.Lines.Id.Value());
        Host.GoToKey(1);
        Observer.Observe('back_on_host1_part_row', Host.Lines.Id.Value());
        Host.Lines.GoToKey(12);
        Host.GoToKey(2);
        Observer.Observe('host2_part_row', Host.Lines.Id.Value());
        Host.GoToKey(1);
        Observer.Observe('back_again_on_host1_part_row', Host.Lines.Id.Value());
        Host.Close();
        Observer.Expect('host1_part_row', '11');
        Observer.Expect('host1_part_after_last', '13');
        Observer.Expect('host3_part_row', '22');
        Observer.Expect('back_on_host1_part_row', '13');
        Observer.Expect('host2_part_row', '41');
        Observer.Expect('back_again_on_host1_part_row', '13');
        Observer.Verify();
    end;

    [Test]
    procedure Part_Position_HostShowsNoRow()
    var
        Host: TestPage "W1 Part Host";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Host.OpenEdit();
        Host.GoToKey(1);
        Host.Filter.SetFilter(Id, '99');
        Observer.Observe('host_id', Host.Id.Value());
        Observer.Observe('part_first', Format(Host.Lines.First()));
        Observer.Observe('part_row', Host.Lines.Id.Value());
        Observer.Observe('part_rows', LinesRows(Host));
        Host.Close();
        Observer.Expect('host_id', '');
        Observer.Expect('part_first', 'No');
        Observer.Expect('part_row', '0');
        Observer.Expect('part_rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure Part_Position_ProviderMoves()
    var
        Host: TestPage "W1 Part Host Prov";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Host.OpenEdit();
        Host.GoToKey(1);
        Observer.Observe('lines_row', Host.Lines.Id.Value());
        Observer.Observe('detail_row', Host.Detail.Id.Value());
        Host.Detail.Last();
        Observer.Observe('detail_after_last', Host.Detail.Id.Value());
        Host.Lines.GoToKey(12);
        Observer.Observe('provider_on_12_detail_row', Host.Detail.Id.Value());
        Host.Lines.GoToKey(13);
        Observer.Observe('provider_on_13_detail_row', Host.Detail.Id.Value());
        Host.Lines.GoToKey(11);
        Observer.Observe('provider_back_on_11_detail_row', Host.Detail.Id.Value());
        Host.Detail.Last();
        Host.Lines.GoToKey(12);
        Host.Lines.GoToKey(11);
        Observer.Observe('detail_last_then_provider_12_then_11', Host.Detail.Id.Value());
        Host.Close();
        Observer.Expect('lines_row', '11');
        Observer.Expect('detail_row', '31');
        Observer.Expect('detail_after_last', '32');
        Observer.Expect('provider_on_12_detail_row', '33');
        Observer.Expect('provider_on_13_detail_row', '0');
        Observer.Expect('provider_back_on_11_detail_row', '31');
        Observer.Expect('detail_last_then_provider_12_then_11', '32');
        Observer.Verify();
    end;

    // ---------- md:126 ----------

    [Test]
    procedure PendingPartEdit_IsSavedBeforeTheHostMoves()
    var
        Host: TestPage "W1 Part Host";
        Line: Record "W1 Line";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Host.OpenEdit();
        Host.GoToKey(1);
        Host.Lines.GoToKey(12);
        Host.Lines.Name.SetValue('pend');
        Line.Get(12);
        Observer.Observe('stored_before_move', Line.Name);
        Host.GoToKey(3);
        Line.Get(12);
        Observer.Observe('stored_after_host_move', Line.Name);
        Host.GoToKey(1);
        Observer.Observe('rows_back', LinesRows(Host));
        Host.Close();
        Observer.Expect('stored_before_move', 'b');
        Observer.Expect('stored_after_host_move', 'pend');
        Observer.Expect('rows_back', '11 12 13 0 ');
        Observer.Verify();
    end;

    [Test]
    procedure PendingPartEdit_IsSavedBeforeTheHostCloses()
    var
        Host: TestPage "W1 Part Host";
        Line: Record "W1 Line";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Host.OpenEdit();
        Host.GoToKey(1);
        Host.Lines.GoToKey(12);
        Host.Lines.Name.SetValue('pend');
        Host.Close();
        Line.Get(12);
        Observer.Observe('stored_after_host_close', Line.Name);
        Observer.Expect('stored_after_host_close', 'pend');
        Observer.Verify();
    end;

    // ---------- md:127 ----------

    [Test]
    procedure SubPageView_AndLink_OnTheSameField()
    var
        Host: TestPage "W1 Part Host View";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Host.OpenEdit();
        Observer.Observe('host1_rows', ViewRows(Host));
        Host.GoToKey(2);
        Observer.Observe('host2_rows', ViewRows(Host));
        Host.GoToKey(3);
        Observer.Observe('host3_rows', ViewRows(Host));
        Host.GoToKey(1);
        Observer.Observe('host1_rows_again', ViewRows(Host));
        Host.Close();
        Observer.Expect('host1_rows', '11 12 13 0 ');
        Observer.Expect('host2_rows', '41 0 ');
        Observer.Expect('host3_rows', '21 22 0 ');
        Observer.Expect('host1_rows_again', '11 12 13 0 ');
        Observer.Verify();
    end;
}
