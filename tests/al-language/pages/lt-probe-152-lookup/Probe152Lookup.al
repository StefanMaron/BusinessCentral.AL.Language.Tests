// Windows reference probe for StefanMaron/MsDyn365Bc.On.Linux#152: TestPage Lookup on a field
// whose table relation names a table with no LookupPageId. Every test reports what happened
// in its error text, so the failure message is the measurement:
//   "returned"            the lookup returned without an error
//   "error: <text>"       the lookup raised <text>
//   "handler ran"         the ModalPageHandler was called
// On Linux BC 27.5, 28.4 and 29.0: no handler -> "error: Unhandled UI: ModalPage ";
// with a ModalPageHandler declared -> an uncatchable NullReferenceException.
table 97900 "BCL152 DdOnly"
{
    DataClassification = SystemMetadata;
    DrillDownPageId = "BCL152 DdOnly List";

    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 97901 "BCL152 NoPage"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 97902 "BCL152 Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; DdOnly; Code[10]) { TableRelation = "BCL152 DdOnly".Code; }
        field(3; NoPage; Code[10]) { TableRelation = "BCL152 NoPage".Code; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 97903 "BCL152 DdOnly List"
{
    PageType = List;
    SourceTable = "BCL152 DdOnly";
    ApplicationArea = All;
    UsageCategory = None;

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
}

page 97904 "BCL152 Host Card"
{
    PageType = Card;
    SourceTable = "BCL152 Host";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(DdOnlyCtl; Rec.DdOnly) { ApplicationArea = All; }
                field(NoPageCtl; Rec.NoPage) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 97905 "BCL152 Lookup Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P152_DdOnly_NoHandler()
    begin
        Report(1);
    end;

    [Test]
    procedure P152_NoPage_NoHandler()
    begin
        Report(2);
    end;

    [Test]
    [HandlerFunctions('DdOnlyModal')]
    procedure P152_DdOnly_WithModalHandler()
    begin
        Report(1);
    end;

    [Test]
    [HandlerFunctions('DdOnlyModal')]
    procedure P152_NoPage_WithModalHandler()
    begin
        Report(2);
    end;

    [ModalPageHandler]
    procedure DdOnlyModal(var P: TestPage "BCL152 DdOnly List")
    begin
        Error('handler ran');
    end;

    local procedure Report(Which: Integer)
    var
        Host: Record "BCL152 Host";
        Card: TestPage "BCL152 Host Card";
        Outcome: Text;
    begin
        Prepare(Host);
        Card.OpenEdit();
        Card.GoToRecord(Host);
        if TryLookup(Card, Which) then
            Outcome := 'returned'
        else
            Outcome := 'error: ' + GetLastErrorText();
        Card.Close();
        Host.Get('H1');
        Error('%1 | stored DdOnly=%2 NoPage=%3', Outcome, Host.DdOnly, Host.NoPage);
    end;

    [TryFunction]
    local procedure TryLookup(var Card: TestPage "BCL152 Host Card"; Which: Integer)
    begin
        if Which = 1 then
            Card.DdOnlyCtl.Lookup()
        else
            Card.NoPageCtl.Lookup();
    end;

    local procedure Prepare(var Host: Record "BCL152 Host")
    var
        DdOnly: Record "BCL152 DdOnly";
        NoPage: Record "BCL152 NoPage";
    begin
        if not DdOnly.Get('D1') then begin
            DdOnly."Code" := 'D1';
            DdOnly.Insert();
        end;
        if not NoPage.Get('N1') then begin
            NoPage."Code" := 'N1';
            NoPage.Insert();
        end;
        if not Host.Get('H1') then begin
            Host."Code" := 'H1';
            Host.Insert();
        end;
    end;
}
