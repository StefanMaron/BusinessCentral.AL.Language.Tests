// Windows check of Linux suspects. Every test ends by raising its observations as an error (Probe Observer Finish).
codeunit 79901 "WC File Download"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TDownload(From: Text; var ToFile: Text; var R: Boolean)
    begin
        R := File.Download(From, 'Title', '', '', ToFile);
    end;

    [TryFunction]
    local procedure TDownloadStream(var InS: InStream; var ToFile: Text; var R: Boolean)
    begin
        R := File.DownloadFromStream(InS, 'Title', '', '', ToFile);
    end;

    [Test]
    procedure Download_File()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        OutS: OutStream;
        P: Text;
        ToFile: Text;
        R: Boolean;
    begin
        P := TemporaryPath() + 'wc-download.txt';
        F.Create(P);
        F.CreateOutStream(OutS);
        OutS.WriteText('download content');
        F.Close();
        R := true;
        ToFile := 'untouched';
        if TDownload(P, ToFile, R) then
            Observer.Observe('download', 'ok ret=' + Format(R) + ' tofile=[' + ToFile + ']')
        else
            Observer.ObserveError('download');
        Observer.Finish();
    end;

    [Test]
    procedure Download_FromStream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        ToFile: Text;
        R: Boolean;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('download content');
        TempBlob.CreateInStream(InS);
        R := true;
        ToFile := 'untouched';
        if TDownloadStream(InS, ToFile, R) then
            Observer.Observe('downloadfromstream', 'ok ret=' + Format(R) + ' tofile=[' + ToFile + ']')
        else
            Observer.ObserveError('downloadfromstream');
        Observer.Finish();
    end;
}

codeunit 79911 "WC Evaluate PageStyle"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Evaluate_PageStyle()
    var
        Observer: Codeunit "Probe Observer";
        V: PageStyle;
        R: Boolean;
    begin
        R := Evaluate(V, 'Strong');
        Observer.Observe('evaluate_Strong', Format(R) + ' value=' + Format(V));
        R := Evaluate(V, 'NoSuchStyle');
        Observer.Observe('evaluate_bad', Format(R) + ' value=' + Format(V));
        Observer.Finish();
    end;
}

codeunit 79912 "WC Evaluate HttpRequestType"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Evaluate_HttpRequestType()
    var
        Observer: Codeunit "Probe Observer";
        V: HttpRequestType;
        R: Boolean;
    begin
        R := Evaluate(V, 'Get');
        Observer.Observe('evaluate_Get', Format(R) + ' value=' + Format(V));
        R := Evaluate(V, 'NoSuchType');
        Observer.Observe('evaluate_bad', Format(R) + ' value=' + Format(V));
        Observer.Finish();
    end;
}

codeunit 79913 "WC Evaluate PBT ErrorLevel"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Evaluate_PageBackgroundTaskErrorLevel()
    var
        Observer: Codeunit "Probe Observer";
        V: PageBackgroundTaskErrorLevel;
        R: Boolean;
    begin
        R := Evaluate(V, 'Warning');
        Observer.Observe('evaluate_Warning', Format(R) + ' value=' + Format(V));
        R := Evaluate(V, 'NoSuchLevel');
        Observer.Observe('evaluate_bad', Format(R) + ' value=' + Format(V));
        Observer.Finish();
    end;
}

table 79920 "WC Flow Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; ChildCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("WC Flow Child" where("Parent No." = field("No.")));
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 79921 "WC Flow Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Parent No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
    }

    keys
    {
        key(PK; "Parent No.", "Line No.") { Clustered = true; }
    }
}

page 79922 "WC Flow Card"
{
    PageType = Card;
    SourceTable = "WC Flow Parent";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
            field(ChildCount; Rec.ChildCount) { ApplicationArea = All; Editable = true; }
        }
    }
}

codeunit 79923 "WC FlowField SetValue"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySet(var Card: TestPage "WC Flow Card"; V: Integer)
    begin
        Card.ChildCount.SetValue(V);
    end;

    [Test]
    procedure TestPage_SetValue_FlowField()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "WC Flow Parent";
        Card: TestPage "WC Flow Card";
    begin
        Parent.DeleteAll();
        Parent.Init();
        Parent."No." := 'F1';
        Parent.Insert();
        Card.OpenEdit();
        Card.GotoRecord(Parent);
        Observer.Observe('before', '[' + Card.ChildCount.Value() + '] editable=' + Format(Card.ChildCount.Editable()));
        if TrySet(Card, 5) then
            Observer.Observe('setvalue', 'ok value=[' + Card.ChildCount.Value() + ']')
        else
            Observer.ObserveError('setvalue');
        Card.Close();
        Observer.Finish();
    end;
}

page 79930 "WC Gesture List"
{
    PageType = List;
    SourceTable = "WC Flow Parent";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CtxAction)
            {
                ApplicationArea = All;
                Gesture = ContextMenu;

                trigger OnAction()
                begin
                end;
            }
        }
    }
}

codeunit 79931 "WC Gesture ContextMenu"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOpen(var P: TestPage "WC Gesture List")
    begin
        P.OpenView();
    end;

    [Test]
    procedure Page_GestureContextMenu_Opens()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "WC Gesture List";
    begin
        if TryOpen(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Finish();
    end;
}
