// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT PX)
// Writer PX-B (al-runtime-rs probes-needed, "Page control text and captions", TestField.DrillDown, TestField.Lookup, 2026-10-20).
// Facts: a control ClosingDates = false over a field with ClosingDates = true (Value, SetValue with C and c); a control Caption over a field
// CaptionClass; when OnResolveCaptionClass is raised for a control CaptionClass expression (same text at a refill, an expression changed
// since the fill) and for a field CaptionClass read twice; the page a control DrillDownPageId opens (filters and rows) from a field with and
// without a TableRelation; a FlowField DrillDown with no page on the control (filters, rows); OnDrillDown together with DrillDownPageId; the
// error code of a non-Dialog error in OnDrillDown; control TableRelation / LookupPageId lookups of each shape (page, filters, rows, the pick).
// The caption tests use their own caption expressions (T1..T4) so that a per-session caption cache cannot make them depend on test order.

table 86185 "LT PX Grp"
{
    DataClassification = CustomerContent;
    LookupPageId = "LT PX Grp List";
    DrillDownPageId = "LT PX Grp List";

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 86186 "LT PX Grp2"
{
    DataClassification = CustomerContent;
    DrillDownPageId = "LT PX Grp2 List";

    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 86187 "LT PX Grp3"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 86188 "LT PX Itm"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Grp; Code[10]) { TableRelation = "LT PX Grp".Code; }
        field(3; Plain; Code[10]) { }
        field(4; Qty; Integer) { }
        field(5; Closing; Date) { ClosingDates = true; }
        field(7; LkTrig; Code[10])
        {
            trigger OnLookup()
            var
                Log: Codeunit "LT PX Nav Log";
            begin
                Log.Add('field-onlookup');
            end;
        }
        field(8; Kind; Option) { OptionMembers = A,B; }
        field(9; SumAmt; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT PX Ent".Amount where(Grp = field(Grp), Day = field("Date Filter")));
            Editable = false;
        }
        field(10; "Date Filter"; Date) { FieldClass = FlowFilter; }
        field(11; Qty2; Integer) { }
        field(13; P1; Code[10]) { }
        field(14; P2; Code[10]) { }
        field(15; P3; Code[10]) { }
        field(16; P4; Code[10]) { }
        field(17; P5; Code[10]) { }
        field(18; P6; Code[10]) { }
        field(19; P7; Code[10]) { }
        field(20; G2f; Code[10]) { TableRelation = "LT PX Grp".Code; }
        field(21; G3f; Code[10]) { TableRelation = "LT PX Grp".Code; }
        field(22; P8; Code[10]) { }
        field(23; G4f; Code[10]) { TableRelation = "LT PX Grp".Code; }
        field(24; P9; Code[10]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 86189 "LT PX Ent"
{
    DataClassification = CustomerContent;
    DrillDownPageId = "LT PX Ent List";

    fields
    {
        field(1; Entry; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Amount; Decimal) { }
        field(4; Day; Date) { }
    }

    keys
    {
        key(PK; Entry) { Clustered = true; }
    }
}

table 86201 "LT PX CapRow"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; CapFld; Text[30]) { CaptionClass = CapText('A'); }
        field(3; CapFld2; Text[30]) { CaptionClass = CapText('B'); }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    procedure CapText(Suffix: Text): Text
    var
        State: Codeunit "LT PX CC State";
    begin
        exit('LTPX,' + State.GetText() + Suffix);
    end;
}

page 86190 "LT PX Grp List"
{
    PageType = List;
    SourceTable = "LT PX Grp";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PX Nav Log";
    begin
        Log.Add('open grp list' + Log.Filters(Rec));
    end;
}

page 86191 "LT PX Grp2 List"
{
    PageType = List;
    SourceTable = "LT PX Grp2";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PX Nav Log";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        Log.Add('open grp2 list' + Log.RefFilters(RecRef));
    end;
}

page 86192 "LT PX Grp Alt List"
{
    PageType = List;
    SourceTable = "LT PX Grp";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PX Nav Log";
    begin
        Log.Add('open grp alt list' + Log.Filters(Rec));
    end;
}

