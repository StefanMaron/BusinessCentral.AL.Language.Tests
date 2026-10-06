// PROBE REVISION 2: every test records what it observed and ends in Error(<observations>).
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

page 69600 "AFT Always Card"
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
}

page 69601 "AFT TypeOnly Card"
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
            field(TypeOnlyCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
            }
            field(OkCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = OkFormat();
            }
        }
    }

    local procedure OkFormat(): Text
    begin
        exit('<Precision,3:3><Standard Format,0>');
    end;
}

page 69602 "AFT Hidden Card"
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
            field(HiddenFailingCtl; Rec.Amount)
            {
                ApplicationArea = All;
                Visible = false;
                AutoFormatType = 10;
                AutoFormatExpression = FailingFormat();
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
}

page 69603 "AFT Row Card"
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
            field(RowCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = RowFormat();
            }
        }
    }

    local procedure RowFormat(): Text
    begin
        if Rec.Boom then
            Error('AFT row format failed for %1', Rec."No.");
        exit('<Precision,3:3><Standard Format,0>');
    end;
}

page 69604 "AFT Row List"
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
                field(RowCtl; Rec.Amount)
                {
                    ApplicationArea = All;
                    AutoFormatType = 10;
                    AutoFormatExpression = RowFormat();
                }
            }
        }
    }

    local procedure RowFormat(): Text
    begin
        if Rec.Boom then
            Error('AFT row format failed for %1', Rec."No.");
        exit('<Precision,3:3><Standard Format,0>');
    end;
}

page 69605 "AFT Always List"
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
                field(AlwaysCtl; Rec.Amount)
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
        Error('AFT format expression failed');
    end;
}

page 69606 "AFT Type1 Card"
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
            field(Type1Ctl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 1;
                AutoFormatExpression = FailingFormat();
            }
        }
    }

    local procedure FailingFormat(): Text
    begin
        Error('AFT format expression failed');
    end;
}

