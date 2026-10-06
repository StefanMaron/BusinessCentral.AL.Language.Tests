// PROBE REVISION: every test records what it observed and ends in Error(<observations>).
// Written by agent stma-auto-7, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4920.

table 69600 "AFT Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Amount; Decimal) { }
        field(3; Boom; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 69600 "AFT Card"
{
    PageType = Card;
    SourceTable = "AFT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(OkCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = OkFormat();
            }
            field(FailingCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = FailingFormat();
            }
            field(TypeOnlyCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
            }
            field(HiddenFailingCtl; Rec.Amount)
            {
                ApplicationArea = All;
                Visible = false;
                AutoFormatType = 10;
                AutoFormatExpression = FailingFormat();
            }
            field(RowFailingCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = RowFormat();
            }
        }
    }

    local procedure OkFormat(): Text
    begin
        exit('<Precision,3:3><Standard Format,0>');
    end;

    local procedure FailingFormat(): Text
    begin
        Error('AFT format expression failed');
    end;

    local procedure RowFormat(): Text
    begin
        if Rec.Boom then
            Error('AFT row format failed for %1', Rec."No.");
        exit('<Precision,3:3><Standard Format,0>');
    end;
}

page 69601 "AFT List"
{
    PageType = List;
    SourceTable = "AFT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(RowFailingCtl; Rec.Amount)
                {
                    ApplicationArea = All;
                    AutoFormatType = 10;
                    AutoFormatExpression = RowFormat();
                }
                field(AlwaysFailingCtl; Rec.Amount)
                {
                    ApplicationArea = All;
                    AutoFormatType = 10;
                    AutoFormatExpression = FailingFormat();
                }
            }
        }
    }

    local procedure FailingFormat(): Text
    begin
        Error('AFT list format expression failed');
    end;

    local procedure RowFormat(): Text
    begin
        if Rec.Boom then
            Error('AFT list row format failed for %1', Rec."No.");
        exit('<Precision,3:3><Standard Format,0>');
    end;
}

page 69602 "AFT Caption Card"
{
    PageType = Card;
    SourceTable = "AFT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(OkCaptionCtl; Rec.Amount)
            {
                ApplicationArea = All;
                CaptionClass = OkCaption();
            }
            field(FailingCaptionCtl; Rec.Amount)
            {
                ApplicationArea = All;
                CaptionClass = FailingCaption();
            }
        }
    }

    local procedure OkCaption(): Text
    begin
        exit('3,Ok Caption');
    end;

    local procedure FailingCaption(): Text
    begin
        Error('AFT caption class expression failed');
    end;
}