page 86193 "LT PX Ent List"
{
    PageType = List;
    SourceTable = "LT PX Ent";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(EntryCtl; Rec.Entry) { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
                field(AmountCtl; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PX Nav Log";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        Log.Add('open ent list' + Log.RefFilters(RecRef));
    end;
}

page 86194 "LT PX Nav Card"
{
    PageType = Card;
    SourceTable = "LT PX Itm";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(ClosingOff; Rec.Closing) { ApplicationArea = All; ClosingDates = false; }
                field(ClosingOn; Rec.Closing) { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
                field(DdNoRel; Rec.P8) { ApplicationArea = All; DrillDownPageId = "LT PX Grp List"; }
                field(DdRel; Rec.G4f) { ApplicationArea = All; DrillDownPageId = "LT PX Grp List"; }
                field(DdBoth; Rec.Qty)
                {
                    ApplicationArea = All;
                    DrillDownPageId = "LT PX Grp List";

                    trigger OnDrillDown()
                    var
                        Log: Codeunit "LT PX Nav Log";
                    begin
                        Log.Add('ondrilldown');
                    end;
                }
                field(DdErr; Rec.Qty2)
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    var
                        Grp: Record "LT PX Grp";
                    begin
                        Grp.Get('NONE');
                    end;
                }
                field(DdFlow; Rec.SumAmt) { ApplicationArea = All; }
                field(LkWhere; Rec.P2) { ApplicationArea = All; TableRelation = "LT PX Grp".Code where(Descr = const('Open')); }
                field(LkCond; Rec.P3) { ApplicationArea = All; TableRelation = if (Kind = const(A)) "LT PX Grp".Code else "LT PX Grp2".Code; }
                field(LkOverRel; Rec.G2f) { ApplicationArea = All; TableRelation = "LT PX Grp2".Code; }
                field(LkOverTrig; Rec.LkTrig) { ApplicationArea = All; TableRelation = "LT PX Grp".Code; }
                field(LkDiffPage; Rec.P4) { ApplicationArea = All; TableRelation = "LT PX Grp".Code; LookupPageId = "LT PX Grp Alt List"; }
                field(LkOnlyDd; Rec.P5) { ApplicationArea = All; TableRelation = "LT PX Grp2".Code; }
                field(LkNone; Rec.P6) { ApplicationArea = All; TableRelation = "LT PX Grp3".Code; }
                field(LkOtherTable; Rec.P7) { ApplicationArea = All; TableRelation = "LT PX Grp".Code; LookupPageId = "LT PX Ent List"; }
                field(LkPageOverRel; Rec.G3f) { ApplicationArea = All; LookupPageId = "LT PX Grp Alt List"; }
                field(LkPlainRel; Rec.P1) { ApplicationArea = All; TableRelation = "LT PX Grp".Code; }
                field(LkPlainRelEmpty; Rec.P9) { ApplicationArea = All; TableRelation = "LT PX Grp".Code; }
                field(SharedFirst; Rec.Plain) { ApplicationArea = All; TableRelation = "LT PX Grp".Code where(Descr = const('Open')); }
                field(SharedSecond; Rec.Plain) { ApplicationArea = All; TableRelation = "LT PX Grp2".Code; }
            }
        }
    }
}

page 86195 "LT PX Cap Card"
{
    PageType = Card;
    SourceTable = "LT PX CapRow";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(CapPlain; Rec.CapFld) { ApplicationArea = All; }
                field(CapOver; Rec.CapFld2) { ApplicationArea = All; Caption = 'Control caption'; }
                field(ExprCC; ExprVal) { ApplicationArea = All; CaptionClass = 'LTPX,' + CcState.GetText(); }
                field(SetMe; SetMeVal) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refill)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        CcState: Codeunit "LT PX CC State";
        ExprVal: Text;
        SetMeVal: Text;
}

codeunit 86196 "LT PX Nav Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
    end;

    procedure Filters(var Grp: Record "LT PX Grp"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Grp);
        exit(RefFilters(RecRef));
    end;

    procedure RefFilters(var RecRef: RecordRef): Text
    var
        Result: Text;
        i: Integer;
    begin
        for i := 0 to 9 do begin
            RecRef.FilterGroup(i);
            if RecRef.GetFilters() <> '' then
                Result += ' g' + Format(i) + '=' + RecRef.GetFilters();
        end;
        RecRef.FilterGroup(0);
        exit(Result);
    end;
}

