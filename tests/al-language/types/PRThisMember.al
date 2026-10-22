// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-this-keyword
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// `this.Member` / `this.Procedure()` inside a report (trigger and data item trigger), a page, an xmlport (field trigger) and a query (trigger and procedures) read and write the
// object's OWN variables and call its own local procedures: the counters below count 10, 11, 12 (report), 3, 4 (page), 20, 21, 22 (xmlport) and 30, 31, 32 (query).
// A query procedure called from outside sees the same instance (Describe after Bump reads 32).
// Fixtures used: self-contained table 69540, codeunit 69541 (log), report 69540, page 69541, xmlport 69540, query 69540, codeunit 69542 (tests)
// BC versions: 27.5

table 69540 "PR This Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69541 "PR This Log"
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

report 69540 "PR This Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "PR This Row")
        {
            trigger OnAfterGetRecord()
            var
                Log: Codeunit "PR This Log";
            begin
                this.Counter += 1;
                Log.Add('row' + Format(this.Counter) + ':' + this.Describe());
            end;
        }
    }

    var
        Counter: Integer;

    trigger OnPreReport()
    var
        Log: Codeunit "PR This Log";
    begin
        this.Counter := 10;
        Log.Add('pre:' + this.Describe() + ':' + Format(this.Counter));
    end;

    local procedure Describe(): Text
    begin
        exit('report counter ' + Format(Counter));
    end;
}

page 69541 "PR This Page"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "PR This Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }

    var
        Counter: Integer;

    trigger OnOpenPage()
    var
        Log: Codeunit "PR This Log";
    begin
        this.Counter := 3;
        Log.Add('open:' + this.Describe() + ':' + Format(this.Counter));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PR This Log";
    begin
        this.Counter += 1;
        Log.Add('row:' + this.Describe());
    end;

    local procedure Describe(): Text
    begin
        exit('page counter ' + Format(Counter));
    end;
}

xmlport 69540 "PR This XmlPort"
{
    Direction = Export;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "PR This Row")
            {
                fieldelement(Id; Row.Id)
                {
                    trigger OnBeforePassField()
                    var
                        Log: Codeunit "PR This Log";
                    begin
                        this.Counter += 1;
                        Log.Add('field' + Format(this.Counter) + ':' + this.Describe());
                    end;
                }
            }
        }
    }

    var
        Counter: Integer;

    trigger OnPreXmlPort()
    var
        Log: Codeunit "PR This Log";
    begin
        this.Counter := 20;
        Log.Add('pre:' + this.Describe() + ':' + Format(this.Counter));
    end;

    local procedure Describe(): Text
    begin
        exit('xmlport counter ' + Format(Counter));
    end;
}

query 69540 "PR This Query"
{
    elements
    {
        dataitem(Row; "PR This Row")
        {
            column(Id; Id) { }
        }
    }

    var
        Counter: Integer;

    trigger OnBeforeOpen()
    var
        Log: Codeunit "PR This Log";
    begin
        this.Counter := 30;
        Log.Add('beforeopen:' + this.Describe() + ':' + Format(this.Counter));
    end;

    procedure Describe(): Text
    begin
        exit('query counter ' + Format(Counter));
    end;

    procedure Bump(): Integer
    begin
        this.Counter += 1;
        exit(this.Counter);
    end;
}

codeunit 69542 "PR This Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "PR This Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
    end;

    [Test]
    procedure This_InReportTriggers()
    var
        Rpt: Report "PR This Report";
        Log: Codeunit "PR This Log";
        Observer: Codeunit "PR This Log";
        Obs: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Take();
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Obs.Observe('log', Log.Take());
        Obs.Expect('log', 'pre:report counter 10:10;row11:report counter 11;row12:report counter 12;');
        Obs.Verify();
    end;

    [Test]
    procedure This_InPageTriggers()
    var
        Pg: TestPage "PR This Page";
        Log: Codeunit "PR This Log";
        Obs: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Take();
        Pg.OpenView();
        Obs.Observe('log', Log.Take());
        Pg.Close();
        Obs.Expect('log', 'open:page counter 3:3;row:page counter 4;');
        Obs.Verify();
    end;

    [Test]
    procedure This_InXmlPortTriggers()
    var
        XmlPort: XmlPort "PR This XmlPort";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Log: Codeunit "PR This Log";
        Obs: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        XmlPort.SetDestination(OutS);
        XmlPort.Export();
        Obs.Observe('log', Log.Take());
        Obs.Expect('log', 'pre:xmlport counter 20:20;field21:xmlport counter 21;field22:xmlport counter 22;');
        Obs.Verify();
    end;

    [Test]
    procedure This_InQueryProceduresAndTriggers()
    var
        Q: Query "PR This Query";
        Log: Codeunit "PR This Log";
        Obs: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Take();
        Q.Open();
        Obs.Observe('log_after_open', Log.Take());
        Obs.Observe('describe_after_open', Q.Describe());
        Obs.Observe('bump_1', Format(Q.Bump()));
        Obs.Observe('bump_2', Format(Q.Bump()));
        Obs.Observe('describe_after_bumps', Q.Describe());
        Obs.Expect('log_after_open', 'beforeopen:query counter 30:30;');
        Obs.Expect('describe_after_open', 'query counter 30');
        Obs.Expect('bump_1', '31');
        Obs.Expect('bump_2', '32');
        Obs.Expect('describe_after_bumps', 'query counter 32');
        Obs.Verify();
    end;
}
