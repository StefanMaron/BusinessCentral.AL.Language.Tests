// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Parent (60004), ALT Child (60005), ALTFixtureCleanup (60019),
//                shared Assert (60021); self-contained xmlports 68200..68204, log codeunit 68206, tests 68205
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the import trigger order, that every XML element starts from an empty record, AutoReplace and
// AutoUpdate (SystemId kept, what happens to the fields the document does not carry), the duplicate
// key error of a plain import, the rows and order of an export with SetTableView (also with another key
// and a descending order), the VariableText export bytes, and nested table elements (export, and the
// link field of the second imported child).
// BC versions: 27.5

codeunit 68206 "Probe XmlPort Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

xmlport 68200 "Probe XP Trig"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(U; "ALT Universal")
            {
                fieldattribute(Attr; U."Name Field") { }
                fieldelement(EntryNo; U."Entry No.") { }
                fieldelement(Txt; U."Text Field")
                {
                    MinOccurs = Zero;

                    trigger OnAfterAssignField()
                    begin
                        XmlLog.Add('Txt.AfterAssign(' + U."Text Field" + ')');
                    end;

                    trigger OnBeforePassField()
                    begin
                        XmlLog.Add('Txt.BeforePass');
                    end;
                }
                fieldelement(Intg; U."Integer Field")
                {
                    MinOccurs = Zero;

                    trigger OnAfterAssignField()
                    begin
                        XmlLog.Add('Int.AfterAssign');
                    end;
                }

                trigger OnAfterInitRecord()
                begin
                    XmlLog.Add('AfterInitRecord(entry=' + Format(U."Entry No.") + ',txt=' + U."Text Field" + ')');
                end;

                trigger OnBeforeInsertRecord()
                begin
                    XmlLog.Add('BeforeInsert(' + Format(U."Entry No.") + ')');
                end;

                trigger OnAfterInsertRecord()
                begin
                    XmlLog.Add('AfterInsert');
                end;
            }
        }
    }

    var
        XmlLog: Codeunit "Probe XmlPort Log";
}

xmlport 68201 "Probe XP Replace"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(U; "ALT Universal")
            {
                AutoReplace = true;

                fieldelement(EntryNo; U."Entry No.") { }
                fieldelement(Txt; U."Text Field") { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 68202 "Probe XP Update"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(U; "ALT Universal")
            {
                AutoUpdate = true;

                fieldelement(EntryNo; U."Entry No.") { }
                fieldelement(Txt; U."Text Field") { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 68203 "Probe XP Variable Text"
{
    Direction = Export;
    Format = VariableText;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(U; "ALT Universal")
            {
                fieldelement(EntryNo; U."Entry No.") { }
                fieldelement(Txt; U."Text Field") { }
                fieldelement(Dec; U."Decimal Field") { }
            }
        }
    }
}

xmlport 68204 "Probe XP Nested"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "ALT Parent")
            {
                fieldelement(PNo; P."Entry No.") { }
                tableelement(C; "ALT Child")
                {
                    LinkFields = "Parent Entry No." = field("Entry No.");
                    LinkTable = P;

                    fieldelement(CNo; C."Entry No.") { }
                    fieldelement(CCode; C.Code) { }
                }
            }
        }
    }
}

