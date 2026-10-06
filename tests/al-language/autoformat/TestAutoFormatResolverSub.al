// PROBE REVISION 2. Written by agent stma-auto-7, an automated implementation agent acting on the
// account holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4920.

table 69620 "AFS Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 69620 "AFS Card"
{
    PageType = Card;
    SourceTable = "AFS Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(PlainCaptionCtl; Rec.Amount)
            {
                ApplicationArea = All;
                CaptionClass = '3,Plain Caption';
            }
            field(BoomCaptionCtl; Rec.Amount)
            {
                ApplicationArea = All;
                CaptionClass = 'ZZ,AFSBOOM';
            }
        }
    }
}

codeunit 69620 "AFS Resolver Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', false, false)]
    local procedure OnResolve(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if CaptionExpr.Contains('AFSBOOM') then
            Error('AFS resolver subscriber failed');
    end;
}

codeunit 69621 "AFS Probe Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Res(Label: Text; Ok: Boolean; Shown: Text): Text
    begin
        if Ok then
            exit(Label + '=OK[' + Shown + '] ');
        exit(Label + '=ERR[' + GetLastErrorText() + '] ');
    end;

    [TryFunction]
    local procedure TryOpen(var Card: TestPage "AFS Card")
    begin
        Card.OpenView();
    end;

    [TryFunction]
    local procedure TryNo(var Card: TestPage "AFS Card"; var V: Text)
    begin
        V := Card.NoCtl.Value();
    end;

    [TryFunction]
    local procedure TryPlainCaption(var Card: TestPage "AFS Card"; var V: Text)
    begin
        V := Card.PlainCaptionCtl.Caption();
    end;

    [TryFunction]
    local procedure TryBoomCaption(var Card: TestPage "AFS Card"; var V: Text)
    begin
        V := Card.BoomCaptionCtl.Caption();
    end;

    [TryFunction]
    local procedure TryBoomValue(var Card: TestPage "AFS Card"; var V: Text)
    begin
        V := Card.BoomCaptionCtl.Value();
    end;

    [Test]
    procedure S1_FailingResolverSubscriber()
    var
        Card: TestPage "AFS Card";
        Row: Record "AFS Row";
        Obs: Text;
        Ok: Boolean;
        V: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'A';
        Row.Amount := 7;
        Row.Insert();
        Ok := TryOpen(Card);
        Obs += Res('OpenView', Ok, '');
        Ok := TryNo(Card, V);
        Obs += Res('No', Ok, V);
        Ok := TryPlainCaption(Card, V);
        Obs += Res('PlainCaption', Ok, V);
        Ok := TryBoomValue(Card, V);
        Obs += Res('BoomValue', Ok, V);
        Ok := TryBoomCaption(Card, V);
        Obs += Res('BoomCaption', Ok, V);
        Ok := TryBoomCaption(Card, V);
        Obs += Res('BoomCaption2', Ok, V);
        Error(Obs);
    end;

    [Test]
    procedure S2_FailingResolverSubscriber_Asserterror()
    var
        Card: TestPage "AFS Card";
        Row: Record "AFS Row";
        Obs: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'A';
        Row.Amount := 7;
        Row.Insert();
        asserterror Card.OpenView();
        Obs += 'OpenView.err=[' + GetLastErrorText() + ']';
        Error(Obs);
    end;
}
