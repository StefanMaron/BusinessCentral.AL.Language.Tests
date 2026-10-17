// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own tables 74956 and 74957, log 74958, xmlports 74959 and 74960, test codeunit 74961
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the order in which an XmlPort runs its triggers on Export and on Import with a parent and a nested child table element and a text element: OnPreXmlPort, OnPreXmlItem, OnAfterGetRecord, the element triggers, OnPostXmlPort, and the counts the data items answer when read inside OnPreXmlPort, OnAfterGetRecord and OnPostXmlPort. Import inserts new rows and modifies existing ones (AutoSave, AutoReplace).
// BC versions: 29 (27 and 28 by CI)

table 74956 "LT XT Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 74957 "LT XT Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Note; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74958 "LT XT Log"
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

xmlport 74959 "LT XT Export"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Hdr)
            {
                trigger OnBeforePassVariable()
                begin
                    L.Add('Hdr.BeforePassVariable');
                    Hdr := 'h';
                end;
            }
            tableelement(Par; "LT XT Parent")
            {
                XmlName = 'Par';

                fieldelement(Id; Par.Id)
                {
                    trigger OnBeforePassField()
                    begin
                        L.Add('Par.Id.BeforePassField=' + Format(Par.Id));
                    end;
                }
                fieldelement(Name; Par.Name) { }
                tableelement(Chi; "LT XT Child")
                {
                    XmlName = 'Chi';
                    LinkFields = ParentId = field(Id);
                    LinkTable = Par;
                    MinOccurs = Zero;

                    fieldelement(CId; Chi.Id)
                    {
                        trigger OnBeforePassField()
                        begin
                            L.Add('Chi.Id.BeforePassField=' + Format(Chi.Id));
                        end;
                    }
                    fieldelement(Note; Chi.Note) { }

                    trigger OnPreXmlItem()
                    begin
                        L.Add('Chi.PreXmlItem count=' + Format(Chi.Count()));
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        L.Add('Chi.AfterGetRecord=' + Format(Chi.Id));
                    end;

                }

                trigger OnPreXmlItem()
                begin
                    L.Add('Par.PreXmlItem count=' + Format(Par.Count()));
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('Par.AfterGetRecord=' + Format(Par.Id));
                end;

            }
        }
    }

    trigger OnPreXmlPort()
    begin
        L.Add('PreXmlPort par=' + Format(Par.Count()) + ' chi=' + Format(Chi.Count()));
    end;

    trigger OnPostXmlPort()
    begin
        L.Add('PostXmlPort par=' + Format(Par.Count()) + ' chi=' + Format(Chi.Count()));
    end;

    var
        L: Codeunit "LT XT Log";
}