codeunit 86197 "LT PX CC State"
{
    SingleInstance = true;

    var
        Value: Text;

    procedure SetText(NewValue: Text)
    begin
        Value := NewValue;
    end;

    procedure GetText(): Text
    begin
        exit(Value);
    end;
}

codeunit 86198 "LT PX CC Subscriber"
{
    EventSubscriberInstance = Manual;

    var
        Calls: Text;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Calls;
        Calls := '';
        exit(Result);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', false, false)]
    local procedure OnResolve(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if CaptionArea <> 'LTPX' then
            exit;
        Calls += '[' + CaptionExpr + ']';
        Caption := 'res:' + CaptionExpr;
        Resolved := true;
    end;
}

codeunit 86199 "LT PX Cap Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Itm: Record "LT PX CapRow";
    begin
        Itm.DeleteAll();
        Itm."No." := 'I1';
        Itm.Insert();
    end;

    [Test]
    procedure PX_ControlCaption_OverFieldCaptionClass()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "LT PX CC Subscriber";
        State: Codeunit "LT PX CC State";
        Pg: TestPage "LT PX Cap Card";
    begin
        Seed();
        State.SetText('T1');
        BindSubscription(Subscriber);
        Pg.OpenEdit();
        Subscriber.Take();
        Observer.Observe('first', Pg.CapOver.Caption());
        Observer.Observe('first_events', Subscriber.Take());
        Observer.Observe('second', Pg.CapOver.Caption());
        Observer.Observe('second_events', Subscriber.Take());
        Pg.Close();
        UnbindSubscription(Subscriber);
        Observer.Finish();
    end;

    [Test]
    procedure PX_FieldCaptionClass_ReadTwice()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "LT PX CC Subscriber";
        State: Codeunit "LT PX CC State";
        Pg: TestPage "LT PX Cap Card";
    begin
        Seed();
        State.SetText('T2');
        BindSubscription(Subscriber);
        Pg.OpenEdit();
        Observer.Observe('open_events', Subscriber.Take());
        Observer.Observe('first', Pg.CapPlain.Caption());
        Observer.Observe('first_events', Subscriber.Take());
        Observer.Observe('second', Pg.CapPlain.Caption());
        Observer.Observe('second_events', Subscriber.Take());
        Pg.SetMe.SetValue('x');
        Observer.Observe('setvalue_events', Subscriber.Take());
        Observer.Observe('third', Pg.CapPlain.Caption());
        Observer.Observe('third_events', Subscriber.Take());
        Pg.Close();
        UnbindSubscription(Subscriber);
        Observer.Finish();
    end;

    [Test]
    procedure PX_ExpressionCaption_SameTextAtRefill()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "LT PX CC Subscriber";
        State: Codeunit "LT PX CC State";
        Pg: TestPage "LT PX Cap Card";
    begin
        Seed();
        State.SetText('T3');
        BindSubscription(Subscriber);
        Pg.OpenEdit();
        Observer.Observe('open_events', Subscriber.Take());
        Observer.Observe('open_caption', Pg.ExprCC.Caption());
        Pg.Refill.Invoke();
        Observer.Observe('action_events', Subscriber.Take());
        Observer.Observe('action_caption', Pg.ExprCC.Caption());
        Pg.SetMe.SetValue('y');
        Observer.Observe('setvalue_events', Subscriber.Take());
        Observer.Observe('setvalue_caption', Pg.ExprCC.Caption());
        Pg.Close();
        UnbindSubscription(Subscriber);
        Observer.Finish();
    end;

    [Test]
    procedure PX_ExpressionCaption_ChangedSinceFill()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "LT PX CC Subscriber";
        State: Codeunit "LT PX CC State";
        Pg: TestPage "LT PX Cap Card";
    begin
        Seed();
        State.SetText('T4a');
        BindSubscription(Subscriber);
        Pg.OpenEdit();
        Observer.Observe('open_events', Subscriber.Take());
        State.SetText('T4b');
        Observer.Observe('changed_caption', Pg.ExprCC.Caption());
        Observer.Observe('changed_events', Subscriber.Take());
        Pg.Refill.Invoke();
        Observer.Observe('action_events', Subscriber.Take());
        Observer.Observe('action_caption', Pg.ExprCC.Caption());
        State.SetText('T4a');
        Pg.SetMe.SetValue('z');
        Observer.Observe('back_events', Subscriber.Take());
        Observer.Observe('back_caption', Pg.ExprCC.Caption());
        Pg.Close();
        UnbindSubscription(Subscriber);
        Observer.Finish();
    end;
}