page 69607 "AFT Caption Card"
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

    var
        HandlerRan: Boolean;
        HandlerObs: Text;

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

    [TryFunction]
    local procedure TryAlwaysOpenView(var P: TestPage "AFT Always Card")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryAlwaysOpenEdit(var P: TestPage "AFT Always Card")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryAlwaysOpenNew(var P: TestPage "AFT Always Card")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryAlwaysNoCtl(var P: TestPage "AFT Always Card"; var V: Text)
    begin
        V := P.NoCtl.Value();
    end;

    [TryFunction]
    local procedure TryAlwaysOkCtl(var P: TestPage "AFT Always Card"; var V: Text)
    begin
        V := P.OkCtl.Value();
    end;

    [TryFunction]
    local procedure TryAlwaysFailingCtl(var P: TestPage "AFT Always Card"; var V: Text)
    begin
        V := P.FailingCtl.Value();
    end;

    [TryFunction]
    local procedure TryAlwaysClose(var P: TestPage "AFT Always Card")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryTypeOnlyOpenView(var P: TestPage "AFT TypeOnly Card")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryTypeOnlyNoCtl(var P: TestPage "AFT TypeOnly Card"; var V: Text)
    begin
        V := P.NoCtl.Value();
    end;

    [TryFunction]
    local procedure TryTypeOnlyTypeOnlyCtl(var P: TestPage "AFT TypeOnly Card"; var V: Text)
    begin
        V := P.TypeOnlyCtl.Value();
    end;

    [TryFunction]
    local procedure TryTypeOnlyOkCtl(var P: TestPage "AFT TypeOnly Card"; var V: Text)
    begin
        V := P.OkCtl.Value();
    end;

    [TryFunction]
    local procedure TryTypeOnlyClose(var P: TestPage "AFT TypeOnly Card")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryHiddenOpenView(var P: TestPage "AFT Hidden Card")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryHiddenNoCtl(var P: TestPage "AFT Hidden Card"; var V: Text)
    begin
        V := P.NoCtl.Value();
    end;

    [TryFunction]
    local procedure TryHiddenOkCtl(var P: TestPage "AFT Hidden Card"; var V: Text)
    begin
        V := P.OkCtl.Value();
    end;

    [TryFunction]
    local procedure TryHiddenHiddenFailingCtl(var P: TestPage "AFT Hidden Card"; var V: Text)
    begin
        V := P.HiddenFailingCtl.Value();
    end;

    [TryFunction]
    local procedure TryHiddenClose(var P: TestPage "AFT Hidden Card")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryRowCardOpenView(var P: TestPage "AFT Row Card")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryRowCardNoCtl(var P: TestPage "AFT Row Card"; var V: Text)
    begin
        V := P.NoCtl.Value();
    end;

    [TryFunction]
    local procedure TryRowCardRowCtl(var P: TestPage "AFT Row Card"; var V: Text)
    begin
        V := P.RowCtl.Value();
    end;

    [TryFunction]
    local procedure TryRowCardClose(var P: TestPage "AFT Row Card")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryRowCardGoTo(var P: TestPage "AFT Row Card"; KeyValue: Code[20])
    begin
        P.GoToKey(KeyValue);
    end;

    [TryFunction]
    local procedure TryRowListOpenView(var P: TestPage "AFT Row List")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryRowListNoCtl(var P: TestPage "AFT Row List"; var V: Text)
    begin
        V := P.NoCtl.Value();
    end;

    [TryFunction]
    local procedure TryRowListRowCtl(var P: TestPage "AFT Row List"; var V: Text)
    begin
        V := P.RowCtl.Value();
    end;

    [TryFunction]
    local procedure TryRowListClose(var P: TestPage "AFT Row List")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryRowListNext(var P: TestPage "AFT Row List"; var Moved: Boolean)
    begin
        Moved := P.Next();
    end;

    [TryFunction]
    local procedure TryRowListFirst(var P: TestPage "AFT Row List"; var Moved: Boolean)
    begin
        Moved := P.First();
    end;

    [TryFunction]
    local procedure TryRowListLast(var P: TestPage "AFT Row List"; var Moved: Boolean)
    begin
        Moved := P.Last();
    end;

    [TryFunction]
    local procedure TryAlwaysListOpenView(var P: TestPage "AFT Always List")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryAlwaysListNoCtl(var P: TestPage "AFT Always List"; var V: Text)
    begin
        V := P.NoCtl.Value();
    end;

    [TryFunction]
    local procedure TryAlwaysListAlwaysCtl(var P: TestPage "AFT Always List"; var V: Text)
    begin
        V := P.AlwaysCtl.Value();
    end;

    [TryFunction]
    local procedure TryAlwaysListClose(var P: TestPage "AFT Always List")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryAlwaysListNext(var P: TestPage "AFT Always List"; var Moved: Boolean)
    begin
        Moved := P.Next();
    end;

    [TryFunction]
    local procedure TryAlwaysListFirst(var P: TestPage "AFT Always List"; var Moved: Boolean)
    begin
        Moved := P.First();
    end;

    [TryFunction]
    local procedure TryAlwaysListLast(var P: TestPage "AFT Always List"; var Moved: Boolean)
    begin
        Moved := P.Last();
    end;

    [TryFunction]
    local procedure TryType1OpenView(var P: TestPage "AFT Type1 Card")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryType1NoCtl(var P: TestPage "AFT Type1 Card"; var V: Text)
    begin
        V := P.NoCtl.Value();
    end;

    [TryFunction]
    local procedure TryType1Type1Ctl(var P: TestPage "AFT Type1 Card"; var V: Text)
    begin
        V := P.Type1Ctl.Value();
    end;

    [TryFunction]
    local procedure TryType1Close(var P: TestPage "AFT Type1 Card")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryCaptionOpenView(var P: TestPage "AFT Caption Card")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryCaptionNoCtl(var P: TestPage "AFT Caption Card"; var V: Text)
    begin
        V := P.NoCtl.Value();
    end;

    [TryFunction]
    local procedure TryCaptionClose(var P: TestPage "AFT Caption Card")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryCaptionOkCaption(var P: TestPage "AFT Caption Card"; var V: Text)
    begin
        V := P.OkCaptionCtl.Caption();
    end;

    [TryFunction]
    local procedure TryCaptionFailingCaption(var P: TestPage "AFT Caption Card"; var V: Text)
    begin
        V := P.FailingCaptionCtl.Caption();
    end;

    [ModalPageHandler]
    procedure AlwaysHandler(var P: TestPage "AFT Always Card")
    var
        V: Text;
        Ok: Boolean;
    begin
        HandlerRan := true;
        Ok := TryAlwaysNoCtl(P, V);
        HandlerObs += Res('inHandler.No', Ok, V);
        Ok := TryAlwaysFailingCtl(P, V);
        HandlerObs += Res('inHandler.Failing', Ok, V);
    end;

    local procedure ObsAlways(var P: TestPage "AFT Always Card"; Prefix: Text): Text
    var
        V: Text;
        Obs: Text;
        Ok: Boolean;
    begin
        Ok := TryAlwaysNoCtl(P, V);
        Obs += Res(Prefix + 'No', Ok, V);
        Ok := TryAlwaysOkCtl(P, V);
        Obs += Res(Prefix + 'Ok', Ok, V);
        Ok := TryAlwaysFailingCtl(P, V);
        Obs += Res(Prefix + 'Failing', Ok, V);
        exit(Obs);
    end;

    [Test]
    procedure T01_Always_OpenView_Try()
    var
        P: TestPage "AFT Always Card";
        Obs: Text;
    begin
        Seed();
        Obs += Res('OpenView', TryAlwaysOpenView(P), '');
        Obs += ObsAlways(P, 'r.');
        Obs += Res('Close', TryAlwaysClose(P), '');
        Error(Obs);
    end;

    [Test]
    procedure T02_Always_OpenView_Asserterror()
    var
        P: TestPage "AFT Always Card";
        Obs: Text;
    begin
        Seed();
        asserterror P.OpenView();
        Obs += 'asserterror.OpenView.err=[' + GetLastErrorText() + '] ';
        Obs += ObsAlways(P, 'r.');
        Error(Obs);
    end;

    [Test]
    procedure T03_Always_OpenEdit_And_OpenNew()
    var
        P: TestPage "AFT Always Card";
        P2: TestPage "AFT Always Card";
        Obs: Text;
    begin
        Seed();
        Obs += Res('OpenEdit', TryAlwaysOpenEdit(P), '');
        Obs += Res('OpenNew', TryAlwaysOpenNew(P2), '');
        Obs += ObsAlways(P2, 'new.');
        Error(Obs);
    end;

    [Test]
    procedure T04_Always_OpenView_EmptyTable()
    var
        P: TestPage "AFT Always Card";
        Row: Record "AFT Row";
        Obs: Text;
    begin
        Row.DeleteAll();
        Obs += Res('OpenView(empty)', TryAlwaysOpenView(P), '');
        Obs += ObsAlways(P, 'r.');
        Error(Obs);
    end;

    [Test]
    procedure T05_TypeOnly_NoExpression()
    var
        P: TestPage "AFT TypeOnly Card";
        V: Text;
        Obs: Text;
    begin
        Seed();
        Obs += Res('OpenView', TryTypeOnlyOpenView(P), '');
        Obs += Res('No', TryTypeOnlyNoCtl(P, V), V);
        Obs += Res('TypeOnly', TryTypeOnlyTypeOnlyCtl(P, V), V);
        Obs += Res('Ok', TryTypeOnlyOkCtl(P, V), V);
        Error(Obs);
    end;

    [Test]
    procedure T06_Hidden_RaisingExpression()
    var
        P: TestPage "AFT Hidden Card";
        V: Text;
        Obs: Text;
    begin
        Seed();
        Obs += Res('OpenView', TryHiddenOpenView(P), '');
        Obs += Res('No', TryHiddenNoCtl(P, V), V);
        Obs += Res('Ok', TryHiddenOkCtl(P, V), V);
        Obs += Res('HiddenFailing', TryHiddenHiddenFailingCtl(P, V), V);
        Error(Obs);
    end;

    [Test]
    procedure T07_RowCard_OpenAtOkRow_ThenMove()
    var
        P: TestPage "AFT Row Card";
        V: Text;
        Obs: Text;
    begin
        Seed();
        Obs += Res('OpenView(A)', TryRowCardOpenView(P), '');
        Obs += Res('RowA', TryRowCardRowCtl(P, V), V);
        Obs += Res('GoToKeyB', TryRowCardGoTo(P, 'B'), '');
        Obs += Res('NoAtB', TryRowCardNoCtl(P, V), V);
        Obs += Res('RowAtB', TryRowCardRowCtl(P, V), V);
        Obs += Res('GoToKeyC', TryRowCardGoTo(P, 'C'), '');
        Obs += Res('NoAtC', TryRowCardNoCtl(P, V), V);
        Obs += Res('RowAtC', TryRowCardRowCtl(P, V), V);
        Error(Obs);
    end;

    [Test]
    procedure T08_RowCard_OpenAtFailingRow()
    var
        P: TestPage "AFT Row Card";
        Row: Record "AFT Row";
        V: Text;
        Obs: Text;
    begin
        Seed();
        Row.Get('A');
        Row.Delete();
        Obs += Res('OpenView(first=B)', TryRowCardOpenView(P), '');
        Obs += Res('NoAtB', TryRowCardNoCtl(P, V), V);
        Obs += Res('RowAtB', TryRowCardRowCtl(P, V), V);
        Error(Obs);
    end;

    local procedure ObsRowList(var P: TestPage "AFT Row List"; Prefix: Text): Text
    var
        V: Text;
        Obs: Text;
    begin
        Obs += Res(Prefix + 'No', TryRowListNoCtl(P, V), V);
        Obs += Res(Prefix + 'Row', TryRowListRowCtl(P, V), V);
        exit(Obs);
    end;

    [Test]
    procedure T09_RowList_WalkRows()
    var
        P: TestPage "AFT Row List";
        Moved: Boolean;
        Obs: Text;
    begin
        Seed();
        Obs += Res('OpenView', TryRowListOpenView(P), '');
        Obs += ObsRowList(P, 'A.');
        Obs += Res('Next->B', TryRowListNext(P, Moved), Format(Moved));
        Obs += ObsRowList(P, 'B.');
        Obs += Res('Next->C', TryRowListNext(P, Moved), Format(Moved));
        Obs += ObsRowList(P, 'C.');
        Obs += Res('Last', TryRowListLast(P, Moved), Format(Moved));
        Obs += ObsRowList(P, 'L.');
        Obs += Res('First', TryRowListFirst(P, Moved), Format(Moved));
        Obs += ObsRowList(P, 'F.');
        Error(Obs);
    end;

    [Test]
    procedure T10_RowList_OnlyFailingRow()
    var
        P: TestPage "AFT Row List";
        Row: Record "AFT Row";
        Obs: Text;
    begin
        Seed();
        Row.Get('A');
        Row.Delete();
        Row.Get('C');
        Row.Delete();
        Obs += Res('OpenView(only B)', TryRowListOpenView(P), '');
        Obs += ObsRowList(P, 'B.');
        Error(Obs);
    end;

    [Test]
    procedure T11_AlwaysList_WithRows_And_Empty()
    var
        P: TestPage "AFT Always List";
        P2: TestPage "AFT Always List";
        Row: Record "AFT Row";
        V: Text;
        Obs: Text;
    begin
        Seed();
        Obs += Res('OpenView(rows)', TryAlwaysListOpenView(P), '');
        Obs += Res('No', TryAlwaysListNoCtl(P, V), V);
        Row.DeleteAll();
        Obs += Res('OpenView(empty)', TryAlwaysListOpenView(P2), '');
        Obs += Res('NoEmpty', TryAlwaysListNoCtl(P2, V), V);
        Error(Obs);
    end;

    [Test]
    procedure T12_Type1_RaisingExpression()
    var
        P: TestPage "AFT Type1 Card";
        V: Text;
        Obs: Text;
    begin
        Seed();
        Obs += Res('OpenView', TryType1OpenView(P), '');
        Obs += Res('No', TryType1NoCtl(P, V), V);
        Obs += Res('Type1', TryType1Type1Ctl(P, V), V);
        Error(Obs);
    end;

    [Test]
    [HandlerFunctions('AlwaysHandler')]
    procedure T13_Always_RunModal_Handler()
    var
        Row: Record "AFT Row";
        Obs: Text;
    begin
        Seed();
        HandlerRan := false;
        HandlerObs := '';
        Row.Get('A');
        Page.RunModal(Page::"AFT Always Card", Row);
        Obs := 'RunModal returned; handlerRan=' + Format(HandlerRan) + ' ' + HandlerObs;
        Error(Obs);
    end;

    [Test]
    [HandlerFunctions('AlwaysHandler')]
    procedure T14_Always_RunModal_Asserterror()
    var
        Row: Record "AFT Row";
        Obs: Text;
    begin
        Seed();
        HandlerRan := false;
        HandlerObs := '';
        Row.Get('A');
        asserterror Page.RunModal(Page::"AFT Always Card", Row);
        Obs := 'RunModal asserterror err=[' + GetLastErrorText() + '] handlerRan=' + Format(HandlerRan) + ' ' + HandlerObs;
        Error(Obs);
    end;

    [Test]
    procedure T15_Caption_Try()
    var
        P: TestPage "AFT Caption Card";
        V: Text;
        Obs: Text;
    begin
        Seed();
        Obs += Res('OpenView', TryCaptionOpenView(P), '');
        Obs += Res('No', TryCaptionNoCtl(P, V), V);
        Error(Obs);
    end;

    [Test]
    procedure T16_Caption_Asserterror()
    var
        P: TestPage "AFT Caption Card";
        Obs: Text;
    begin
        Seed();
        asserterror P.OpenView();
        Obs += 'asserterror.OpenView.err=[' + GetLastErrorText() + '] ';
        Error(Obs);
    end;
}
