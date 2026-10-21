// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-maxoccurs-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 87275, 87276, 87279, xmlport 87277, runner codeunit 87278, test codeunit 87280 (writer QR)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: MaxOccurs and MinOccurs on CONTAINER text elements (the root text element with MaxOccurs = Once, a required container with
//   MinOccurs = Once and MaxOccurs = Once that holds a temporary table element, an optional container with MinOccurs = Zero and
//   MaxOccurs = Once inside each table row that holds a linked temporary table element, an optional leaf text element): Export with zero,
//   one and many rows (the XML text, lines joined by |), Import with each container absent, present once and present twice (the rows the
//   import made, or the error text and code; the import runs inside Codeunit.Run so a failed import does not end the test).
//   BC (27.5, 28.5, 29.0 alike): Export writes every container once, also when empty (<request />, <lines />, <status />). Import takes the
//   containers absent or once as their MinOccurs allows; a missing required container or a second one fails the schema check with
//   'Imported XML cannot validate with the schema: ...' / XmlPortInvalidXml before any row is made.
// BC versions: 27, 28, 29

table 87275 "LT QR XP Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 87276 "LT QR XP Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head No."; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; "Head No.", "Line No.") { Clustered = true; }
    }
}

table 87279 "LT QR XP Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 87277 "LT QR XP Containers"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(envelope)
        {
            MaxOccurs = Once;
            textelement(request)
            {
                MinOccurs = Once;
                MaxOccurs = Once;
                tableelement(head; "LT QR XP Head")
                {
                    UseTemporary = true;
                    MinOccurs = Zero;
                    MaxOccurs = Unbounded;
                    fieldattribute(no; head."No.") { }
                    fieldelement(name; head.Name)
                    {
                        MinOccurs = Zero;
                        MaxOccurs = Once;
                    }
                    textelement(lines)
                    {
                        MinOccurs = Zero;
                        MaxOccurs = Once;
                        tableelement(line; "LT QR XP Line")
                        {
                            UseTemporary = true;
                            MinOccurs = Zero;
                            MaxOccurs = Unbounded;
                            LinkTable = head;
                            LinkFields = "Head No." = field("No.");
                            fieldattribute(n; line."Line No.") { }
                            fieldelement(qty; line.Qty) { }
                        }
                    }
                }
            }
            textelement(status)
            {
                MinOccurs = Zero;
                MaxOccurs = Once;

                trigger OnBeforePassVariable()
                begin
                    status := StatusText;
                end;

                trigger OnAfterAssignVariable()
                begin
                    StatusText := status;
                end;
            }
        }
    }

    var
        StatusText: Text;

    procedure SetStatus(NewStatus: Text)
    begin
        StatusText := NewStatus;
    end;

    procedure GetStatus(): Text
    begin
        exit(StatusText);
    end;

    procedure AddHead(No: Code[10]; NewName: Text[30])
    begin
        head.Init();
        head."No." := No;
        head.Name := NewName;
        head.Insert();
    end;

    procedure AddLine(HeadNo: Code[10]; LineNo: Integer; NewQty: Integer)
    begin
        line.Init();
        line."Head No." := HeadNo;
        line."Line No." := LineNo;
        line.Qty := NewQty;
        line.Insert();
    end;

    procedure HeadRows() Result: Text
    begin
        head.Reset();
        if head.FindSet() then
            repeat
                Result += head."No." + ':' + head.Name + ';';
            until head.Next() = 0;
    end;

    procedure LineRows() Result: Text
    begin
        line.Reset();
        if line.FindSet() then
            repeat
                Result += line."Head No." + '/' + Format(line."Line No.") + '=' + Format(line.Qty) + ';';
            until line.Next() = 0;
    end;
}

