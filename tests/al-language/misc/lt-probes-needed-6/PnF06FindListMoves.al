// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onfindrecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73869 (log), table 73870, pages 73871, 73872 and 73873, codeunit 73874
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "Find list" (Page reads after an action, and a list that ends inside its window, corpus bump 7)
// Facts: log of OnFindRecord (F), OnNextRecord (N), OnAfterGetRecord (R) and OnAfterGetCurrRecord (C) when a TestPage opens a list and moves First, Next, Last and Previous,
//   on an ascending view, on a descending view (Rec.Ascending(false) in OnOpenPage) and for a list without OnFindRecord, over 3 and over 25 rows
// BC versions: 29 (27 and 28 by CI)

codeunit 73869 "LT PnF FL Log"
{
    SingleInstance = true;

    var
        Entries: Text;

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
}

table 73870 "LT PnF FL Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 73871 "LT PnF FL Asc"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF FL Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('F(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('N(' + Format(Steps) + ')');
        exit(Rec.Next(Steps));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('C');
    end;
}

page 73872 "LT PnF FL Desc"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF FL Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Ascending(false);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('F(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('N(' + Format(Steps) + ')');
        exit(Rec.Next(Steps));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('C');
    end;
}

page 73873 "LT PnF FL Plain Desc"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF FL Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Ascending(false);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('C');
    end;
}

