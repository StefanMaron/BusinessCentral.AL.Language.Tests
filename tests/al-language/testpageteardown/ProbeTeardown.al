// PROBE (record-only): every test ends in Error(<observation>); the failure message IS the answer.
// Written by agent stma-auto-7 for AL Runner issues #5388 and #5390. Not for merge in this form.

table 69640 "PRB Row"
{
    DataClassification = CustomerContent;
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Qty; Integer) { }
        field(3; Amount; Decimal) { }
        field(4; Boom; Boolean) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

page 69640 "PRB Fmt Card"
{
    PageType = Card;
    SourceTable = "PRB Row";
    ApplicationArea = All;
    UsageCategory = None;
    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            field(AmtCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = RowFormat();
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Act)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Error('PRB action ran');
                end;
            }
        }
    }
    local procedure RowFormat(): Text
    begin
        if Rec.Boom then
            Error('PRB row format failed for %1', Rec."No.");
        exit('<Precision,3:3><Standard Format,0>');
    end;
}

page 69641 "PRB Fmt List"
{
    PageType = List;
    SourceTable = "PRB Row";
    ApplicationArea = All;
    UsageCategory = None;
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
                field(AmtCtl; Rec.Amount)
                {
                    ApplicationArea = All;
                    AutoFormatType = 10;
                    AutoFormatExpression = RowFormat();
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Act)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Error('PRB action ran');
                end;
            }
        }
    }
    local procedure RowFormat(): Text
    begin
        if Rec.Boom then
            Error('PRB row format failed for %1', Rec."No.");
        exit('<Precision,3:3><Standard Format,0>');
    end;
}

page 69642 "PRB AGR Card"
{
    PageType = Card;
    SourceTable = "PRB Row";
    ApplicationArea = All;
    UsageCategory = None;
    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Act)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Error('PRB action ran');
                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        if Rec.Boom then
            Error('PRB AGR failed for %1', Rec."No.");
    end;
}

page 69643 "PRB Host Card"
{
    PageType = Card;
    SourceTable = "PRB Row";
    ApplicationArea = All;
    UsageCategory = None;
    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
        }
    }
    actions
    {
        area(Processing)
        {
            action(OpenFailing)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Row: Record "PRB Row";
                begin
                    Row.Get('B');
                    Page.RunModal(Page::"PRB Fmt Card", Row);
                end;
            }
        }
    }
}