codeunit 86200 "LT PX Nav Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT PX Nav Log";

    local procedure Seed()
    var
        Itm: Record "LT PX Itm";
        Grp: Record "LT PX Grp";
        Grp2: Record "LT PX Grp2";
        Grp3: Record "LT PX Grp3";
        Ent: Record "LT PX Ent";
    begin
        Itm.DeleteAll();
        Grp.DeleteAll();
        Grp2.DeleteAll();
        Grp3.DeleteAll();
        Ent.DeleteAll();
        AddGrp('G1', 'Open');
        AddGrp('G2', 'Closed');
        AddGrp('G3', 'Open');
        Grp2.Code := 'H1';
        Grp2.Insert();
        Grp2.Code := 'H2';
        Grp2.Insert();
        Grp3.Code := 'K1';
        Grp3.Insert();
        AddEnt(1, 'G2', 10, DMY2Date(5, 1, 2025));
        AddEnt(2, 'G2', 20, DMY2Date(5, 2, 2025));
        AddEnt(3, 'G1', 5, DMY2Date(10, 1, 2025));
        AddEnt(4, 'G2', 7, DMY2Date(20, 1, 2025));
        Itm."No." := 'I1';
        Itm.Grp := 'G2';
        Itm.Plain := 'G2';
        Itm.LkTrig := 'G2';
        Itm.P1 := 'G2';
        Itm.P2 := 'G2';
        Itm.P3 := 'G2';
        Itm.P4 := 'G2';
        Itm.P5 := 'G2';
        Itm.P6 := 'G2';
        Itm.P7 := 'G2';
        Itm.P8 := 'G2';
        Itm.G2f := 'G2';
        Itm.G3f := 'G2';
        Itm.G4f := 'G2';
        Itm.Insert();
        Log.Take();
    end;

    local procedure AddGrp(C: Code[10]; D: Text[30])
    var
        Grp: Record "LT PX Grp";
    begin
        Grp.Code := C;
        Grp.Descr := D;
        Grp.Insert();
    end;

    local procedure AddEnt(E: Integer; G: Code[10]; A: Decimal; D: Date)
    var
        Ent: Record "LT PX Ent";
    begin
        Ent.Entry := E;
        Ent.Grp := G;
        Ent.Amount := A;
        Ent.Day := D;
        Ent.Insert();
    end;

    local procedure Stored(Which: Text): Text
    var
        Itm: Record "LT PX Itm";
    begin
        Itm.Get('I1');
        case Which of
            'DdNoRel':
                exit(Itm.P8);
            'DdRel':
                exit(Itm.G4f);
            'DdBoth':
                exit(Format(Itm.Qty));
            'DdErr':
                exit(Format(Itm.Qty2));
            'DdFlow':
                exit(Format(Itm.Qty));
            'GrpCtl':
                exit(Itm.Grp);
            'LkWhere':
                exit(Itm.P2);
            'LkCond':
                exit(Itm.P3);
            'LkOverRel':
                exit(Itm.G2f);
            'LkOverTrig':
                exit(Itm.LkTrig);
            'LkDiffPage':
                exit(Itm.P4);
            'LkOnlyDd':
                exit(Itm.P5);
            'LkNone':
                exit(Itm.P6);
            'LkOtherTable':
                exit(Itm.P7);
            'LkPageOverRel':
                exit(Itm.G3f);
            'LkPlainRel':
                exit(Itm.P1);
            'LkPlainRelEmpty':
                exit(Itm.P9);
            'SharedSecond':
                exit(Itm.Plain);
        end;
    end;

    [PageHandler]
    procedure GrpPage(var P: TestPage "LT PX Grp List")
    var
        Rows: Text;
    begin
        Rows := 'page grp cur=' + P.CodeCtl.Value() + ' rows=';
        if P.First() then
            repeat
                Rows += P.CodeCtl.Value() + ',';
            until not P.Next();
        Log.Add(Rows);
    end;

    [PageHandler]
    procedure EntPage(var P: TestPage "LT PX Ent List")
    var
        Rows: Text;
    begin
        Rows := 'page ent cur=' + P.EntryCtl.Value() + ' rows=';
        if P.First() then
            repeat
                Rows += P.EntryCtl.Value() + ',';
            until not P.Next();
        Log.Add(Rows);
    end;

    [ModalPageHandler]
    procedure GrpModal(var P: TestPage "LT PX Grp List")
    var
        Rows: Text;
    begin
        Rows := 'modal grp cur=' + P.CodeCtl.Value() + ' rows=';
        if P.First() then
            repeat
                Rows += P.CodeCtl.Value() + ',';
            until not P.Next();
        P.Last();
        Log.Add(Rows + ' pick=' + P.CodeCtl.Value());
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure GrpAltModal(var P: TestPage "LT PX Grp Alt List")
    var
        Rows: Text;
    begin
        Rows := 'modal grpalt cur=' + P.CodeCtl.Value() + ' rows=';
        if P.First() then
            repeat
                Rows += P.CodeCtl.Value() + ',';
            until not P.Next();
        P.Last();
        Log.Add(Rows + ' pick=' + P.CodeCtl.Value());
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure Grp2Modal(var P: TestPage "LT PX Grp2 List")
    var
        Rows: Text;
    begin
        Rows := 'modal grp2 cur=' + P.CodeCtl.Value() + ' rows=';
        if P.First() then
            repeat
                Rows += P.CodeCtl.Value() + ',';
            until not P.Next();
        P.Last();
        Log.Add(Rows + ' pick=' + P.CodeCtl.Value());
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EntModal(var P: TestPage "LT PX Ent List")
    var
        Rows: Text;
    begin
        Rows := 'modal ent cur=' + P.EntryCtl.Value() + ' rows=';
        if P.First() then
            repeat
                Rows += P.EntryCtl.Value() + ',';
            until not P.Next();
        P.Last();
        Log.Add(Rows + ' pick=' + P.EntryCtl.Value());
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryNav(var Card: TestPage "LT PX Nav Card"; Which: Text)
    begin
        case Which of
            'DdNoRel':
                Card.DdNoRel.Drilldown();
            'DdRel':
                Card.DdRel.Drilldown();
            'DdBoth':
                Card.DdBoth.Drilldown();
            'DdErr':
                Card.DdErr.Drilldown();
            'DdFlow':
                Card.DdFlow.Drilldown();
            'GrpCtl':
                Card.GrpCtl.Lookup();
            'LkWhere':
                Card.LkWhere.Lookup();
            'LkCond':
                Card.LkCond.Lookup();
            'LkOverRel':
                Card.LkOverRel.Lookup();
            'LkOverTrig':
                Card.LkOverTrig.Lookup();
            'LkDiffPage':
                Card.LkDiffPage.Lookup();
            'LkOnlyDd':
                Card.LkOnlyDd.Lookup();
            'LkNone':
                Card.LkNone.Lookup();
            'LkOtherTable':
                Card.LkOtherTable.Lookup();
            'LkPageOverRel':
                Card.LkPageOverRel.Lookup();
            'LkPlainRel':
                Card.LkPlainRel.Lookup();
            'LkPlainRelEmpty':
                Card.LkPlainRelEmpty.Lookup();
            'SharedSecond':
                Card.SharedSecond.Lookup();
        end;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Which: Text; Kind: Integer)
    var
        Itm: Record "LT PX Itm";
        Card: TestPage "LT PX Nav Card";
        Ok: Boolean;
    begin
        Seed();
        if Kind = 1 then begin
            Itm.Get('I1');
            Itm.Kind := Itm.Kind::B;
            Itm.Modify();
        end;
        Itm.Get('I1');
        Itm.SetFilter("Date Filter", '%1..%2', DMY2Date(1, 1, 2025), DMY2Date(31, 1, 2025));
        if Kind = 2 then begin
            Which += '@openedit';
            Card.OpenEdit();
        end else begin
            Card.Trap();
            Page.Run(Page::"LT PX Nav Card", Itm);
        end;
        ClearLastError();
        Ok := TryNav(Card, Which.Replace('@openedit', ''));
        Observer.Observe(Which + ':ok', Format(Ok));
        if not Ok then
            Observer.ObserveError(Which + ':err');
        Observer.Observe(Which + ':log', Log.Take());
        Card.Close();
        Observer.Observe(Which + ':stored', Stored(Which.Replace('@openedit', '')));
    end;

    [Test]
    [HandlerFunctions('GrpPage,EntPage')]
    procedure PX_DrillDowns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'DdNoRel', 0);
        Probe(Observer, 'DdNoRel', 2);
        Probe(Observer, 'DdRel', 0);
        Probe(Observer, 'DdRel', 2);
        Probe(Observer, 'DdBoth', 0);
        Probe(Observer, 'DdErr', 0);
        Probe(Observer, 'DdFlow', 0);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GrpModal,GrpAltModal,Grp2Modal,EntModal')]
    procedure PX_ControlLookups()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'GrpCtl', 0);
        Probe(Observer, 'LkPlainRel', 0);
        Probe(Observer, 'LkWhere', 0);
        Probe(Observer, 'LkCond', 0);
        Probe(Observer, 'LkCond', 1);
        Probe(Observer, 'LkOverRel', 0);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GrpModal,GrpAltModal,Grp2Modal,EntModal')]
    procedure PX_ControlLookups2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'LkOverTrig', 0);
        Probe(Observer, 'LkDiffPage', 0);
        Probe(Observer, 'LkOnlyDd', 0);
        Probe(Observer, 'LkNone', 0);
        Probe(Observer, 'LkOtherTable', 0);
        Probe(Observer, 'LkPageOverRel', 0);
        Probe(Observer, 'LkPlainRelEmpty', 0);
        Probe(Observer, 'SharedSecond', 0);
        Observer.Finish();
    end;

    [Test]
    procedure PX_ClosingDatesOffOverClosingField()
    var
        Observer: Codeunit "Probe Observer";
        Itm: Record "LT PX Itm";
        Card: TestPage "LT PX Nav Card";
    begin
        Seed();
        Itm.Get('I1');
        Itm.Closing := ClosingDate(DMY2Date(31, 12, 2025));
        Itm.Modify();
        Card.OpenEdit();
        Observer.Observe('off_value', Card.ClosingOff.Value());
        Observer.Observe('on_value', Card.ClosingOn.Value());
        Card.Close();
        Observer.Observe('off_set_C', TrySet(1, 'C12/31/2025'));
        Observer.Observe('off_set_c', TrySet(1, 'c12/31/2025'));
        Observer.Observe('on_set_c', TrySet(2, 'c12/31/2025'));
        Observer.Observe('on_set_plain', TrySet(2, '12/30/2025'));
        Observer.Finish();
    end;

    local procedure TrySet(Ctl: Integer; NewValue: Text): Text
    var
        Itm: Record "LT PX Itm";
        Card: TestPage "LT PX Nav Card";
        Result: Text;
    begin
        Itm.Get('I1');
        Itm.Closing := 0D;
        Itm.Modify();
        Card.OpenEdit();
        ClearLastError();
        if TrySetValue(Card, Ctl, NewValue) then
            Result := 'ok'
        else
            Result := 'err ' + GetLastErrorCode() + ' ' + GetLastErrorText();
        Result += ' | off=' + Card.ClosingOff.Value() + ' on=' + Card.ClosingOn.Value();
        Card.Close();
        Itm.Get('I1');
        Result += ' | stored=' + Format(Itm.Closing);
        if Itm.Closing <> 0D then
            Result += ' closing=' + Format(Itm.Closing = ClosingDate(NormalDate(Itm.Closing)));
        exit(Result);
    end;

    [TryFunction]
    local procedure TrySetValue(var Card: TestPage "LT PX Nav Card"; Ctl: Integer; NewValue: Text)
    begin
        if Ctl = 1 then
            Card.ClosingOff.SetValue(NewValue)
        else
            Card.ClosingOn.SetValue(NewValue);
    end;
}