codeunit 87278 "LT QR XP Runner"
{
    var
        Input: Text;
        HeadRows: Text;
        LineRows: Text;
        Status: Text;

    trigger OnRun()
    var
        Buffer: Record "LT QR XP Blob" temporary;
        Port: XmlPort "LT QR XP Containers";
        OutS: OutStream;
        InS: InStream;
    begin
        Buffer.Id := 1;
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Input);
        Buffer.Insert();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        Port.SetSource(InS);
        Port.Import();
        HeadRows := Port.HeadRows();
        LineRows := Port.LineRows();
        Status := Port.GetStatus();
    end;

    procedure SetInput(NewInput: Text)
    begin
        Input := NewInput;
        HeadRows := '';
        LineRows := '';
        Status := '';
    end;

    procedure Result(): Text
    begin
        exit('heads=' + HeadRows + ' lines=' + LineRows + ' status=' + Status);
    end;
}

codeunit 87280 "LT QR XP Container Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Exported(var Port: XmlPort "LT QR XP Containers"): Text
    var
        Buffer: Record "LT QR XP Blob" temporary;
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Xml: Text;
    begin
        Buffer.Id := 1;
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + '|';
        end;
        exit(Xml);
    end;

    local procedure Import(var Observer: Codeunit "Probe Observer"; Name: Text; Body: Text)
    var
        Runner: Codeunit "LT QR XP Runner";
    begin
        Runner.SetInput('<?xml version="1.0" encoding="UTF-8"?>' + Body);
        ClearLastError();
        if Runner.Run() then
            Observer.Observe(Name, 'ok ' + Runner.Result())
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure QR_Export_NoRows()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT QR XP Containers";
    begin
        Observer.Observe('xml', Exported(Port));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<envelope>|  <request />|  <status />|</envelope>|');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Export_NoRows_Status()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT QR XP Containers";
    begin
        Port.SetStatus('ok');
        Observer.Observe('xml', Exported(Port));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<envelope>|  <request />|  <status>ok</status>|</envelope>|');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Export_OneHead_NoLines()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT QR XP Containers";
    begin
        Port.AddHead('H1', 'one');
        Observer.Observe('xml', Exported(Port));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<envelope>|  <request>|    <head no="H1">|      <name>one</name>|      <lines />|    </head>|  </request>|  <status />|</envelope>|');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Export_OneHead_TwoLines()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT QR XP Containers";
    begin
        Port.AddHead('H1', 'one');
        Port.AddLine('H1', 10, 5);
        Port.AddLine('H1', 20, 7);
        Observer.Observe('xml', Exported(Port));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<envelope>|  <request>|    <head no="H1">|      <name>one</name>|      <lines>|        <line n="10">|          <qty>5</qty>|        </line>|        <line n="20">|          <qty>7</qty>|        </line>|      </lines>|    </head>|  </request>|  <status />|</envelope>|');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Export_TwoHeads_LinesOnSecond()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT QR XP Containers";
    begin
        Port.AddHead('H1', '');
        Port.AddHead('H2', 'two');
        Port.AddLine('H2', 10, 1);
        Port.AddLine('H9', 10, 9);
        Port.SetStatus('done');
        Observer.Observe('xml', Exported(Port));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<envelope>|  <request>|    <head no="H1">|      <name />|      <lines />|    </head>|    <head no="H2">|      <name>two</name>|      <lines>|        <line n="10">|          <qty>1</qty>|        </line>|      </lines>|    </head>|  </request>|  <status>done</status>|</envelope>|');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Import_Present()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'empty request', '<envelope><request/></envelope>');
        Import(Observer, 'empty request with status', '<envelope><request></request><status>s</status></envelope>');
        Import(Observer, 'one head no lines', '<envelope><request><head no="H1"><name>one</name></head></request></envelope>');
        Import(Observer, 'one head no name', '<envelope><request><head no="H1"/></request></envelope>');
        Import(Observer, 'one head empty lines', '<envelope><request><head no="H1"><lines/></head></request></envelope>');
        Import(Observer, 'two heads with lines', '<envelope><request><head no="H1"><name>one</name><lines><line n="10"><qty>5</qty></line><line n="20"><qty>7</qty></line></lines></head><head no="H2"><lines><line n="10"><qty>1</qty></line></lines></head></request></envelope>');
        Observer.Expect('empty request', 'ok heads= lines= status=');
        Observer.Expect('empty request with status', 'ok heads= lines= status=s');
        Observer.Expect('one head no lines', 'ok heads=H1:one; lines= status=');
        Observer.Expect('one head no name', 'ok heads=H1:; lines= status=');
        Observer.Expect('one head empty lines', 'ok heads=H1:; lines= status=');
        Observer.Expect('two heads with lines', 'ok heads=H1:one;H2:; lines=H1/10=5;H1/20=7;H2/10=1; status=');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Import_MissingOrTwoRequests()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'no request', '<envelope></envelope>');
        Import(Observer, 'no request but status', '<envelope><status>s</status></envelope>');
        Import(Observer, 'two requests', '<envelope><request/><request/></envelope>');
        Observer.Expect('no request|text', 'Imported XML cannot validate with the schema: The element ''envelope'' has incomplete content. List of possible elements expected: ''request''.');
        Observer.Expect('no request|code', 'XmlPortInvalidXml');
        Observer.Expect('no request but status|text', 'Imported XML cannot validate with the schema: The element ''envelope'' has invalid child element ''status''. List of possible elements expected: ''request''.');
        Observer.Expect('no request but status|code', 'XmlPortInvalidXml');
        Observer.Expect('two requests|text', 'Imported XML cannot validate with the schema: The element ''envelope'' has invalid child element ''request''. List of possible elements expected: ''status''.');
        Observer.Expect('two requests|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Import_Repeated()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'two lines containers', '<envelope><request><head no="H1"><lines/><lines/></head></request></envelope>');
        Import(Observer, 'two names', '<envelope><request><head no="H1"><name>a</name><name>b</name></head></request></envelope>');
        Import(Observer, 'two statuses', '<envelope><request/><status>a</status><status>b</status></envelope>');
        Observer.Expect('two lines containers|text', 'Imported XML cannot validate with the schema: The element ''head'' has invalid child element ''lines''.');
        Observer.Expect('two lines containers|code', 'XmlPortInvalidXml');
        Observer.Expect('two names|text', 'Imported XML cannot validate with the schema: The element ''head'' has invalid child element ''name''. List of possible elements expected: ''lines''.');
        Observer.Expect('two names|code', 'XmlPortInvalidXml');
        Observer.Expect('two statuses|text', 'Imported XML cannot validate with the schema: The element ''envelope'' has invalid child element ''status''.');
        Observer.Expect('two statuses|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Import_WrongRootOrOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'other root', '<other><request/></other>');
        Import(Observer, 'status before request', '<envelope><status>s</status><request/></envelope>');
        Import(Observer, 'lines before name', '<envelope><request><head no="H1"><lines/><name>a</name></head></request></envelope>');
        Observer.Expect('other root|text', 'Imported XML cannot validate with the schema: The ''other'' element is not declared.');
        Observer.Expect('other root|code', 'XmlPortInvalidXml');
        Observer.Expect('status before request|text', 'Imported XML cannot validate with the schema: The element ''envelope'' has invalid child element ''status''. List of possible elements expected: ''request''.');
        Observer.Expect('status before request|code', 'XmlPortInvalidXml');
        Observer.Expect('lines before name|text', 'Imported XML cannot validate with the schema: The element ''head'' has invalid child element ''name''.');
        Observer.Expect('lines before name|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Import_UnknownChild()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'unknown child', '<envelope><request><extra/></request></envelope>');
        Observer.Expect('unknown child|text', 'Imported XML cannot validate with the schema: The element ''request'' has invalid child element ''extra''. List of possible elements expected: ''head''.');
        Observer.Expect('unknown child|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;
}