xmlport 74960 "LT XT Import"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Hdr)
            {
                trigger OnAfterAssignVariable()
                begin
                    L.Add('Hdr.AfterAssignVariable=' + Hdr);
                end;
            }
            tableelement(Par; "LT XT Parent")
            {
                XmlName = 'Par';
                AutoSave = true;
                AutoReplace = true;

                fieldelement(Id; Par.Id)
                {
                    trigger OnAfterAssignField()
                    begin
                        L.Add('Par.Id.AfterAssignField=' + Format(Par.Id));
                    end;
                }
                fieldelement(Name; Par.Name) { }
                tableelement(Chi; "LT XT Child")
                {
                    XmlName = 'Chi';
                    LinkFields = ParentId = field(Id);
                    LinkTable = Par;
                    MinOccurs = Zero;
                    AutoSave = true;
                    AutoReplace = true;

                    fieldelement(CId; Chi.Id)
                    {
                        trigger OnAfterAssignField()
                        begin
                            L.Add('Chi.Id.AfterAssignField=' + Format(Chi.Id));
                        end;
                    }
                    fieldelement(Note; Chi.Note) { }

                    trigger OnPreXmlItem()
                    begin
                        L.Add('Chi.PreXmlItem');
                    end;

                    trigger OnAfterInitRecord()
                    begin
                        L.Add('Chi.AfterInitRecord');
                    end;

                    trigger OnBeforeInsertRecord()
                    begin
                        L.Add('Chi.BeforeInsertRecord=' + Format(Chi.Id) + '/' + Format(Chi.ParentId));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        L.Add('Chi.AfterInsertRecord=' + Format(Chi.Id));
                    end;

                    trigger OnBeforeModifyRecord()
                    begin
                        L.Add('Chi.BeforeModifyRecord=' + Format(Chi.Id));
                    end;

                    trigger OnAfterModifyRecord()
                    begin
                        L.Add('Chi.AfterModifyRecord=' + Format(Chi.Id));
                    end;

                }

                trigger OnPreXmlItem()
                begin
                    L.Add('Par.PreXmlItem');
                end;

                trigger OnAfterInitRecord()
                begin
                    L.Add('Par.AfterInitRecord');
                end;

                trigger OnBeforeInsertRecord()
                begin
                    L.Add('Par.BeforeInsertRecord=' + Format(Par.Id) + '/' + Par.Name);
                end;

                trigger OnAfterInsertRecord()
                begin
                    L.Add('Par.AfterInsertRecord=' + Format(Par.Id));
                end;

                trigger OnBeforeModifyRecord()
                begin
                    L.Add('Par.BeforeModifyRecord=' + Format(Par.Id) + '/' + Par.Name);
                end;

                trigger OnAfterModifyRecord()
                begin
                    L.Add('Par.AfterModifyRecord=' + Format(Par.Id));
                end;

            }
        }
    }

    trigger OnPreXmlPort()
    begin
        L.Add('PreXmlPort par=' + Format(Par.Count()) + ' chi=' + Format(Chi.Count()));
    end;

    trigger OnPostXmlPort()
    begin
        L.Add('PostXmlPort par=' + Format(Par.Count()) + ' chi=' + Format(Chi.Count()));
    end;

    var
        L: Codeunit "LT XT Log";
}