codeunit 69600 "AFT Probe Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "AFT Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'A';
        Row.Amount := 7;
        Row.Insert();
        Row.Init();
        Row."No." := 'B';
        Row.Amount := 8;
        Row.Boom := true;
        Row.Insert();
        Row.Init();
        Row."No." := 'C';
        Row.Amount := 9;
        Row.Insert();
    end;

    local procedure Res(Label: Text; Ok: Boolean; Shown: Text): Text
    begin
        if Ok then
            exit(Label + '=OK[' + Shown + '] ');
        exit(Label + '=ERR[' + GetLastErrorText() + '] ');
    end;

    // ---- card ----
    [TryFunction]
    local procedure TryOpenCard(var Card: TestPage "AFT Card")
    begin
        Card.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenCardEdit(var Card: TestPage "AFT Card")
    begin
        Card.OpenEdit();
    end;

    [TryFunction]
    local procedure TryCardNo(var Card: TestPage "AFT Card"; var V: Text)
    begin
        V := Card.NoCtl.Value();
    end;

    [TryFunction]
    local procedure TryCardOk(var Card: TestPage "AFT Card"; var V: Text)
    begin
        V := Card.OkCtl.Value();
    end;

    [TryFunction]
    local procedure TryCardFailing(var Card: TestPage "AFT Card"; var V: Text)
    begin
        V := Card.FailingCtl.Value();
    end;

    [TryFunction]
    local procedure TryCardTypeOnly(var Card: TestPage "AFT Card"; var V: Text)
    begin
        V := Card.TypeOnlyCtl.Value();
    end;

    [TryFunction]
    local procedure TryCardHidden(var Card: TestPage "AFT Card"; var V: Text)
    begin
        V := Card.HiddenFailingCtl.Value();
    end;

    [TryFunction]
    local procedure TryCardRow(var Card: TestPage "AFT Card"; var V: Text)
    begin
        V := Card.RowFailingCtl.Value();
    end;

    [TryFunction]
    local procedure TryCardGoTo(var Card: TestPage "AFT Card"; KeyValue: Code[20])
    begin
        Card.GoToKey(KeyValue);
    end;

    [TryFunction]
    local procedure TryCardClose(var Card: TestPage "AFT Card")
    begin
        Card.Close();
    end;

    local procedure ObsCard(var Card: TestPage "AFT Card"; Prefix: Text): Text
    var
        V: Text;
        Obs: Text;
        Ok: Boolean;
    begin
        Ok := TryCardNo(Card, V);
        Obs += Res(Prefix + 'No', Ok, V);
        Ok := TryCardOk(Card, V);
        Obs += Res(Prefix + 'Ok', Ok, V);
        Ok := TryCardTypeOnly(Card, V);
        Obs += Res(Prefix + 'TypeOnly', Ok, V);
        Ok := TryCardHidden(Card, V);
        Obs += Res(Prefix + 'Hidden', Ok, V);
        Ok := TryCardRow(Card, V);
        Obs += Res(Prefix + 'Row', Ok, V);
        Ok := TryCardFailing(Card, V);
        Obs += Res(Prefix + 'Failing', Ok, V);
        exit(Obs);
    end;

    [Test]
    procedure P1_Card_OpenView_ThenReadOthersFirst()
    var
        Card: TestPage "AFT Card";
        Obs: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := TryOpenCard(Card);
        Obs += Res('OpenView', Ok, '');
        Obs += ObsCard(Card, 'r1.');
        Obs += ObsCard(Card, 'r2.');
        Ok := TryCardClose(Card);
        Obs += Res('Close', Ok, '');
        Error(Obs);
    end;

    [Test]
    procedure P2_Card_OpenEdit_ThenReadOthersFirst()
    var
        Card: TestPage "AFT Card";
        Obs: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := TryOpenCardEdit(Card);
        Obs += Res('OpenEdit', Ok, '');
        Obs += ObsCard(Card, 'r1.');
        Ok := TryCardClose(Card);
        Obs += Res('Close', Ok, '');
        Error(Obs);
    end;

    [Test]
    procedure P3_Card_RowDependent_GoToKey()
    var
        Card: TestPage "AFT Card";
        Obs: Text;
        Ok: Boolean;
        V: Text;
    begin
        Seed();
        Ok := TryOpenCard(Card);
        Obs += Res('OpenView(A)', Ok, '');
        Ok := TryCardRow(Card, V);
        Obs += Res('RowA', Ok, V);
        Ok := TryCardGoTo(Card, 'B');
        Obs += Res('GoToKeyB', Ok, '');
        Ok := TryCardNo(Card, V);
        Obs += Res('NoAtB', Ok, V);
        Ok := TryCardOk(Card, V);
        Obs += Res('OkAtB', Ok, V);
        Ok := TryCardRow(Card, V);
        Obs += Res('RowAtB', Ok, V);
        Ok := TryCardGoTo(Card, 'C');
        Obs += Res('GoToKeyC', Ok, '');
        Ok := TryCardRow(Card, V);
        Obs += Res('RowAtC', Ok, V);
        Error(Obs);
    end;

    [Test]
    procedure P4_Card_OpenOnFailingRow()
    var
        Card: TestPage "AFT Card";
        Row: Record "AFT Row";
        Obs: Text;
        Ok: Boolean;
        V: Text;
    begin
        Seed();
        Row.Get('A');
        Row.Delete();
        Ok := TryOpenCard(Card);
        Obs += Res('OpenView(first=B)', Ok, '');
        Ok := TryCardNo(Card, V);
        Obs += Res('NoAtB', Ok, V);
        Ok := TryCardOk(Card, V);
        Obs += Res('OkAtB', Ok, V);
        Ok := TryCardRow(Card, V);
        Obs += Res('RowAtB', Ok, V);
        Error(Obs);
    end;

    // ---- list ----
    [TryFunction]
    local procedure TryOpenList(var Lst: TestPage "AFT List")
    begin
        Lst.OpenView();
    end;

    [TryFunction]
    local procedure TryListNo(var Lst: TestPage "AFT List"; var V: Text)
    begin
        V := Lst.NoCtl.Value();
    end;

    [TryFunction]
    local procedure TryListRow(var Lst: TestPage "AFT List"; var V: Text)
    begin
        V := Lst.RowFailingCtl.Value();
    end;

    [TryFunction]
    local procedure TryListAlways(var Lst: TestPage "AFT List"; var V: Text)
    begin
        V := Lst.AlwaysFailingCtl.Value();
    end;

    [TryFunction]
    local procedure TryListNext(var Lst: TestPage "AFT List"; var Moved: Boolean)
    begin
        Moved := Lst.Next();
    end;

    [TryFunction]
    local procedure TryListFirst(var Lst: TestPage "AFT List"; var Moved: Boolean)
    begin
        Moved := Lst.First();
    end;

    local procedure ObsList(var Lst: TestPage "AFT List"; Prefix: Text): Text
    var
        V: Text;
        Obs: Text;
        Ok: Boolean;
    begin
        Ok := TryListNo(Lst, V);
        Obs += Res(Prefix + 'No', Ok, V);
        Ok := TryListRow(Lst, V);
        Obs += Res(Prefix + 'Row', Ok, V);
        Ok := TryListAlways(Lst, V);
        Obs += Res(Prefix + 'Always', Ok, V);
        exit(Obs);
    end;

    [Test]
    procedure P5_List_OpenThenWalkRows()
    var
        Lst: TestPage "AFT List";
        Obs: Text;
        Ok: Boolean;
        Moved: Boolean;
    begin
        Seed();
        Ok := TryOpenList(Lst);
        Obs += Res('OpenView', Ok, '');
        Obs += ObsList(Lst, 'A.');
        Ok := TryListNext(Lst, Moved);
        Obs += Res('Next->B', Ok, Format(Moved));
        Obs += ObsList(Lst, 'B.');
        Ok := TryListNext(Lst, Moved);
        Obs += Res('Next->C', Ok, Format(Moved));
        Obs += ObsList(Lst, 'C.');
        Ok := TryListFirst(Lst, Moved);
        Obs += Res('First->A', Ok, Format(Moved));
        Obs += ObsList(Lst, 'A2.');
        Error(Obs);
    end;

    [Test]
    procedure P6_List_OnlyFailingRowExists()
    var
        Lst: TestPage "AFT List";
        Row: Record "AFT Row";
        Obs: Text;
        Ok: Boolean;
    begin
        Seed();
        Row.Get('A');
        Row.Delete();
        Row.Get('C');
        Row.Delete();
        Ok := TryOpenList(Lst);
        Obs += Res('OpenView(only B)', Ok, '');
        Obs += ObsList(Lst, 'B.');
        Error(Obs);
    end;

    // ---- CaptionClass expression that raises ----
    [TryFunction]
    local procedure TryOpenCaption(var Card: TestPage "AFT Caption Card")
    begin
        Card.OpenView();
    end;

    [TryFunction]
    local procedure TryCaptionNo(var Card: TestPage "AFT Caption Card"; var V: Text)
    begin
        V := Card.NoCtl.Value();
    end;

    [TryFunction]
    local procedure TryCaptionOkCaption(var Card: TestPage "AFT Caption Card"; var V: Text)
    begin
        V := Card.OkCaptionCtl.Caption();
    end;

    [TryFunction]
    local procedure TryCaptionFailingCaption(var Card: TestPage "AFT Caption Card"; var V: Text)
    begin
        V := Card.FailingCaptionCtl.Caption();
    end;

    [TryFunction]
    local procedure TryCaptionFailingValue(var Card: TestPage "AFT Caption Card"; var V: Text)
    begin
        V := Card.FailingCaptionCtl.Value();
    end;

    [Test]
    procedure P7_CaptionClass_RaisingExpression()
    var
        Card: TestPage "AFT Caption Card";
        Obs: Text;
        Ok: Boolean;
        V: Text;
    begin
        Seed();
        Ok := TryOpenCaption(Card);
        Obs += Res('OpenView', Ok, '');
        Ok := TryCaptionNo(Card, V);
        Obs += Res('No', Ok, V);
        Ok := TryCaptionOkCaption(Card, V);
        Obs += Res('OkCaption', Ok, V);
        Ok := TryCaptionFailingValue(Card, V);
        Obs += Res('FailingValue', Ok, V);
        Ok := TryCaptionFailingCaption(Card, V);
        Obs += Res('FailingCaption', Ok, V);
        Ok := TryCaptionFailingCaption(Card, V);
        Obs += Res('FailingCaption2', Ok, V);
        Error(Obs);
    end;
}