codeunit 69640 "PRB Teardown Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Text;
        Cached: Boolean;

    local procedure Seed()
    var
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Row.Init(); Row."No." := 'A'; Row.Qty := 1; Row.Insert();
        Row.Init(); Row."No." := 'B'; Row.Qty := 2; Row.Boom := true; Row.Insert();
        Row.Init(); Row."No." := 'C'; Row.Qty := 3; Row.Insert();
    end;

    local procedure SeedMany(Count: Integer; FailAt: Integer)
    var
        Row: Record "PRB Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Count do begin
            Row.Init();
            Row."No." := 'R' + Format(1000 + i);
            Row.Qty := i;
            Row.Boom := i = FailAt;
            Row.Insert();
        end;
    end;

    local procedure RowCount(): Integer
    var
        Row: Record "PRB Row";
    begin
        exit(Row.Count());
    end;

    local procedure SeedPlain()
    var
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Row.Init(); Row."No." := 'A'; Row.Qty := 1; Row.Insert();
        Row.Init(); Row."No." := 'B'; Row.Qty := 2; Row.Insert();
        Row.Init(); Row."No." := 'C'; Row.Qty := 3; Row.Insert();
    end;

    local procedure SeedBoomLast()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('B');
        Row.Boom := false;
        Row.Modify();
        Row.Get('C');
        Row.Boom := true;
        Row.Modify();
    end;

    local procedure SeedBoomFirst()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Row.Delete();
    end;

    local procedure FixData()
    var
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Row.Init(); Row."No." := 'C'; Row.Qty := 3; Row.Insert();
    end;

    [Test]
    procedure Probe_CE_Value_Fresh()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Error('OBS ' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_CE_Value_Cached()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        Error('OBS ' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_CE_AsInteger_Fresh()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.AsInteger());
    end;

    [Test]
    procedure Probe_CE_AsInteger_Cached()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        I := P.QtyCtl.AsInteger();
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.AsInteger());
    end;

    [Test]
    procedure Probe_CE_Caption_Fresh()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Error('OBS ' + P.QtyCtl.Caption());
    end;

    [Test]
    procedure Probe_CE_Caption_Cached()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Caption();
        asserterror P.GoToKey('B');
        Error('OBS ' + P.QtyCtl.Caption());
    end;

    [Test]
    procedure Probe_CE_Editable_Fresh()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.Editable());
    end;

    [Test]
    procedure Probe_CE_Editable_Cached()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.QtyCtl.Editable();
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.Editable());
    end;

    [Test]
    procedure Probe_CE_Visible_Fresh()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.Visible());
    end;

    [Test]
    procedure Probe_CE_Visible_Cached()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.QtyCtl.Visible();
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.Visible());
    end;

    [Test]
    procedure Probe_CE_Enabled_Fresh()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.Enabled());
    end;

    [Test]
    procedure Probe_CE_Enabled_Cached()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.QtyCtl.Enabled();
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.Enabled());
    end;

    [Test]
    procedure Probe_CE_AssertEquals_Fresh()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        P.QtyCtl.AssertEquals(2); Error('OBS assertequals(2) passed');
    end;

    [Test]
    procedure Probe_CE_AssertEquals_Cached()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        P.QtyCtl.AssertEquals(2); Error('OBS assertequals(2) passed');
    end;

    [Test]
    procedure Probe_CE_SetValue_Fresh()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        P.QtyCtl.SetValue(9); Error('OBS setvalue ok');
    end;

    [Test]
    procedure Probe_CE_SetValue_Cached()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        P.QtyCtl.SetValue(9); Error('OBS setvalue ok');
    end;

    [Test]
    procedure Probe_CE_Invoke_Fresh()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        P.Act.Invoke(); Error('OBS invoke returned');
    end;

    [Test]
    procedure Probe_CE_Invoke_Cached()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.Act.Visible();
        asserterror P.GoToKey('B');
        P.Act.Invoke(); Error('OBS invoke returned');
    end;

    [Test]
    procedure Probe_CE_ActEnabled_Fresh()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Error('OBS %1', P.Act.Enabled());
    end;

    [Test]
    procedure Probe_CE_ActEnabled_Cached()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.Act.Enabled();
        asserterror P.GoToKey('B');
        Error('OBS %1', P.Act.Enabled());
    end;

    [Test]
    procedure Probe_CE_Page_Close()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.Close(); Error('OBS close returned');
    end;

    [Test]
    procedure Probe_CE_Page_First()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.First(); Error('OBS first returned');
    end;

    [Test]
    procedure Probe_CE_Page_Next()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Error('OBS next=%1', P.Next());
    end;

    [Test]
    procedure Probe_CE_Page_GoToKeyA()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.GoToKey('A'); Error('OBS gotokey(A) returned');
    end;

    [Test]
    procedure Probe_CE_Page_PageCaption()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Error('OBS ' + P.Caption());
    end;

    [Test]
    procedure Probe_CE_Page_PageEditable()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Error('OBS %1', P.Editable());
    end;

    [Test]
    procedure Probe_CE_Page_OpenView()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView(); Error('OBS openview ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_CE_Page_OpenEdit()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenEdit(); Error('OBS openedit ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_CE_Page_OpenNew()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenNew(); Error('OBS opennew ok qty=' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_CA_Value_Fresh()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Error('OBS ' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_CA_Value_Cached()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        Error('OBS ' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_CA_AsInteger_Fresh()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.AsInteger());
    end;

    [Test]
    procedure Probe_CA_AsInteger_Cached()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        I := P.QtyCtl.AsInteger();
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.AsInteger());
    end;

    [Test]
    procedure Probe_CA_Caption_Fresh()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Error('OBS ' + P.QtyCtl.Caption());
    end;

    [Test]
    procedure Probe_CA_Caption_Cached()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Caption();
        asserterror P.GoToKey('B');
        Error('OBS ' + P.QtyCtl.Caption());
    end;

    [Test]
    procedure Probe_CA_Editable_Fresh()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.Editable());
    end;

    [Test]
    procedure Probe_CA_Editable_Cached()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.QtyCtl.Editable();
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.Editable());
    end;

    [Test]
    procedure Probe_CA_Visible_Fresh()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.Visible());
    end;

    [Test]
    procedure Probe_CA_Visible_Cached()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.QtyCtl.Visible();
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.Visible());
    end;

    [Test]
    procedure Probe_CA_Enabled_Fresh()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.Enabled());
    end;

    [Test]
    procedure Probe_CA_Enabled_Cached()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.QtyCtl.Enabled();
        asserterror P.GoToKey('B');
        Error('OBS %1', P.QtyCtl.Enabled());
    end;

    [Test]
    procedure Probe_CA_AssertEquals_Fresh()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        P.QtyCtl.AssertEquals(2); Error('OBS assertequals(2) passed');
    end;

    [Test]
    procedure Probe_CA_AssertEquals_Cached()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        P.QtyCtl.AssertEquals(2); Error('OBS assertequals(2) passed');
    end;

    [Test]
    procedure Probe_CA_SetValue_Fresh()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        P.QtyCtl.SetValue(9); Error('OBS setvalue ok');
    end;

    [Test]
    procedure Probe_CA_SetValue_Cached()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        P.QtyCtl.SetValue(9); Error('OBS setvalue ok');
    end;

    [Test]
    procedure Probe_CA_Invoke_Fresh()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        P.Act.Invoke(); Error('OBS invoke returned');
    end;

    [Test]
    procedure Probe_CA_Invoke_Cached()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.Act.Visible();
        asserterror P.GoToKey('B');
        P.Act.Invoke(); Error('OBS invoke returned');
    end;

    [Test]
    procedure Probe_CA_ActEnabled_Fresh()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        
        asserterror P.GoToKey('B');
        Error('OBS %1', P.Act.Enabled());
    end;

    [Test]
    procedure Probe_CA_ActEnabled_Cached()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        B := P.Act.Enabled();
        asserterror P.GoToKey('B');
        Error('OBS %1', P.Act.Enabled());
    end;

    [Test]
    procedure Probe_CA_Page_Close()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.Close(); Error('OBS close returned');
    end;

    [Test]
    procedure Probe_CA_Page_First()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.First(); Error('OBS first returned');
    end;

    [Test]
    procedure Probe_CA_Page_Next()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Error('OBS next=%1', P.Next());
    end;

    [Test]
    procedure Probe_CA_Page_GoToKeyA()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.GoToKey('A'); Error('OBS gotokey(A) returned');
    end;

    [Test]
    procedure Probe_CA_Page_PageCaption()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Error('OBS ' + P.Caption());
    end;

    [Test]
    procedure Probe_CA_Page_PageEditable()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Error('OBS %1', P.Editable());
    end;

    [Test]
    procedure Probe_CA_Page_OpenView()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView(); Error('OBS openview ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_CA_Page_OpenEdit()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenEdit(); Error('OBS openedit ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_CA_Page_OpenNew()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenNew(); Error('OBS opennew ok qty=' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_LE_Value_Fresh()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        
        asserterror P.Last();
        Error('OBS ' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_LE_Value_Cached()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.Last();
        Error('OBS ' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_LE_AsInteger_Fresh()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        
        asserterror P.Last();
        Error('OBS %1', P.QtyCtl.AsInteger());
    end;

    [Test]
    procedure Probe_LE_AsInteger_Cached()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        I := P.QtyCtl.AsInteger();
        asserterror P.Last();
        Error('OBS %1', P.QtyCtl.AsInteger());
    end;

    [Test]
    procedure Probe_LE_Caption_Fresh()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        
        asserterror P.Last();
        Error('OBS ' + P.QtyCtl.Caption());
    end;

    [Test]
    procedure Probe_LE_Caption_Cached()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        T := P.QtyCtl.Caption();
        asserterror P.Last();
        Error('OBS ' + P.QtyCtl.Caption());
    end;

    [Test]
    procedure Probe_LE_Editable_Fresh()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        
        asserterror P.Last();
        Error('OBS %1', P.QtyCtl.Editable());
    end;

    [Test]
    procedure Probe_LE_Editable_Cached()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        B := P.QtyCtl.Editable();
        asserterror P.Last();
        Error('OBS %1', P.QtyCtl.Editable());
    end;

    [Test]
    procedure Probe_LE_Visible_Fresh()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        
        asserterror P.Last();
        Error('OBS %1', P.QtyCtl.Visible());
    end;

    [Test]
    procedure Probe_LE_Visible_Cached()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        B := P.QtyCtl.Visible();
        asserterror P.Last();
        Error('OBS %1', P.QtyCtl.Visible());
    end;

    [Test]
    procedure Probe_LE_Enabled_Fresh()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        
        asserterror P.Last();
        Error('OBS %1', P.QtyCtl.Enabled());
    end;

    [Test]
    procedure Probe_LE_Enabled_Cached()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        B := P.QtyCtl.Enabled();
        asserterror P.Last();
        Error('OBS %1', P.QtyCtl.Enabled());
    end;

    [Test]
    procedure Probe_LE_AssertEquals_Fresh()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        
        asserterror P.Last();
        P.QtyCtl.AssertEquals(2); Error('OBS assertequals(2) passed');
    end;

    [Test]
    procedure Probe_LE_AssertEquals_Cached()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.Last();
        P.QtyCtl.AssertEquals(2); Error('OBS assertequals(2) passed');
    end;

    [Test]
    procedure Probe_LE_SetValue_Fresh()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        
        asserterror P.Last();
        P.QtyCtl.SetValue(9); Error('OBS setvalue ok');
    end;

    [Test]
    procedure Probe_LE_SetValue_Cached()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.Last();
        P.QtyCtl.SetValue(9); Error('OBS setvalue ok');
    end;

    [Test]
    procedure Probe_LE_Invoke_Fresh()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        
        asserterror P.Last();
        P.Act.Invoke(); Error('OBS invoke returned');
    end;

    [Test]
    procedure Probe_LE_Invoke_Cached()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        B := P.Act.Visible();
        asserterror P.Last();
        P.Act.Invoke(); Error('OBS invoke returned');
    end;

    [Test]
    procedure Probe_LE_ActEnabled_Fresh()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        
        asserterror P.Last();
        Error('OBS %1', P.Act.Enabled());
    end;

    [Test]
    procedure Probe_LE_ActEnabled_Cached()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        B := P.Act.Enabled();
        asserterror P.Last();
        Error('OBS %1', P.Act.Enabled());
    end;

    [Test]
    procedure Probe_LE_Page_Close()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        asserterror P.Last();
        P.Close(); Error('OBS close returned');
    end;

    [Test]
    procedure Probe_LE_Page_First()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        asserterror P.Last();
        P.First(); Error('OBS first returned');
    end;

    [Test]
    procedure Probe_LE_Page_Next()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        asserterror P.Last();
        Error('OBS next=%1', P.Next());
    end;

    [Test]
    procedure Probe_LE_Page_GoToKeyA()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        asserterror P.Last();
        P.GoToKey('A'); Error('OBS gotokey(A) returned');
    end;

    [Test]
    procedure Probe_LE_Page_PageCaption()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        asserterror P.Last();
        Error('OBS ' + P.Caption());
    end;

    [Test]
    procedure Probe_LE_Page_PageEditable()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        asserterror P.Last();
        Error('OBS %1', P.Editable());
    end;

    [Test]
    procedure Probe_LE_Page_OpenView()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        asserterror P.Last();
        P.OpenView(); Error('OBS openview ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_LE_Page_OpenEdit()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        asserterror P.Last();
        P.OpenEdit(); Error('OBS openedit ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_LE_Page_OpenNew()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 120);
        P.OpenView();
        asserterror P.Last();
        P.OpenNew(); Error('OBS opennew ok qty=' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_CEO_Page_Close()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.Close(); Error('OBS close returned');
    end;

    [Test]
    procedure Probe_CEO_Page_First()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.First(); Error('OBS first returned');
    end;

    [Test]
    procedure Probe_CEO_Page_Next()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        Error('OBS next=%1', P.Next());
    end;

    [Test]
    procedure Probe_CEO_Page_GoToKeyA()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.GoToKey('A'); Error('OBS gotokey(A) returned');
    end;

    [Test]
    procedure Probe_CEO_Page_PageCaption()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        Error('OBS ' + P.Caption());
    end;

    [Test]
    procedure Probe_CEO_Page_PageEditable()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        Error('OBS %1', P.Editable());
    end;

    [Test]
    procedure Probe_CEO_Page_OpenView()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.OpenView(); Error('OBS openview ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_CEO_Page_OpenEdit()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.OpenEdit(); Error('OBS openedit ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_CEO_Page_OpenNew()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.OpenNew(); Error('OBS opennew ok qty=' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_CEO_Page_Value()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        Error('OBS ' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_CEO_Page_Act()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.Act.Invoke(); Error('OBS invoke returned');
    end;

    [Test]
    procedure Probe_CEO_Page_SetValue()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.QtyCtl.SetValue(9); Error('OBS setvalue ok');
    end;

    [Test]
    procedure Probe_CAO_Page_Close()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.Close(); Error('OBS close returned');
    end;

    [Test]
    procedure Probe_CAO_Page_First()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.First(); Error('OBS first returned');
    end;

    [Test]
    procedure Probe_CAO_Page_Next()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        Error('OBS next=%1', P.Next());
    end;

    [Test]
    procedure Probe_CAO_Page_GoToKeyA()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.GoToKey('A'); Error('OBS gotokey(A) returned');
    end;

    [Test]
    procedure Probe_CAO_Page_PageCaption()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        Error('OBS ' + P.Caption());
    end;

    [Test]
    procedure Probe_CAO_Page_PageEditable()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        Error('OBS %1', P.Editable());
    end;

    [Test]
    procedure Probe_CAO_Page_OpenView()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.OpenView(); Error('OBS openview ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_CAO_Page_OpenEdit()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.OpenEdit(); Error('OBS openedit ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_CAO_Page_OpenNew()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.OpenNew(); Error('OBS opennew ok qty=' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_CAO_Page_Value()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        Error('OBS ' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_CAO_Page_Act()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.Act.Invoke(); Error('OBS invoke returned');
    end;

    [Test]
    procedure Probe_CAO_Page_SetValue()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.QtyCtl.SetValue(9); Error('OBS setvalue ok');
    end;

    [Test]
    procedure Probe_LEO_Page_Close()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 20);
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.Close(); Error('OBS close returned');
    end;

    [Test]
    procedure Probe_LEO_Page_First()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 20);
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.First(); Error('OBS first returned');
    end;

    [Test]
    procedure Probe_LEO_Page_Next()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 20);
        asserterror P.OpenView();
        T := GetLastErrorText();
        Error('OBS next=%1', P.Next());
    end;

    [Test]
    procedure Probe_LEO_Page_GoToKeyA()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 20);
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.GoToKey('A'); Error('OBS gotokey(A) returned');
    end;

    [Test]
    procedure Probe_LEO_Page_PageCaption()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 20);
        asserterror P.OpenView();
        T := GetLastErrorText();
        Error('OBS ' + P.Caption());
    end;

    [Test]
    procedure Probe_LEO_Page_PageEditable()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 20);
        asserterror P.OpenView();
        T := GetLastErrorText();
        Error('OBS %1', P.Editable());
    end;

    [Test]
    procedure Probe_LEO_Page_OpenView()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 20);
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.OpenView(); Error('OBS openview ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_LEO_Page_OpenEdit()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 20);
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.OpenEdit(); Error('OBS openedit ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_LEO_Page_OpenNew()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 20);
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.OpenNew(); Error('OBS opennew ok qty=' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_LEO_Page_Value()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 20);
        asserterror P.OpenView();
        T := GetLastErrorText();
        Error('OBS ' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_LEO_Page_Act()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 20);
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.Act.Invoke(); Error('OBS invoke returned');
    end;

    [Test]
    procedure Probe_LEO_Page_SetValue()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
    begin
        SeedMany(120, 20);
        asserterror P.OpenView();
        T := GetLastErrorText();
        P.QtyCtl.SetValue(9); Error('OBS setvalue ok');
    end;

    [Test]
    procedure Probe_Reopen_Control_AfterClose()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        Seed();
        P.OpenView();
        P.Close();
        P.OpenView();
        Error('OBS reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CE_AfterTeardown()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        Error('OBS reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CE_AfterTeardown_Cached()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        P.OpenView();
        Error('OBS reopen ok Qty=' + P.QtyCtl.Value() + ' NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CE_AfterTeardown_RefusedCloseFirst()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        asserterror P.Close();
        T := GetLastErrorText();
        P.OpenView();
        Error('OBS close said [' + T + '] then reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CE_TearTwice()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        Error('OBS second reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CE_ThenClose()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        P.Close();
        Error('OBS reopen then close ok');
    end;

    [Test]
    procedure Probe_Reopen_CA_AfterTeardown()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        Error('OBS reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CA_AfterTeardown_Cached()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        Seed();
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        P.OpenView();
        Error('OBS reopen ok Qty=' + P.QtyCtl.Value() + ' NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CA_AfterTeardown_RefusedCloseFirst()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        asserterror P.Close();
        T := GetLastErrorText();
        P.OpenView();
        Error('OBS close said [' + T + '] then reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CA_TearTwice()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        Error('OBS second reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CA_ThenClose()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        P.Close();
        Error('OBS reopen then close ok');
    end;

    [Test]
    procedure Probe_Reopen_LE_AfterTeardown()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedMany(120, 120);
        P.OpenView();
        asserterror P.Last();
        P.OpenView();
        Error('OBS reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_LE_AfterTeardown_Cached()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedMany(120, 120);
        P.OpenView();
        T := P.QtyCtl.Value();
        asserterror P.Last();
        P.OpenView();
        Error('OBS reopen ok Qty=' + P.QtyCtl.Value() + ' NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_LE_AfterTeardown_RefusedCloseFirst()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedMany(120, 120);
        P.OpenView();
        asserterror P.Last();
        asserterror P.Close();
        T := GetLastErrorText();
        P.OpenView();
        Error('OBS close said [' + T + '] then reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_LE_TearTwice()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedMany(120, 120);
        P.OpenView();
        asserterror P.Last();
        P.OpenView();
        asserterror P.Last();
        P.OpenView();
        Error('OBS second reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_LE_ThenClose()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedMany(120, 120);
        P.OpenView();
        asserterror P.Last();
        P.OpenView();
        P.Close();
        Error('OBS reopen then close ok');
    end;

    [Test]
    procedure Probe_Reopen_CE_AfterFailedOpen()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        FixData();
        P.OpenView();
        Error('OBS reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CE_AfterFailedOpen_CloseThenOpen()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        asserterror P.Close();
        FixData();
        P.OpenView();
        Error('OBS reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CE_AfterFailedOpen_OpenEdit()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        FixData();
        P.OpenEdit();
        Error('OBS reopen(edit) ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CE_AfterFailedOpen_OpenNew()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        FixData();
        P.OpenNew();
        Error('OBS reopen(new) ok qty=' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CE_AfterFailedOpen_StillFails()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        asserterror P.OpenView();
        T := GetLastErrorText();
        Error('OBS second open of still-failing data said [' + T + ']');
    end;

    [Test]
    procedure Probe_Reopen_CA_AfterFailedOpen()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        FixData();
        P.OpenView();
        Error('OBS reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CA_AfterFailedOpen_CloseThenOpen()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        asserterror P.Close();
        FixData();
        P.OpenView();
        Error('OBS reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CA_AfterFailedOpen_OpenEdit()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        FixData();
        P.OpenEdit();
        Error('OBS reopen(edit) ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CA_AfterFailedOpen_OpenNew()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        FixData();
        P.OpenNew();
        Error('OBS reopen(new) ok qty=' + P.QtyCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_CA_AfterFailedOpen_StillFails()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedBoomFirst();
        asserterror P.OpenView();
        asserterror P.OpenView();
        T := GetLastErrorText();
        Error('OBS second open of still-failing data said [' + T + ']');
    end;

    [Test]
    procedure Probe_Reopen_LE_AfterFailedOpen()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedMany(120, 20);
        asserterror P.OpenView();
        FixData();
        P.OpenView();
        Error('OBS reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_Position_CE_MoveCloseReopen()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedPlain();
        P.OpenView();
        P.GoToKey('C');
        P.Close();
        P.OpenView();
        Error('OBS reopened at NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_Position_CE_MoveCloseReopenEdit()
    var
        P: TestPage "PRB Fmt Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedPlain();
        P.OpenEdit();
        P.GoToKey('C');
        P.Close();
        P.OpenEdit();
        Error('OBS reopened(edit) at NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_Position_LE_MoveCloseReopen()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedPlain();
        P.OpenView();
        P.Last();
        P.Close();
        P.OpenView();
        Error('OBS reopened at NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_Position_LE_MoveCloseReopenEdit()
    var
        P: TestPage "PRB Fmt List";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedPlain();
        P.OpenEdit();
        P.Last();
        P.Close();
        P.OpenEdit();
        Error('OBS reopened(edit) at NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_Position_CA_MoveCloseReopen()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedPlain();
        P.OpenView();
        P.GoToKey('C');
        P.Close();
        P.OpenView();
        Error('OBS reopened at NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Reopen_Position_CA_MoveCloseReopenEdit()
    var
        P: TestPage "PRB AGR Card";
        T: Text;
        I: Integer;
        B: Boolean;
        Row: Record "PRB Row";
    begin
        SeedPlain();
        P.OpenEdit();
        P.GoToKey('C');
        P.Close();
        P.OpenEdit();
        Error('OBS reopened(edit) at NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe2_CE_TearThenReopen_Untouched()
    var
        P: TestPage "PRB Fmt Card";
        P2: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + '] Qty=[' + P.QtyCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CE_TearThenReopen_AfterModify()
    var
        P: TestPage "PRB Fmt Card";
        P2: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        Row.FindFirst();
        Row.Amount := 5;
        Row.Modify();
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CE_TearThenReopen_AfterCommit()
    var
        P: TestPage "PRB Fmt Card";
        P2: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        Commit();
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CE_TearThenReopen_AfterDeleteBoom()
    var
        P: TestPage "PRB Fmt Card";
        P2: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        Row.SetRange(Boom, true);
        Row.DeleteAll();
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CE_TearThenSecondVariable()
    var
        P: TestPage "PRB Fmt Card";
        P2: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        P2.OpenView();
        Error('OBS second variable NoCtl=[' + P2.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CE_TearThenReopen_ThenFirst()
    var
        P: TestPage "PRB Fmt Card";
        P2: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        P.First();
        Error('OBS after First NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CE_TearThenReopen_ThenGoToKeyA()
    var
        P: TestPage "PRB Fmt Card";
        P2: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        P.GoToKey('A');
        Error('OBS after GoToKey(A) NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CE_TearThenReopen_CloseReopen()
    var
        P: TestPage "PRB Fmt Card";
        P2: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        P.Close();
        P.OpenView();
        Error('OBS third open NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CA_TearThenReopen_Untouched()
    var
        P: TestPage "PRB AGR Card";
        P2: TestPage "PRB AGR Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + '] Qty=[' + P.QtyCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CA_TearThenReopen_AfterModify()
    var
        P: TestPage "PRB AGR Card";
        P2: TestPage "PRB AGR Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        Row.FindFirst();
        Row.Amount := 5;
        Row.Modify();
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CA_TearThenReopen_AfterCommit()
    var
        P: TestPage "PRB AGR Card";
        P2: TestPage "PRB AGR Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        Commit();
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CA_TearThenReopen_AfterDeleteBoom()
    var
        P: TestPage "PRB AGR Card";
        P2: TestPage "PRB AGR Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        Row.SetRange(Boom, true);
        Row.DeleteAll();
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CA_TearThenSecondVariable()
    var
        P: TestPage "PRB AGR Card";
        P2: TestPage "PRB AGR Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        P2.OpenView();
        Error('OBS second variable NoCtl=[' + P2.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CA_TearThenReopen_ThenFirst()
    var
        P: TestPage "PRB AGR Card";
        P2: TestPage "PRB AGR Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        P.First();
        Error('OBS after First NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CA_TearThenReopen_ThenGoToKeyA()
    var
        P: TestPage "PRB AGR Card";
        P2: TestPage "PRB AGR Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        P.GoToKey('A');
        Error('OBS after GoToKey(A) NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CA_TearThenReopen_CloseReopen()
    var
        P: TestPage "PRB AGR Card";
        P2: TestPage "PRB AGR Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        P.OpenView();
        P.Close();
        P.OpenView();
        Error('OBS third open NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_LE_TearThenReopen_Untouched()
    var
        P: TestPage "PRB Fmt List";
        P2: TestPage "PRB Fmt List";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        SeedMany(120, 120); Commit();
        P.OpenView();
        asserterror P.Last();
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + '] Qty=[' + P.QtyCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_LE_TearThenReopen_AfterModify()
    var
        P: TestPage "PRB Fmt List";
        P2: TestPage "PRB Fmt List";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        SeedMany(120, 120); Commit();
        P.OpenView();
        asserterror P.Last();
        Row.FindFirst();
        Row.Amount := 5;
        Row.Modify();
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_LE_TearThenReopen_AfterCommit()
    var
        P: TestPage "PRB Fmt List";
        P2: TestPage "PRB Fmt List";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        SeedMany(120, 120); Commit();
        P.OpenView();
        asserterror P.Last();
        Commit();
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_LE_TearThenReopen_AfterDeleteBoom()
    var
        P: TestPage "PRB Fmt List";
        P2: TestPage "PRB Fmt List";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        SeedMany(120, 120); Commit();
        P.OpenView();
        asserterror P.Last();
        Row.SetRange(Boom, true);
        Row.DeleteAll();
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_LE_TearThenSecondVariable()
    var
        P: TestPage "PRB Fmt List";
        P2: TestPage "PRB Fmt List";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        SeedMany(120, 120); Commit();
        P.OpenView();
        asserterror P.Last();
        P2.OpenView();
        Error('OBS second variable NoCtl=[' + P2.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_LE_TearThenReopen_ThenFirst()
    var
        P: TestPage "PRB Fmt List";
        P2: TestPage "PRB Fmt List";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        SeedMany(120, 120); Commit();
        P.OpenView();
        asserterror P.Last();
        P.OpenView();
        P.First();
        Error('OBS after First NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_LE_TearThenReopen_ThenGoToKeyA()
    var
        P: TestPage "PRB Fmt List";
        P2: TestPage "PRB Fmt List";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        SeedMany(120, 120); Commit();
        P.OpenView();
        asserterror P.Last();
        P.OpenView();
        P.GoToKey('A');
        Error('OBS after GoToKey(A) NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_LE_TearThenReopen_CloseReopen()
    var
        P: TestPage "PRB Fmt List";
        P2: TestPage "PRB Fmt List";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        SeedMany(120, 120); Commit();
        P.OpenView();
        asserterror P.Last();
        P.OpenView();
        P.Close();
        P.OpenView();
        Error('OBS third open NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CE_BoomLast_TearThenReopen()
    var
        P: TestPage "PRB Fmt Card";
        P2: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        SeedBoomLast(); Commit();
        P.OpenView();
        asserterror P.GoToKey('C');
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CA_BoomLast_TearThenReopen()
    var
        P: TestPage "PRB AGR Card";
        P2: TestPage "PRB AGR Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        SeedBoomLast(); Commit();
        P.OpenView();
        asserterror P.GoToKey('C');
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CE_FailedOpen_ThenSecondVariable()
    var
        P: TestPage "PRB Fmt Card";
        P2: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        SeedBoomFirst(); Commit();
        asserterror P.OpenView();
        P2.OpenView();
        Error('OBS second variable NoCtl=[' + P2.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CE_FailedOpen_ReopenUntouchedThenFix()
    var
        P: TestPage "PRB Fmt Card";
        P2: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        SeedBoomFirst(); Commit();
        asserterror P.OpenView();
        P.OpenView();
        T := P.NoCtl.Value();
        P.Close();
        FixData();
        P.OpenView();
        Error('OBS first reopen NoCtl=[' + T + '] after fix and close and open: NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CE_FailedOpen_FixThenReopen()
    var
        P: TestPage "PRB Fmt Card";
        P2: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        SeedBoomFirst(); Commit();
        asserterror P.OpenView();
        FixData();
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CE_FailedOpen_DeleteBoomOnlyThenReopen()
    var
        P: TestPage "PRB Fmt Card";
        P2: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        SeedBoomFirst(); Commit();
        asserterror P.OpenView();
        Row.Get('B');
        Row.Delete();
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe2_CE_PlainClose_ThenReopen_AfterDelete()
    var
        P: TestPage "PRB Fmt Card";
        P2: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
        T: Text;
        B: Boolean;

    begin
        SeedPlain(); Commit();
        P.OpenView();
        P.GoToKey('C');
        P.Close();
        Row.Get('A');
        Row.Delete();
        P.OpenView();
        Error('OBS NoCtl=[' + P.NoCtl.Value() + ']');
    end;

    [Test]
    procedure Probe3_Plain_AsserterrorThenCount()
    var
        P: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        Seed();
        asserterror Error('plain');
        Error('OBS rows=%1', Row.Count());
    end;

    [Test]
    procedure Probe3_CE_TearThenCount()
    var
        P: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Error('OBS rows=%1', Row.Count());
    end;

    [Test]
    procedure Probe3_CE_CommittedSeed_TearThenCount()
    var
        P: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        Error('OBS rows=%1', Row.Count());
    end;

    [Test]
    procedure Probe3_CE_ModifyAfterOpen_TearThenRead()
    var
        P: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        Seed(); Commit();
        P.OpenView();
        Row.FindFirst();
        Row.Qty := 77;
        Row.Modify();
        asserterror P.GoToKey('B');
        Row.FindFirst();
        Error('OBS first row qty=%1', Row.Qty);
    end;

    [Test]
    procedure Probe3_CA_TearThenCount()
    var
        P: TestPage "PRB AGR Card";
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        Seed();
        P.OpenView();
        asserterror P.GoToKey('B');
        Error('OBS rows=%1', Row.Count());
    end;

    [Test]
    procedure Probe3_CA_CommittedSeed_TearThenCount()
    var
        P: TestPage "PRB AGR Card";
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        Seed(); Commit();
        P.OpenView();
        asserterror P.GoToKey('B');
        Error('OBS rows=%1', Row.Count());
    end;

    [Test]
    procedure Probe3_CA_ModifyAfterOpen_TearThenRead()
    var
        P: TestPage "PRB AGR Card";
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        Seed(); Commit();
        P.OpenView();
        Row.FindFirst();
        Row.Qty := 77;
        Row.Modify();
        asserterror P.GoToKey('B');
        Row.FindFirst();
        Error('OBS first row qty=%1', Row.Qty);
    end;

    [Test]
    procedure Probe3_LE_TearThenCount()
    var
        P: TestPage "PRB Fmt List";
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        SeedMany(120, 120);
        P.OpenView();
        asserterror P.Last();
        Error('OBS rows=%1', Row.Count());
    end;

    [Test]
    procedure Probe3_LE_CommittedSeed_TearThenCount()
    var
        P: TestPage "PRB Fmt List";
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        SeedMany(120, 120); Commit();
        P.OpenView();
        asserterror P.Last();
        Error('OBS rows=%1', Row.Count());
    end;

    [Test]
    procedure Probe3_LE_ModifyAfterOpen_TearThenRead()
    var
        P: TestPage "PRB Fmt List";
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        SeedMany(120, 120); Commit();
        P.OpenView();
        Row.FindFirst();
        Row.Qty := 77;
        Row.Modify();
        asserterror P.Last();
        Row.FindFirst();
        Error('OBS first row qty=%1', Row.Qty);
    end;

    [Test]
    procedure Probe3_CE_FailedOpen_ThenCount()
    var
        P: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        SeedBoomFirst();
        asserterror P.OpenView();
        Error('OBS rows=%1', Row.Count());
    end;

    [Test]
    procedure Probe3_CA_FailedOpen_ThenCount()
    var
        P: TestPage "PRB AGR Card";
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        SeedBoomFirst();
        asserterror P.OpenView();
        Error('OBS rows=%1', Row.Count());
    end;

    [Test]
    procedure Probe3_CE_FailedOpen_CommittedSeed_ThenCount()
    var
        P: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        SeedBoomFirst(); Commit();
        asserterror P.OpenView();
        Error('OBS rows=%1', Row.Count());
    end;

    [Test]
    procedure Probe3_CE_ActionError_ThenCount()
    var
        P: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        Seed();
        P.OpenView();
        asserterror P.Act.Invoke();
        Error('OBS rows=%1', Row.Count());
    end;

    [Test]
    procedure Probe3_CE_ValidateError_ThenCount()
    var
        P: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue('abc');
        Error('OBS rows=%1', Row.Count());
    end;

    [ModalPageHandler]
    procedure HCount(var P: TestPage "PRB Fmt Card")
    begin
        asserterror P.GoToKey('B');
        Error('OBS rows=%1', RowCount());
    end;

    [Test]
    [HandlerFunctions('HCount')]
    procedure Probe3_Modal_TearInHandler_ThenCount()
    var
        Row: Record "PRB Row";
    begin
        Row.DeleteAll();
        Commit();
        Seed();
        Row.Get('A');
        Page.RunModal(Page::"PRB Fmt Card", Row);
    end;

    [ModalPageHandler]
    procedure HFmt(var P: TestPage "PRB Fmt Card")
    var
        T: Text;
    begin
        if Cached then T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        case Mode of
            'Value': Error('OBS ' + P.QtyCtl.Value());
            'AsInteger': Error('OBS %1', P.QtyCtl.AsInteger());
            'Editable': Error('OBS %1', P.QtyCtl.Editable());
            'AssertEquals': begin P.QtyCtl.AssertEquals(2); Error('OBS assertequals(2) passed'); end;
            'Close': begin P.Close(); Error('OBS close returned'); end;
            'OKInvoke': begin P.OK().Invoke(); Error('OBS ok invoked'); end;
            'PageCaption': Error('OBS ' + P.Caption());
            'Next': Error('OBS next=%1', P.Next());
            'Act': begin P.Act.Invoke(); Error('OBS act invoked'); end;
            'Count': Error('OBS rows=%1 NoCtlRead=[%2]', RowCount(), 'n/a');
        end;
    end;

    [Test]
    [HandlerFunctions('HFmt')]
    procedure Probe_Modal_HFmt_Value_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Value';
        Cached := false;
        Page.RunModal(Page::"PRB Fmt Card", Row);
    end;

    [Test]
    [HandlerFunctions('HFmt')]
    procedure Probe_Modal_HFmt_Value_Cached()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Value';
        Cached := true;
        Page.RunModal(Page::"PRB Fmt Card", Row);
    end;

    [Test]
    [HandlerFunctions('HFmt')]
    procedure Probe_Modal_HFmt_AsInteger_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'AsInteger';
        Cached := false;
        Page.RunModal(Page::"PRB Fmt Card", Row);
    end;

    [Test]
    [HandlerFunctions('HFmt')]
    procedure Probe_Modal_HFmt_AsInteger_Cached()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'AsInteger';
        Cached := true;
        Page.RunModal(Page::"PRB Fmt Card", Row);
    end;

    [Test]
    [HandlerFunctions('HFmt')]
    procedure Probe_Modal_HFmt_Editable_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Editable';
        Cached := false;
        Page.RunModal(Page::"PRB Fmt Card", Row);
    end;

    [Test]
    [HandlerFunctions('HFmt')]
    procedure Probe_Modal_HFmt_Editable_Cached()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Editable';
        Cached := true;
        Page.RunModal(Page::"PRB Fmt Card", Row);
    end;

    [Test]
    [HandlerFunctions('HFmt')]
    procedure Probe_Modal_HFmt_AssertEquals_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'AssertEquals';
        Cached := false;
        Page.RunModal(Page::"PRB Fmt Card", Row);
    end;

    [Test]
    [HandlerFunctions('HFmt')]
    procedure Probe_Modal_HFmt_AssertEquals_Cached()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'AssertEquals';
        Cached := true;
        Page.RunModal(Page::"PRB Fmt Card", Row);
    end;

    [Test]
    [HandlerFunctions('HFmt')]
    procedure Probe_Modal_HFmt_Close_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Close';
        Cached := false;
        Page.RunModal(Page::"PRB Fmt Card", Row);
    end;

    [Test]
    [HandlerFunctions('HFmt')]
    procedure Probe_Modal_HFmt_OKInvoke_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'OKInvoke';
        Cached := false;
        Page.RunModal(Page::"PRB Fmt Card", Row);
    end;

    [Test]
    [HandlerFunctions('HFmt')]
    procedure Probe_Modal_HFmt_PageCaption_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'PageCaption';
        Cached := false;
        Page.RunModal(Page::"PRB Fmt Card", Row);
    end;

    [Test]
    [HandlerFunctions('HFmt')]
    procedure Probe_Modal_HFmt_Next_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Next';
        Cached := false;
        Page.RunModal(Page::"PRB Fmt Card", Row);
    end;

    [Test]
    [HandlerFunctions('HFmt')]
    procedure Probe_Modal_HFmt_Act_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Act';
        Cached := false;
        Page.RunModal(Page::"PRB Fmt Card", Row);
    end;

    [Test]
    [HandlerFunctions('HFmt')]
    procedure Probe_Modal_HFmt_Act_Cached()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Act';
        Cached := true;
        Page.RunModal(Page::"PRB Fmt Card", Row);
    end;

    [ModalPageHandler]
    procedure HAgr(var P: TestPage "PRB AGR Card")
    var
        T: Text;
    begin
        if Cached then T := P.QtyCtl.Value();
        asserterror P.GoToKey('B');
        case Mode of
            'Value': Error('OBS ' + P.QtyCtl.Value());
            'AsInteger': Error('OBS %1', P.QtyCtl.AsInteger());
            'Editable': Error('OBS %1', P.QtyCtl.Editable());
            'AssertEquals': begin P.QtyCtl.AssertEquals(2); Error('OBS assertequals(2) passed'); end;
            'Close': begin P.Close(); Error('OBS close returned'); end;
            'OKInvoke': begin P.OK().Invoke(); Error('OBS ok invoked'); end;
            'PageCaption': Error('OBS ' + P.Caption());
            'Next': Error('OBS next=%1', P.Next());
            'Act': begin P.Act.Invoke(); Error('OBS act invoked'); end;
            'Count': Error('OBS rows=%1 NoCtlRead=[%2]', RowCount(), 'n/a');
        end;
    end;

    [Test]
    [HandlerFunctions('HAgr')]
    procedure Probe_Modal_HAgr_Value_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Value';
        Cached := false;
        Page.RunModal(Page::"PRB AGR Card", Row);
    end;

    [Test]
    [HandlerFunctions('HAgr')]
    procedure Probe_Modal_HAgr_Value_Cached()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Value';
        Cached := true;
        Page.RunModal(Page::"PRB AGR Card", Row);
    end;

    [Test]
    [HandlerFunctions('HAgr')]
    procedure Probe_Modal_HAgr_AsInteger_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'AsInteger';
        Cached := false;
        Page.RunModal(Page::"PRB AGR Card", Row);
    end;

    [Test]
    [HandlerFunctions('HAgr')]
    procedure Probe_Modal_HAgr_AsInteger_Cached()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'AsInteger';
        Cached := true;
        Page.RunModal(Page::"PRB AGR Card", Row);
    end;

    [Test]
    [HandlerFunctions('HAgr')]
    procedure Probe_Modal_HAgr_Editable_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Editable';
        Cached := false;
        Page.RunModal(Page::"PRB AGR Card", Row);
    end;

    [Test]
    [HandlerFunctions('HAgr')]
    procedure Probe_Modal_HAgr_Editable_Cached()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Editable';
        Cached := true;
        Page.RunModal(Page::"PRB AGR Card", Row);
    end;

    [Test]
    [HandlerFunctions('HAgr')]
    procedure Probe_Modal_HAgr_AssertEquals_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'AssertEquals';
        Cached := false;
        Page.RunModal(Page::"PRB AGR Card", Row);
    end;

    [Test]
    [HandlerFunctions('HAgr')]
    procedure Probe_Modal_HAgr_AssertEquals_Cached()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'AssertEquals';
        Cached := true;
        Page.RunModal(Page::"PRB AGR Card", Row);
    end;

    [Test]
    [HandlerFunctions('HAgr')]
    procedure Probe_Modal_HAgr_Close_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Close';
        Cached := false;
        Page.RunModal(Page::"PRB AGR Card", Row);
    end;

    [Test]
    [HandlerFunctions('HAgr')]
    procedure Probe_Modal_HAgr_OKInvoke_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'OKInvoke';
        Cached := false;
        Page.RunModal(Page::"PRB AGR Card", Row);
    end;

    [Test]
    [HandlerFunctions('HAgr')]
    procedure Probe_Modal_HAgr_PageCaption_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'PageCaption';
        Cached := false;
        Page.RunModal(Page::"PRB AGR Card", Row);
    end;

    [Test]
    [HandlerFunctions('HAgr')]
    procedure Probe_Modal_HAgr_Next_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Next';
        Cached := false;
        Page.RunModal(Page::"PRB AGR Card", Row);
    end;

    [Test]
    [HandlerFunctions('HAgr')]
    procedure Probe_Modal_HAgr_Act_Fresh()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Act';
        Cached := false;
        Page.RunModal(Page::"PRB AGR Card", Row);
    end;

    [Test]
    [HandlerFunctions('HAgr')]
    procedure Probe_Modal_HAgr_Act_Cached()
    var
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('A');
        Mode := 'Act';
        Cached := true;
        Page.RunModal(Page::"PRB AGR Card", Row);
    end;

    [ModalPageHandler]
    procedure HSwallow(var P: TestPage "PRB Fmt Card")
    begin
        asserterror P.GoToKey('B');
    end;

    [Test]
    [HandlerFunctions('HSwallow')]
    procedure Probe_Modal_TearDownInHandler_RunModalReturn()
    var
        Row: Record "PRB Row";
        Result: Action;
    begin
        Seed();
        Row.Get('A');
        Result := Page.RunModal(Page::"PRB Fmt Card", Row);
        Error('OBS runmodal returned %1', Result);
    end;

    [ModalPageHandler]
    procedure NeverRunHandler(var P: TestPage "PRB Fmt Card")
    begin
        Error('PRB handler ran');
    end;

    // nested: page A's action runs page B modally and B fails at open
    [Test]
    [HandlerFunctions('NeverRunHandler')]
    procedure Probe_Nested_HostAction_FailingModal_ErrorText()
    var
        P: TestPage "PRB Host Card";
    begin
        Seed();
        P.OpenView();
        P.OpenFailing.Invoke();
        Error('OBS no error');
    end;

    [Test]
    [HandlerFunctions('NeverRunHandler')]
    procedure Probe_Nested_HostAfterFailedAction_ReadsValue()
    var
        P: TestPage "PRB Host Card";
    begin
        Seed();
        P.OpenView();
        asserterror P.OpenFailing.Invoke();
        Error('OBS host after failed nested modal NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    [HandlerFunctions('NeverRunHandler')]
    procedure Probe_Nested_HostAfterFailedAction_Close()
    var
        P: TestPage "PRB Host Card";
    begin
        Seed();
        P.OpenView();
        asserterror P.OpenFailing.Invoke();
        P.Close();
        Error('OBS host close ok');
    end;

    [Test]
    [HandlerFunctions('NeverRunHandler')]
    procedure Probe_Nested_HostAfterFailedAction_Reopen()
    var
        P: TestPage "PRB Host Card";
    begin
        Seed();
        P.OpenView();
        asserterror P.OpenFailing.Invoke();
        P.OpenView();
        Error('OBS host reopen ok NoCtl=' + P.NoCtl.Value());
    end;

    // Trap + Page.Run of a page that fails at open
    [Test]
    procedure Probe_Trap_PageRunFails_ReadsTrapped()
    var
        P: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('B');
        P.Trap();
        asserterror Page.Run(Page::"PRB Fmt Card", Row);
        Error('OBS trapped page NoCtl=' + P.NoCtl.Value());
    end;

    [Test]
    procedure Probe_Trap_PageRunFails_Close()
    var
        P: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('B');
        P.Trap();
        asserterror Page.Run(Page::"PRB Fmt Card", Row);
        P.Close();
        Error('OBS trapped page close ok');
    end;

    [Test]
    procedure Probe_Trap_PageRunFails_OpenView()
    var
        P: TestPage "PRB Fmt Card";
        Row: Record "PRB Row";
    begin
        Seed();
        Row.Get('B');
        P.Trap();
        asserterror Page.Run(Page::"PRB Fmt Card", Row);
        P.OpenView();
        Error('OBS trapped page openview ok NoCtl=' + P.NoCtl.Value());
    end;
}