codeunit 74961 "LT XmlPort Trigger Flow"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Par: Record "LT XT Parent";
        Chi: Record "LT XT Child";
    begin
        Par.DeleteAll();
        Chi.DeleteAll();
        Par.Id := 1; Par.Name := 'one'; Par.Insert();
        Par.Id := 2; Par.Name := 'two'; Par.Insert();
        Chi.Id := 10; Chi.ParentId := 1; Chi.Note := 'c10'; Chi.Insert();
        Chi.Id := 11; Chi.ParentId := 1; Chi.Note := 'c11'; Chi.Insert();
        Chi.Id := 20; Chi.ParentId := 2; Chi.Note := 'c20'; Chi.Insert();
    end;

    local procedure ExportText(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Txt: Text;
        Line: Text;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xmlport.Export(Xmlport::"LT XT Export", OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Txt += Line;
        end;
        exit(Txt);
    end;

    local procedure ImportText(Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Xml);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(Xmlport::"LT XT Import", InS);
    end;

    [Test]
    procedure Export_TriggerOrder_ParentWithNestedChild()
    var
        Log: Codeunit "LT XT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Take();
        Observer.Observe('xml', ExportText());
        Observer.Observe('trace', Log.Take());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?><Root>  <Hdr>h</Hdr>  <Par>    <Id>1</Id>    <Name>one</Name>    <Chi>      <CId>10</CId>      <Note>c10</Note>    </Chi>    <Chi>      <CId>11</CId>      <Note>c11</Note>    </Chi>  </Par>  <Par>    <Id>2</Id>    <Name>two</Name>    <Chi>      <CId>20</CId>      <Note>c20</Note>    </Chi>  </Par></Root>');
        Observer.Expect('trace', 'PreXmlPort par=2 chi=3;Hdr.BeforePassVariable;Par.PreXmlItem count=2;Par.AfterGetRecord=1;Par.Id.BeforePassField=1;Chi.PreXmlItem count=2;Chi.AfterGetRecord=10;Chi.Id.BeforePassField=10;Chi.AfterGetRecord=11;Chi.Id.BeforePassField=11;Par.AfterGetRecord=2;Par.Id.BeforePassField=2;Chi.PreXmlItem count=1;Chi.AfterGetRecord=20;Chi.Id.BeforePassField=20;PostXmlPort par=2 chi=1;');
        Observer.Verify();
    end;

    [Test]
    procedure Export_TriggerOrder_EmptyTables()
    var
        Par: Record "LT XT Parent";
        Chi: Record "LT XT Child";
        Log: Codeunit "LT XT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Par.DeleteAll();
        Chi.DeleteAll();
        Log.Take();
        Observer.Observe('xml', ExportText());
        Observer.Observe('trace', Log.Take());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?><Root>  <Hdr>h</Hdr>  <Par>    <Id>0</Id>    <Name />  </Par></Root>');
        Observer.Expect('trace', 'PreXmlPort par=0 chi=0;Hdr.BeforePassVariable;Par.PreXmlItem count=0;Par.Id.BeforePassField=0;Chi.PreXmlItem count=0;PostXmlPort par=0 chi=0;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_TriggerOrder_NewRows()
    var
        Par: Record "LT XT Parent";
        Chi: Record "LT XT Child";
        Log: Codeunit "LT XT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Par.DeleteAll();
        Chi.DeleteAll();
        Log.Take();
        ImportText('<Root><Hdr>h</Hdr><Par><Id>1</Id><Name>one</Name><Chi><CId>10</CId><Note>c10</Note></Chi><Chi><CId>11</CId><Note>c11</Note></Chi></Par><Par><Id>2</Id><Name>two</Name></Par></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('par_after', Format(Par.Count()));
        Observer.Observe('chi_after', Format(Chi.Count()));
        Observer.Expect('trace', 'PreXmlPort par=0 chi=0;Hdr.AfterAssignVariable=h;Par.AfterInitRecord;Par.Id.AfterAssignField=1;Par.BeforeInsertRecord=1/one;Par.AfterInsertRecord=1;Chi.AfterInitRecord;Chi.Id.AfterAssignField=10;Chi.BeforeInsertRecord=10/1;Chi.AfterInsertRecord=10;Chi.AfterInitRecord;Chi.Id.AfterAssignField=11;Chi.BeforeInsertRecord=11/0;Chi.AfterInsertRecord=11;Par.BeforeModifyRecord=1/one;Par.AfterModifyRecord=1;Par.AfterInitRecord;Par.Id.AfterAssignField=2;Par.BeforeInsertRecord=2/two;Par.AfterInsertRecord=2;PostXmlPort par=2 chi=2;');
        Observer.Expect('par_after', '2');
        Observer.Expect('chi_after', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Import_TriggerOrder_ExistingRows()
    var
        Par: Record "LT XT Parent";
        Chi: Record "LT XT Child";
        Log: Codeunit "LT XT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Take();
        ImportText('<Root><Hdr>h</Hdr><Par><Id>1</Id><Name>changed</Name><Chi><CId>10</CId><Note>n10</Note></Chi></Par></Root>');
        Observer.Observe('trace', Log.Take());
        Par.Get(1);
        Observer.Observe('par1_name', Par.Name);
        Chi.Get(10);
        Observer.Observe('chi10_note', Chi.Note);
        Observer.Observe('par_after', Format(Par.Count()));
        Observer.Observe('chi_after', Format(Chi.Count()));
        Observer.Expect('trace', 'PreXmlPort par=2 chi=3;Hdr.AfterAssignVariable=h;Par.AfterInitRecord;Par.Id.AfterAssignField=1;Par.BeforeModifyRecord=1/changed;Par.AfterModifyRecord=1;Chi.AfterInitRecord;Chi.Id.AfterAssignField=10;Chi.BeforeModifyRecord=10;Chi.AfterModifyRecord=10;Par.BeforeModifyRecord=1/changed;Par.AfterModifyRecord=1;PostXmlPort par=2 chi=3;');
        Observer.Expect('par1_name', 'changed');
        Observer.Expect('chi10_note', 'n10');
        Observer.Expect('par_after', '2');
        Observer.Expect('chi_after', '3');
        Observer.Verify();
    end;
}
