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
}