codeunit 68205 "Probe XmlPort More"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        XmlLog: Codeunit "Probe XmlPort Log";

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        Commit();
        XmlLog.Take();
    end;

    local procedure Feed(Xml: Text; var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Xml);
    end;

    local procedure EntryNumbersOf(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InStr, TextEncoding::UTF16);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            if Line.Contains('EntryNo') then
                Result += Line.Trim() + ' ';
        end;
        exit(Result);
    end;

    [Test]
    procedure Import_TriggerOrder_AndEveryElementStartsFromAnEmptyRecord()
    var
        TempBlob: Codeunit "Temp Blob";
        Import: XmlPort "Probe XP Trig";
        InStr: InStream;
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();
        Feed('<Root><U Attr="a"><EntryNo>1</EntryNo><Txt>t1</Txt><Intg>5</Intg></U><U Attr="b"><EntryNo>2</EntryNo></U></Root>', TempBlob);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        Import.SetSource(InStr);

        Import.Import();

        Assert.AreEqual('AfterInitRecord(entry=0,txt=);Txt.AfterAssign(t1);Int.AfterAssign;BeforeInsert(1);AfterInsert;AfterInitRecord(entry=0,txt=);BeforeInsert(2);AfterInsert;', XmlLog.Take(),
            'init, the fields in document order, then insert; the second element starts empty');
        Commit();
        ALTUniversal.Get(2);
        Assert.AreEqual('', ALTUniversal."Text Field", 'a field the element does not carry stays empty');
        Assert.AreEqual('b', ALTUniversal."Name Field", 'the attribute');
    end;

    [Test]
    procedure Import_ExistingKey_WithoutAutoReplace_RaisesTheDuplicateKeyError()
    var
        TempBlob: Codeunit "Temp Blob";
        Import: XmlPort "Probe XP Trig";
        InStr: InStream;
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal.Insert();
        Commit();
        Feed('<Root><U Attr="c"><EntryNo>1</EntryNo><Txt>t1b</Txt></U></Root>', TempBlob);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        Import.SetSource(InStr);

        asserterror Import.Import();

        Assert.AreEqual('The record in table ALT Universal already exists. Identification fields and values: Entry No.=''1''', GetLastErrorText(), 'text');
        Assert.AreEqual('DB:RecordExists', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure Import_AutoReplace_ReplacesTheWholeBuffer_KeepsSystemId()
    var
        TempBlob: Codeunit "Temp Blob";
        Import: XmlPort "Probe XP Replace";
        InStr: InStream;
        ALTUniversal: Record "ALT Universal";
        OldSystemId: Guid;
    begin
        Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal."Text Field" := 'orig';
        ALTUniversal."Integer Field" := 42;
        ALTUniversal."Name Field" := 'nm';
        ALTUniversal.Insert();
        Commit();
        ALTUniversal.Get(1);
        OldSystemId := ALTUniversal.SystemId;
        Feed('<Root><U><EntryNo>1</EntryNo><Txt>replaced</Txt></U></Root>', TempBlob);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        Import.SetSource(InStr);

        Import.Import();
        Commit();

        ALTUniversal.Get(1);
        Assert.AreEqual('replaced', ALTUniversal."Text Field", 'carried field');
        Assert.AreEqual(0, ALTUniversal."Integer Field", 'a field the document does not carry is reset');
        Assert.AreEqual('', ALTUniversal."Name Field", 'also the other one');
        Assert.AreEqual(OldSystemId, ALTUniversal.SystemId, 'the row keeps its SystemId');
    end;

    [Test]
    procedure Import_AutoUpdate_ChangesOnlyTheCarriedFields_KeepsSystemId()
    var
        TempBlob: Codeunit "Temp Blob";
        Import: XmlPort "Probe XP Update";
        InStr: InStream;
        ALTUniversal: Record "ALT Universal";
        OldSystemId: Guid;
    begin
        Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal."Text Field" := 'orig';
        ALTUniversal."Integer Field" := 42;
        ALTUniversal."Name Field" := 'nm';
        ALTUniversal.Insert();
        Commit();
        ALTUniversal.Get(1);
        OldSystemId := ALTUniversal.SystemId;
        Feed('<Root><U><EntryNo>1</EntryNo><Txt>updated</Txt></U></Root>', TempBlob);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        Import.SetSource(InStr);

        Import.Import();
        Commit();

        ALTUniversal.Get(1);
        Assert.AreEqual('updated', ALTUniversal."Text Field", 'carried field');
        Assert.AreEqual(42, ALTUniversal."Integer Field", 'not carried: kept');
        Assert.AreEqual('nm', ALTUniversal."Name Field", 'not carried: kept');
        Assert.AreEqual(OldSystemId, ALTUniversal.SystemId, 'SystemId');
    end;

    [Test]
    procedure Export_OnBeforePassField_Runs_AndSetTableViewFiltersAndOrders()
    var
        TempBlob: Codeunit "Temp Blob";
        Export: XmlPort "Probe XP Trig";
        OutStr: OutStream;
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 30;
        ALTUniversal.Insert();
        ALTUniversal."Entry No." := 10;
        ALTUniversal.Insert();
        ALTUniversal."Entry No." := 20;
        ALTUniversal."Text Field" := 'k';
        ALTUniversal.Insert();
        Commit();

        TempBlob.CreateOutStream(OutStr);
        Export.SetDestination(OutStr);
        ALTUniversal.SetFilter("Entry No.", '>=20');
        Export.SetTableView(ALTUniversal);
        Export.Export();
        Assert.AreEqual('<EntryNo>20</EntryNo> <EntryNo>30</EntryNo> ', EntryNumbersOf(TempBlob), 'filtered, in primary key order');
        Assert.AreEqual('Txt.BeforePass;Txt.BeforePass;', XmlLog.Take(), 'OnBeforePassField runs for each row');

        Clear(Export);
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        Export.SetDestination(OutStr);
        Clear(ALTUniversal);
        ALTUniversal.SetCurrentKey("Text Field");
        ALTUniversal.Ascending(false);
        Export.SetTableView(ALTUniversal);
        Export.Export();
        Assert.AreEqual('<EntryNo>20</EntryNo> <EntryNo>30</EntryNo> <EntryNo>10</EntryNo> ', EntryNumbersOf(TempBlob), 'the key and the descending order of the view are used, ties follow the direction too');
    end;

    [Test]
    procedure Export_VariableText_Bytes()
    // CLAIM: every value in double quotes, commas between, CR LF between rows and none after the last, no escaping of a quote inside a value, Decimal with the locale text.
    var
        TempBlob: Codeunit "Temp Blob";
        Export: XmlPort "Probe XP Variable Text";
        OutStr: OutStream;
        InStr: InStream;
        ALTUniversal: Record "ALT Universal";
        Content: Text;
        Line: Text;
    begin
        Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal."Text Field" := 'a,b';
        ALTUniversal."Decimal Field" := 1234.5;
        ALTUniversal.Insert();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 2;
        ALTUniversal."Text Field" := 'q"x';
        ALTUniversal.Insert();
        Commit();

        TempBlob.CreateOutStream(OutStr);
        Export.SetDestination(OutStr);
        Export.Export();

        TempBlob.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Content += Line + '|';
        end;
        Assert.AreEqual('"1","a,b","1,234.50"|"2","q"x","0.00"|', Content, 'lines (ReadText drops the CR of a CR LF)');
    end;

    [Test]
    procedure Nested_Export_GroupsTheChildrenUnderTheirParent_ImportLinksOnlyTheFirstChild()
    // CLAIM: on import the link field of the first child is the parent's; the second child of the same parent is stored with 0.
    var
        TempBlob: Codeunit "Temp Blob";
        Nested: XmlPort "Probe XP Nested";
        OutStr: OutStream;
        InStr: InStream;
        ALTParent: Record "ALT Parent";
        ALTChild: Record "ALT Child";
        Line: Text;
        Content: Text;
        Children: Text;
    begin
        Initialize();
        ALTParent.Init();
        ALTParent."Entry No." := 1;
        ALTParent.Insert();
        ALTParent."Entry No." := 2;
        ALTParent.Insert();
        ALTChild.Init();
        ALTChild."Entry No." := 1;
        ALTChild."Parent Entry No." := 1;
        ALTChild.Code := 'a';
        ALTChild.Insert();
        ALTChild."Entry No." := 2;
        ALTChild."Parent Entry No." := 2;
        ALTChild.Code := 'b';
        ALTChild.Insert();
        ALTChild."Entry No." := 3;
        ALTChild."Parent Entry No." := 1;
        ALTChild.Code := 'c';
        ALTChild.Insert();
        Commit();

        TempBlob.CreateOutStream(OutStr);
        Nested.SetDestination(OutStr);
        Nested.Export();
        TempBlob.CreateInStream(InStr, TextEncoding::UTF16);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Content += Line.Trim();
        end;
        Assert.AreEqual('<?xml version="1.0" encoding="UTF-16" standalone="no"?><Root><P><PNo>1</PNo><C><CNo>1</CNo><CCode>A</CCode></C><C><CNo>3</CNo><CCode>C</CCode></C></P><P><PNo>2</PNo><C><CNo>2</CNo><CCode>B</CCode></C></P></Root>', Content, 'export');

        Initialize();
        Feed('<Root><P><PNo>5</PNo><C><CNo>50</CNo><CCode>x</CCode></C><C><CNo>51</CNo><CCode>y</CCode></C></P></Root>', TempBlob);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        Clear(Nested);
        Nested.SetSource(InStr);
        Nested.Import();
        Commit();

        ALTChild.Reset();
        ALTChild.FindSet();
        repeat
            Children += Format(ALTChild."Entry No.") + '/parent=' + Format(ALTChild."Parent Entry No.") + '/' + ALTChild.Code + ' ';
        until ALTChild.Next() = 0;
        Assert.AreEqual('50/parent=5/X 51/parent=0/Y ', Children, 'children');
    end;
}
