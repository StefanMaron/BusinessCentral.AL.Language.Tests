// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-linktable-xmlport-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 67503-67504, xmlports 67505-67506, codeunits 67507-67508
// Probe: a child table element that sets LinkTable to its parent element and has no LinkFields, on temporary table elements (UseTemporary) and with a persistent child table. The XmlPort compiles; export and import observe which rows are visited and written (issue 580 item 2).
// BC versions: 27+

table 67503 "LT XLT Parent"
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

table 67504 "LT XLT Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Parent Id"; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67508 "LT XLT Log"
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
}

xmlport 67505 "LT XLT Both Temp"
{
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ParentRow; "LT XLT Parent")
            {
                UseTemporary = true;
                fieldelement(Id; ParentRow.Id) { }
                tableelement(ChildRow; "LT XLT Child")
                {
                    LinkTable = ParentRow;
                    UseTemporary = true;
                    fieldelement(Id; ChildRow.Id) { }
                    fieldelement(ParentId; ChildRow."Parent Id") { }

                    trigger OnAfterGetRecord()
                    begin
                        Log.Add('export child ' + Format(ChildRow.Id) + ' under parent ' + Format(ParentRow.Id));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        Log.Add('import child ' + Format(ChildRow.Id) + ' under parent ' + Format(ParentRow.Id));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('export parent ' + Format(ParentRow.Id));
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('import parent ' + Format(ParentRow.Id));
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        if currXMLport.Import() then
            exit;
        ParentRow.Init();
        ParentRow.Id := 1;
        ParentRow.Insert();
        ParentRow.Id := 2;
        ParentRow.Insert();
        ChildRow.Init();
        ChildRow.Id := 10;
        ChildRow."Parent Id" := 1;
        ChildRow.Insert();
        ChildRow.Id := 11;
        ChildRow."Parent Id" := 1;
        ChildRow.Insert();
        ChildRow.Id := 20;
        ChildRow."Parent Id" := 2;
        ChildRow.Insert();
        ChildRow.Id := 30;
        ChildRow."Parent Id" := 0;
        ChildRow.Insert();
    end;

    var
        Log: Codeunit "LT XLT Log";
}

xmlport 67506 "LT XLT Child Persistent"
{
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ParentRow; "LT XLT Parent")
            {
                UseTemporary = true;
                fieldelement(Id; ParentRow.Id) { }
                tableelement(ChildRow; "LT XLT Child")
                {
                    LinkTable = ParentRow;
                    fieldelement(Id; ChildRow.Id) { }
                    fieldelement(ParentId; ChildRow."Parent Id") { }

                    trigger OnAfterGetRecord()
                    begin
                        Log.Add('export child ' + Format(ChildRow.Id) + ' under parent ' + Format(ParentRow.Id));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        Log.Add('import child ' + Format(ChildRow.Id) + ' under parent ' + Format(ParentRow.Id));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('export parent ' + Format(ParentRow.Id));
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('import parent ' + Format(ParentRow.Id));
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        if currXMLport.Import() then
            exit;
        ParentRow.Init();
        ParentRow.Id := 1;
        ParentRow.Insert();
        ParentRow.Id := 2;
        ParentRow.Insert();
    end;

    var
        Log: Codeunit "LT XLT Log";
}

codeunit 67507 "LT XLT Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT XLT Log";

    local procedure ReadAll(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line;
        end;
        exit(Result);
    end;

    local procedure Document(): Text
    begin
        exit('<?xml version="1.0" encoding="UTF-8" standalone="no"?><Root><ParentRow><Id>1</Id><ChildRow><Id>10</Id><ParentId>1</ParentId></ChildRow><ChildRow><Id>11</Id><ParentId>1</ParentId></ChildRow></ParentRow><ParentRow><Id>2</Id><ChildRow><Id>20</Id><ParentId>2</ParentId></ChildRow></ParentRow></Root>');
    end;

    [Test]
    procedure BothTemporary_Export()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "LT XLT Both Temp";
        OutS: OutStream;
    begin
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('xml', ReadAll(TempBlob));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure BothTemporary_Import()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "LT XLT Both Temp";
        OutS: OutStream;
        InS: InStream;
    begin
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Document());
        TempBlob.CreateInStream(InS);
        Port.SetSource(InS);
        Port.Import();
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure PersistentChild_Export()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "LT XLT Child Persistent";
        Child: Record "LT XLT Child";
        OutS: OutStream;
    begin
        Child.DeleteAll();
        Child.Id := 10;
        Child."Parent Id" := 1;
        Child.Insert();
        Child.Id := 11;
        Child."Parent Id" := 1;
        Child.Insert();
        Child.Id := 20;
        Child."Parent Id" := 2;
        Child.Insert();
        Child.Id := 30;
        Child."Parent Id" := 0;
        Child.Insert();
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('xml', ReadAll(TempBlob));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure PersistentChild_Import()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "LT XLT Child Persistent";
        Child: Record "LT XLT Child";
        OutS: OutStream;
        InS: InStream;
        Rows: Text;
    begin
        Child.DeleteAll();
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Document());
        TempBlob.CreateInStream(InS);
        Port.SetSource(InS);
        Port.Import();
        Observer.Observe('log', Log.Take());
        if Child.FindSet() then
            repeat
                Rows += Format(Child.Id) + '/' + Format(Child."Parent Id") + ' ';
            until Child.Next() = 0;
        Observer.Observe('child_rows', Rows);
        Observer.Finish();
    end;
}