codeunit 73874 "LT PnF Find List Moves"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Rows: Integer)
    var
        Row: Record "LT PnF FL Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Rows do begin
            Row.Id := i;
            Row.Name := 'n' + Format(i);
            Row.Insert();
        end;
    end;

    local procedure MovesAsc(Rows: Integer; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT PnF FL Asc";
    begin
        Seed(Rows);
        Log.Take();
        P.OpenView();
        Observer.Observe(Prefix + 'open', Log.Take());
        P.Next();
        Observer.Observe(Prefix + 'next', Log.Take());
        P.Last();
        Observer.Observe(Prefix + 'last', Log.Take());
        P.Previous();
        Observer.Observe(Prefix + 'prev', Log.Take());
        P.First();
        Observer.Observe(Prefix + 'first', Log.Take());
        P.Close();
        Log.Take();
    end;

    local procedure MovesDesc(Rows: Integer; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT PnF FL Desc";
    begin
        Seed(Rows);
        Log.Take();
        P.OpenView();
        Observer.Observe(Prefix + 'open', Log.Take());
        P.Next();
        Observer.Observe(Prefix + 'next', Log.Take());
        P.Last();
        Observer.Observe(Prefix + 'last', Log.Take());
        P.Previous();
        Observer.Observe(Prefix + 'prev', Log.Take());
        P.First();
        Observer.Observe(Prefix + 'first', Log.Take());
        P.Close();
        Log.Take();
    end;

    local procedure MovesPlain(Rows: Integer; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT PnF FL Plain Desc";
    begin
        Seed(Rows);
        Log.Take();
        P.OpenView();
        Observer.Observe(Prefix + 'open', Log.Take());
        P.Next();
        Observer.Observe(Prefix + 'next', Log.Take());
        P.Last();
        Observer.Observe(Prefix + 'last', Log.Take());
        P.Previous();
        Observer.Observe(Prefix + 'prev', Log.Take());
        P.First();
        Observer.Observe(Prefix + 'first', Log.Take());
        P.Close();
        Log.Take();
    end;

    [Test]
    procedure FindList_Ascending_3Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesAsc(3, 'asc3_', Observer);
        Observer.Expect('asc3_open', 'F(=><);R1;N(1);R2;N(1);R3;N(1);R1;N(-1);F(=);R1;C;');
        Observer.Expect('asc3_next', 'R2;F(=);R2;C;');
        Observer.Expect('asc3_last', 'R3;F(=);R3;C;');
        Observer.Expect('asc3_prev', 'R2;F(=);R2;C;');
        Observer.Expect('asc3_first', 'R1;F(=);R1;C;');
        Observer.Verify();
    end;

    [Test]
    procedure FindList_Ascending_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesAsc(25, 'asc25_', Observer);
        Observer.Expect('asc25_open', 'F(=><);R1;N(1);R2;N(1);R3;N(1);R4;N(1);R5;N(1);R6;N(1);R7;N(1);R8;N(1);R9;N(1);R10;N(1);R11;N(1);R12;N(1);R13;N(1);R14;N(1);R15;N(1);R16;N(1);R17;N(1);R18;N(1);R19;N(1);R20;R1;N(-1);F(=);R1;C;');
        Observer.Expect('asc25_next', 'R2;F(=);R2;C;');
        Observer.Expect('asc25_last', 'R20;N(1);R21;N(1);R22;N(1);R23;N(1);R24;N(1);R25;N(1);F(=);R25;C;');
        Observer.Expect('asc25_prev', 'R24;F(=);R24;C;');
        Observer.Expect('asc25_first', 'R1;F(=);R1;C;');
        Observer.Verify();
    end;

    [Test]
    procedure FindList_Descending_3Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesDesc(3, 'desc3_', Observer);
        Observer.Expect('desc3_open', 'F(=><);R1;N(1);N(-1);R2;N(-1);R3;N(-1);R1;F(=);R1;C;');
        Observer.Expect('desc3_next', '');
        Observer.Expect('desc3_last', '');
        Observer.Expect('desc3_prev', 'R2;F(=);R2;C;');
        Observer.Expect('desc3_first', 'R3;F(=);R3;C;');
        Observer.Verify();
    end;

    [Test]
    procedure FindList_Descending_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesDesc(25, 'desc25_', Observer);
        Observer.Expect('desc25_open', 'F(=><);R1;N(1);N(-1);R2;N(-1);R3;N(-1);R4;N(-1);R5;N(-1);R6;N(-1);R7;N(-1);R8;N(-1);R9;N(-1);R10;N(-1);R11;N(-1);R12;N(-1);R13;N(-1);R14;N(-1);R15;N(-1);R16;N(-1);R17;N(-1);R18;N(-1);R19;N(-1);R20;N(-1);R21;R1;F(=);R1;C;');
        Observer.Expect('desc25_next', '');
        Observer.Expect('desc25_last', '');
        Observer.Expect('desc25_prev', 'R2;F(=);R2;C;');
        Observer.Expect('desc25_first', 'R21;N(-1);R22;N(-1);R23;N(-1);R24;N(-1);R25;N(-1);F(=);R25;C;');
        Observer.Verify();
    end;

    [Test]
    procedure FindList_PlainDescending()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesPlain(3, 'plain3_', Observer);
        MovesPlain(25, 'plain25_', Observer);
        Observer.Expect('plain3_open', 'R3;R2;R1;R3;R3;C;');
        Observer.Expect('plain3_next', 'R2;R2;C;');
        Observer.Expect('plain3_last', 'R1;R1;C;');
        Observer.Expect('plain3_prev', 'R2;R2;C;');
        Observer.Expect('plain3_first', 'R3;R3;C;');
        Observer.Expect('plain25_open', 'R25;R24;R23;R22;R21;R20;R19;R18;R17;R16;R15;R14;R13;R12;R11;R10;R9;R8;R7;R6;R25;R25;C;');
        Observer.Expect('plain25_next', 'R24;R24;C;');
        Observer.Expect('plain25_last', 'R6;R5;R4;R3;R2;R1;R1;C;');
        Observer.Expect('plain25_prev', 'R2;R2;C;');
        Observer.Expect('plain25_first', 'R25;R25;C;');
        Observer.Verify();
    end;
    // Writer PW: trust-refusals probe list "descending find list step back": the open of the descending OnFindRecord list (with
    // OnAfterGetCurrRecord) at 1, 2, 19, 20 and 21 rows (3 and 25 are pinned above), and the ascending list at 19, 20 and 21 rows.
    [Test]
    procedure PW_FindList_Descending_1Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesDesc(1, 'desc1_', Observer);
        Observer.Expect('desc1_open', 'F(=><);R1;N(1);N(-1);F(=);R1;C;');
        Observer.Expect('desc1_next', '');
        Observer.Expect('desc1_last', '');
        Observer.Expect('desc1_prev', '');
        Observer.Expect('desc1_first', '');
        Observer.Verify();
    end;

    [Test]
    procedure PW_FindList_Descending_2Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesDesc(2, 'desc2_', Observer);
        Observer.Expect('desc2_open', 'F(=><);R1;N(1);N(-1);R2;N(-1);R1;F(=);R1;C;');
        Observer.Expect('desc2_next', '');
        Observer.Expect('desc2_last', '');
        Observer.Expect('desc2_prev', 'R2;F(=);R2;C;');
        Observer.Expect('desc2_first', '');
        Observer.Verify();
    end;

    [Test]
    procedure PW_FindList_Descending_19Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesDesc(19, 'desc19_', Observer);
        Observer.Expect('desc19_open', 'F(=><);R1;N(1);N(-1);R2;N(-1);R3;N(-1);R4;N(-1);R5;N(-1);R6;N(-1);R7;N(-1);R8;N(-1);R9;N(-1);R10;N(-1);R11;N(-1);R12;N(-1);R13;N(-1);R14;N(-1);R15;N(-1);R16;N(-1);R17;N(-1);R18;N(-1);R19;N(-1);R1;F(=);R1;C;');
        Observer.Expect('desc19_next', '');
        Observer.Expect('desc19_last', '');
        Observer.Expect('desc19_prev', 'R2;F(=);R2;C;');
        Observer.Expect('desc19_first', 'R19;F(=);R19;C;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_FindList_Descending_20Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesDesc(20, 'desc20_', Observer);
        Observer.Expect('desc20_open', 'F(=><);R1;N(1);N(-1);R2;N(-1);R3;N(-1);R4;N(-1);R5;N(-1);R6;N(-1);R7;N(-1);R8;N(-1);R9;N(-1);R10;N(-1);R11;N(-1);R12;N(-1);R13;N(-1);R14;N(-1);R15;N(-1);R16;N(-1);R17;N(-1);R18;N(-1);R19;N(-1);R20;N(-1);R1;F(=);R1;C;');
        Observer.Expect('desc20_next', '');
        Observer.Expect('desc20_last', '');
        Observer.Expect('desc20_prev', 'R2;F(=);R2;C;');
        Observer.Expect('desc20_first', 'R20;F(=);R20;C;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_FindList_Descending_21Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesDesc(21, 'desc21_', Observer);
        Observer.Expect('desc21_open', 'F(=><);R1;N(1);N(-1);R2;N(-1);R3;N(-1);R4;N(-1);R5;N(-1);R6;N(-1);R7;N(-1);R8;N(-1);R9;N(-1);R10;N(-1);R11;N(-1);R12;N(-1);R13;N(-1);R14;N(-1);R15;N(-1);R16;N(-1);R17;N(-1);R18;N(-1);R19;N(-1);R20;N(-1);R21;R1;F(=);R1;C;');
        Observer.Expect('desc21_next', '');
        Observer.Expect('desc21_last', '');
        Observer.Expect('desc21_prev', 'R2;F(=);R2;C;');
        Observer.Expect('desc21_first', 'R21;N(-1);R21;F(=);R21;C;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_FindList_Ascending_19Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesAsc(19, 'asce19_', Observer);
        Observer.Expect('asce19_open', 'F(=><);R1;N(1);R2;N(1);R3;N(1);R4;N(1);R5;N(1);R6;N(1);R7;N(1);R8;N(1);R9;N(1);R10;N(1);R11;N(1);R12;N(1);R13;N(1);R14;N(1);R15;N(1);R16;N(1);R17;N(1);R18;N(1);R19;N(1);R1;N(-1);F(=);R1;C;');
        Observer.Expect('asce19_next', 'R2;F(=);R2;C;');
        Observer.Expect('asce19_last', 'R19;F(=);R19;C;');
        Observer.Expect('asce19_prev', 'R18;F(=);R18;C;');
        Observer.Expect('asce19_first', 'R1;F(=);R1;C;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_FindList_Ascending_20Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesAsc(20, 'asce20_', Observer);
        Observer.Expect('asce20_open', 'F(=><);R1;N(1);R2;N(1);R3;N(1);R4;N(1);R5;N(1);R6;N(1);R7;N(1);R8;N(1);R9;N(1);R10;N(1);R11;N(1);R12;N(1);R13;N(1);R14;N(1);R15;N(1);R16;N(1);R17;N(1);R18;N(1);R19;N(1);R20;R1;N(-1);F(=);R1;C;');
        Observer.Expect('asce20_next', 'R2;F(=);R2;C;');
        Observer.Expect('asce20_last', 'R20;N(1);R20;F(=);R20;C;');
        Observer.Expect('asce20_prev', 'R19;F(=);R19;C;');
        Observer.Expect('asce20_first', 'R1;F(=);R1;C;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_FindList_Ascending_21Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesAsc(21, 'asce21_', Observer);
        Observer.Expect('asce21_open', 'F(=><);R1;N(1);R2;N(1);R3;N(1);R4;N(1);R5;N(1);R6;N(1);R7;N(1);R8;N(1);R9;N(1);R10;N(1);R11;N(1);R12;N(1);R13;N(1);R14;N(1);R15;N(1);R16;N(1);R17;N(1);R18;N(1);R19;N(1);R20;R1;N(-1);F(=);R1;C;');
        Observer.Expect('asce21_next', 'R2;F(=);R2;C;');
        Observer.Expect('asce21_last', 'R20;N(1);R21;N(1);F(=);R21;C;');
        Observer.Expect('asce21_prev', 'R20;F(=);R20;C;');
        Observer.Expect('asce21_first', 'R1;F(=);R1;C;');
        Observer.Verify();
    end;

    // Writer PW: trust-refusals probe list "rows a GoToKey past a full 20-row window reads": GoToKey on the OnFindRecord lists after the open
    // read a full window. Each step's trigger log.
    local procedure PwGoToAsc(Rows: Integer; K1: Integer; K2: Integer; K3: Integer; ObserveFirst: Boolean; ObserveRest: Boolean; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT PnF FL Asc";
        Row: Record "LT PnF FL Row";
    begin
        Seed(Rows);
        Log.Take();
        P.OpenView();
        Log.Take();
        Row.Get(K1);
        if ObserveFirst then
            Observer.Observe('goto' + Format(K1), Format(P.GoToRecord(Row)) + '|' + P.Id.Value() + '|' + Log.Take())
        else
            P.GoToRecord(Row);
        Log.Take();
        if ObserveRest then begin
            Observer.Observe('goToKey' + Format(K2), Format(P.GoToKey(K2)) + '|' + P.Id.Value() + '|' + Log.Take());
            Observer.Observe('goToKey' + Format(K3), Format(P.GoToKey(K3)) + '|' + P.Id.Value() + '|' + Log.Take());
            P.Next();
            Observer.Observe('next', P.Id.Value() + '|' + Log.Take());
        end;
        P.Close();
        Log.Take();
    end;

    local procedure PwGoToDesc(Rows: Integer; K1: Integer; K2: Integer; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT PnF FL Desc";
    begin
        Seed(Rows);
        Log.Take();
        P.OpenView();
        Log.Take();
        Observer.Observe('goToKey' + Format(K1), Format(P.GoToKey(K1)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('goToKey' + Format(K2), Format(P.GoToKey(K2)) + '|' + P.Id.Value() + '|' + Log.Take());
        P.Next();
        Observer.Observe('next', P.Id.Value() + '|' + Log.Take());
        P.Close();
        Log.Take();
    end;

    [Test]
    procedure PW_GoToKey_Ascending_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwGoToAsc(25, 23, 5, 25, true, true, Observer);
        Observer.Expect('goto23', 'Yes|23|R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;R6;F(=);R6;C;R7;F(=);R7;C;R8;F(=);R8;C;R9;F(=);R9;C;R10;F(=);R10;C;R11;F(=);R11;C;R12;F(=);R12;C;R13;F(=);R13;C;R14;F(=);R14;C;R15;F(=);R15;C;R16;F(=);R16;C;R17;F(=);R17;C;R18;F(=);R18;C;R19;F(=);R19;C;R20;N(1);R21;N(1);R22;N(1);R23;N(1);R24;N(1);R25;N(1);R20;F(=);R20;C;R21;F(=);R21;C;R22;F(=);R22;C;R23;F(=);R23;C;');
        Observer.Expect('goToKey5', 'Yes|5|R1;F(=);R1;C;R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;');
        Observer.Expect('goToKey25', 'Yes|25|R1;F(=);R1;C;R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;R6;F(=);R6;C;R7;F(=);R7;C;R8;F(=);R8;C;R9;F(=);R9;C;R10;F(=);R10;C;R11;F(=);R11;C;R12;F(=);R12;C;R13;F(=);R13;C;R14;F(=);R14;C;R15;F(=);R15;C;R16;F(=);R16;C;R17;F(=);R17;C;R18;F(=);R18;C;R19;F(=);R19;C;R20;F(=);R20;C;R21;F(=);R21;C;R22;F(=);R22;C;R23;F(=);R23;C;R24;F(=);R24;C;R25;F(=);R25;C;');
        Observer.Expect('next', '25|');
        Observer.Verify();
    end;

    [Test]
    procedure PW_GoToKey_Ascending_45Rows_FarJump()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwGoToAsc(45, 40, 21, 45, true, false, Observer);
        Observer.Expect('goto40', 'Yes|40|R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;R6;F(=);R6;C;R7;F(=);R7;C;R8;F(=);R8;C;R9;F(=);R9;C;R10;F(=);R10;C;R11;F(=);R11;C;R12;F(=);R12;C;R13;F(=);R13;C;R14;F(=);R14;C;R15;F(=);R15;C;R16;F(=);R16;C;R17;F(=);R17;C;R18;F(=);R18;C;R19;F(=);R19;C;R20;N(1);R21;N(1);R22;N(1);R23;N(1);R24;N(1);R25;N(1);R26;N(1);R27;N(1);R28;N(1);R29;N(1);R30;N(1);R31;N(1);R32;N(1);R33;N(1);R34;N(1);R35;N(1);R36;N(1);R37;N(1);R38;N(1);R39;N(1);R40;R20;F(=);R20;C;R21;F(=);R21;C;R22;F(=);R22;C;R23;F(=);R23;C;R24;F(=);R24;C;R25;F(=);R25;C;R26;F(=);R26;C;R27;F(=);R27;C;R28;F(=);R28;C;R29;F(=);R29;C;R30;F(=);R30;C;R31;F(=);R31;C;R32;F(=);R32;C;R33;F(=);R33;C;R34;F(=);R34;C;R35;F(=);R35;C;R36;F(=);R36;C;R37;F(=);R37;C;R38;F(=);R38;C;R39;F(=);R39;C;R40;N(1);R41;N(1);R42;N(1);R43;N(1);R44;N(1);R45;N(1);R40;F(=);R40;C;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_GoToKey_Ascending_45Rows_AfterFarJump()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwGoToAsc(45, 40, 21, 45, false, true, Observer);
        Observer.Expect('goToKey21', 'Yes|21|R1;F(=);R1;C;R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;R6;F(=);R6;C;R7;F(=);R7;C;R8;F(=);R8;C;R9;F(=);R9;C;R10;F(=);R10;C;R11;F(=);R11;C;R12;F(=);R12;C;R13;F(=);R13;C;R14;F(=);R14;C;R15;F(=);R15;C;R16;F(=);R16;C;R17;F(=);R17;C;R18;F(=);R18;C;R19;F(=);R19;C;R20;F(=);R20;C;R21;F(=);R21;C;');
        Observer.Expect('goToKey45', 'Yes|45|R1;F(=);R1;C;R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;R6;F(=);R6;C;R7;F(=);R7;C;R8;F(=);R8;C;R9;F(=);R9;C;R10;F(=);R10;C;R11;F(=);R11;C;R12;F(=);R12;C;R13;F(=);R13;C;R14;F(=);R14;C;R15;F(=);R15;C;R16;F(=);R16;C;R17;F(=);R17;C;R18;F(=);R18;C;R19;F(=);R19;C;R20;F(=);R20;C;R21;F(=);R21;C;R22;F(=);R22;C;R23;F(=);R23;C;R24;F(=);R24;C;R25;F(=);R25;C;R26;F(=);R26;C;R27;F(=);R27;C;R28;F(=);R28;C;R29;F(=);R29;C;R30;F(=);R30;C;R31;F(=);R31;C;R32;F(=);R32;C;R33;F(=);R33;C;R34;F(=);R34;C;R35;F(=);R35;C;R36;F(=);R36;C;R37;F(=);R37;C;R38;F(=);R38;C;R39;F(=);R39;C;R40;F(=);R40;C;R41;F(=);R41;C;R42;F(=);R42;C;R43;F(=);R43;C;R44;F(=);R44;C;R45;F(=);R45;C;');
        Observer.Expect('next', '45|');
        Observer.Verify();
    end;

    [Test]
    procedure PW_GoToKey_Descending_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwGoToDesc(25, 3, 20, Observer);
        Observer.Expect('goToKey3', 'Yes|3|R21;N(-1);R22;N(-1);R23;N(-1);R24;N(-1);R25;N(-1);F(=);R25;C;R24;F(=);R24;C;R23;F(=);R23;C;R22;F(=);R22;C;R21;F(=);R21;C;R20;F(=);R20;C;R19;F(=);R19;C;R18;F(=);R18;C;R17;F(=);R17;C;R16;F(=);R16;C;R15;F(=);R15;C;R14;F(=);R14;C;R13;F(=);R13;C;R12;F(=);R12;C;R11;F(=);R11;C;R10;F(=);R10;C;R9;F(=);R9;C;R8;F(=);R8;C;R7;F(=);R7;C;R6;F(=);R6;C;R5;F(=);R5;C;R4;F(=);R4;C;R3;F(=);R3;C;');
        Observer.Expect('goToKey20', 'Yes|20|R25;F(=);R25;C;R24;F(=);R24;C;R23;F(=);R23;C;R22;F(=);R22;C;R21;F(=);R21;C;R20;F(=);R20;C;');
        Observer.Expect('next', '19|R19;F(=);R19;C;');
        Observer.Verify();
    end;
}
