// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Y XP State (75568); own tables 75550-75551, xmlports 75552-75567, codeunits 75513 (import runner) and 75514 (tests)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced.
// Facts: XmlPort properties FileName, InlineSchema, UseLax, XmlVersionNo, InherentEntitlements, InherentPermissions; field/text node properties XmlName, NamespacePrefix, Unbound, AutoCalcField, Width;
// table element properties RequestFilterHeading(ML), Unbound, Width. Width out of Integer range, an invalid XmlName and RequestFilterHeading with RequestFilterHeadingML are must-not-compile cases 0814-0825.
// BC versions: 27-29

table 75550 "LT Y Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; Total; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT Y Item Line" where(ItemId = field(Id)));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 75551 "LT Y Item Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ItemId; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 75552 "LT Y XP Inline"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    InlineSchema = true;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75553 "LT Y XP Lax"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    UseLax = true;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75554 "LT Y XP Strict"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75555 "LT Y XP V10"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    XmlVersionNo = V10;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75556 "LT Y XP V11"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    XmlVersionNo = V11;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75557 "LT Y XP FileName"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    FileName = 'lt-y-export.xml';
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75558 "LT Y XP FileName Empty"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    FileName = '';
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75559 "LT Y XP Permissions"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    InherentEntitlements = X;
    InherentPermissions = X;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75560 "LT Y XP Attr"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    Namespaces = p = 'urn:lt-y';

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; Rw.Id)
                {
                    XmlName = 'Ident';
                    NamespacePrefix = 'p';
                }
                fieldattribute(Total; Rw.Total)
                {
                    AutoCalcField = true;
                }
                textattribute(Note)
                {
                    NamespacePrefix = 'p';
                    Width = 10;
                }
                fieldelement(Name; Rw.Name)
                {
                    XmlName = 'Label';
                    NamespacePrefix = 'p';
                    Width = 20;
                }
                fieldelement(Count; Rw.Total)
                {
                    XmlName = 'Lines';
                    AutoCalcField = true;
                }
            }
        }
    }
}

xmlport 75561 "LT Y XP NoCalc"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldattribute(Total; Rw.Total)
                {
                    AutoCalcField = false;
                }
                fieldelement(Count; Rw.Total)
                {
                    AutoCalcField = false;
                }
            }
        }
    }
}

xmlport 75562 "LT Y XP Unbound Attr"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; Rw.Id) { }
                fieldattribute(Free; Rw.Name)
                {
                    Unbound = true;
                }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75566 "LT Y XP Unbound Text"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; Rw.Id) { }
                textattribute(Tag)
                {
                    Unbound = true;
                }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75567 "LT Y XP Unbound Elem"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; Rw.Id) { }
                fieldelement(Extra; Rw.Qty)
                {
                    Unbound = true;
                }
            }
        }
    }
}

xmlport 75563 "LT Y XP Table Unbound"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                Unbound = true;
                Width = 12;
                fieldelement(Id; Rw.Id) { }
            }
            textelement(Plain)
            {
                Width = 6;
            }
        }
    }
}

xmlport 75564 "LT Y XP Heading"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                RequestFilterFields = Id;
                RequestFilterHeading = 'Item rows';
                fieldelement(Id; Rw.Id) { }
            }
        }
    }
}

xmlport 75565 "LT Y XP Heading ML"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                RequestFilterFields = Id;
                RequestFilterHeadingML = ENU = 'English rows', DEU = 'Deutsche Zeilen';
                fieldelement(Id; Rw.Id) { }
            }
        }
    }
}

codeunit 75568 "LT Y XP State"
{
    SingleInstance = true;

    var
        Entries: Dictionary of [Text, Text];

    procedure Put(Name: Text; Value: Text)
    begin
        if Entries.ContainsKey(Name) then
            Entries.Set(Name, Value)
        else
            Entries.Add(Name, Value);
    end;

    procedure Get(Name: Text): Text
    begin
        if Entries.ContainsKey(Name) then
            exit(Entries.Get(Name));
        exit('<none>');
    end;
}

codeunit 75513 "LT Y XP Import Runner"
{
    trigger OnRun()
    var
        Seen: Codeunit "LT Y XP State";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        if Seen.Get('import_text').Contains('encoding="UTF-16"') then
            TempBlob.CreateOutStream(OutS, TextEncoding::UTF16)
        else
            TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Seen.Get('import_text'));
        if Seen.Get('import_text').Contains('encoding="UTF-16"') then
            TempBlob.CreateInStream(InS, TextEncoding::UTF16)
        else
            TempBlob.CreateInStream(InS);
        Xmlport.Import(GetId(Seen.Get('import_id')), InS);
    end;

    local procedure GetId(Text: Text): Integer
    var
        Id: Integer;
    begin
        Evaluate(Id, Text);
        exit(Id);
    end;
}

codeunit 75514 "LT Y XmlPort Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seen: Codeunit "LT Y XP State";

    local procedure Seed()
    var
        Item: Record "LT Y Item";
        Line: Record "LT Y Item Line";
    begin
        Item.DeleteAll();
        Line.DeleteAll();
        Item.Init();
        Item.Id := 1;
        Item.Name := 'one';
        Item.Qty := 5;
        Item.Insert();
        Item.Init();
        Item.Id := 2;
        Item.Name := 'two';
        Item.Qty := 6;
        Item.Insert();
        Line.Id := 1;
        Line.ItemId := 1;
        Line.Insert();
        Line.Id := 2;
        Line.ItemId := 1;
        Line.Insert();
        Line.Id := 3;
        Line.ItemId := 2;
        Line.Insert();
        Commit();
    end;

    local procedure Rows(): Text
    var
        Item: Record "LT Y Item";
        Result: Text;
    begin
        if Item.FindSet() then
            repeat
                Result += Format(Item.Id) + '/' + Item.Name + '/' + Format(Item.Qty) + ';';
            until Item.Next() = 0;
        exit(Result);
    end;

    local procedure ExportText(XmlPortId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(XmlPortId, OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryExport(XmlPortId: Integer; var Result: Text)
    begin
        Result := ExportText(XmlPortId);
    end;

    local procedure Export(var Observer: Codeunit "Probe Observer"; Name: Text; XmlPortId: Integer)
    var
        Result: Text;
    begin
        if TryExport(XmlPortId, Result) then
            Observer.Observe(Name, Result)
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ImportText(XmlPortId: Integer; Xml: Text): Text
    begin
        Seen.Put('import_text', Xml);
        Seen.Put('import_id', Format(XmlPortId));
        Commit();
        if Codeunit.Run(Codeunit::"LT Y XP Import Runner") then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure InlineSchema_Export_ContainsSchema()
    var
        Observer: Codeunit "Probe Observer";
        Text1: Text;
    begin
        Seed();
        Text1 := ExportText(75552);
        Observer.Observe('export', Text1);
        Observer.Observe('plain', ExportText(75554));
        Observer.Observe('import_back', ImportText(75552, Text1));
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure UseLax_Import_AcceptsUnknownElements()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('lax', ImportText(75553, '<Root><Item><Id>7</Id><Name>seven</Name><Unknown>x</Unknown></Item><Other/></Root>'));
        Observer.Observe('rows_lax', Rows());
        Observer.Observe('lax_other_namespace', ImportText(75553, '<Root><Item><Id>6</Id><Name>six</Name><Unknown xmlns="urn:other">x</Unknown></Item></Root>'));
        Observer.Observe('rows_lax_ns', Rows());
        Observer.Observe('strict_other_namespace', ImportText(75554, '<Root><Item><Id>5</Id><Name>five</Name><Unknown xmlns="urn:other">x</Unknown></Item></Root>'));
        Observer.Observe('strict', ImportText(75554, '<Root><Item><Id>8</Id><Name>eight</Name><Unknown>x</Unknown></Item></Root>'));
        Observer.Observe('strict_root', ImportText(75554, '<Root><Item><Id>9</Id><Name>nine</Name></Item><Other/></Root>'));
        Observer.Observe('rows_strict', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure XmlVersionNo_Export_Declaration()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'v10', 75555);
        Export(Observer, 'v11', 75556);
        Export(Observer, 'default', 75554);
        Observer.Observe('import_v11', ImportText(75556, '<?xml version="1.1" encoding="utf-8"?><Root><Item><Id>7</Id><Name>seven</Name></Item></Root>'));
        Observer.Observe('import_v10', ImportText(75555, '<?xml version="1.0" encoding="utf-8"?><Root><Item><Id>8</Id><Name>eight</Name></Item></Root>'));
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure FileName_Export_Output()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'named', 75557);
        Export(Observer, 'empty', 75558);
        Observer.Finish();
    end;

    [Test]
    procedure InherentPermissions_Export_WithoutExplicitPermission()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', 75559);
        Observer.Finish();
    end;

    [Test]
    procedure NodeProperties_Export_NamesPrefixesAutoCalc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'attr', 75560);
        Export(Observer, 'nocalc', 75561);
        Observer.Finish();
    end;

    [Test]
    procedure NodeProperties_Import_NamesPrefixes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('import', ImportText(75560, '<Root xmlns:p="urn:lt-y"><Item Ident="11" Total="0" Note="n"><p:Label>eleven</p:Label><Lines>0</Lines></Item></Root>'));
        Observer.Observe('rows', Rows());
        Observer.Observe('import_no_prefix', ImportText(75560, '<Root><Item Ident="12" Total="0" Note=""><Label>twelve</Label><Lines>0</Lines></Item></Root>'));
        Observer.Observe('rows2', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Unbound_FieldAttribute_ExportAndImport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', 75562);
        Observer.Observe('import', ImportText(75562, '<Root><Item Id="21" Free="f"><Name>twentyone</Name></Item></Root>'));
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Unbound_TextAttribute_ExportAndImport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', 75566);
        Observer.Observe('import', ImportText(75566, '<Root><Item Id="22" Tag="t"><Name>twentytwo</Name></Item></Root>'));
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Unbound_FieldElement_ExportAndImport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        // Exporting this xmlport does not end (the export grows until the blob capacity is exceeded), so only the import is observed.
        Observer.Observe('import', ImportText(75567, '<Root><Item Id="23"><Extra>99</Extra></Item></Root>'));
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure RequestFilterHeading_XmlPort_Metadata()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y Helper";
    begin
        Observer.Observe('plain', Helper.Facts(2000000280, 1, 75564, 'UseRequestPage,Direction,Format,InherentPermissions,InherentEntitlements'));
        Observer.Observe('ml', Helper.Facts(2000000280, 1, 75565, 'UseRequestPage,Direction,Format,InherentPermissions,InherentEntitlements'));
        Observer.Observe('inline', Helper.Facts(2000000280, 1, 75552, 'UseRequestPage,Direction,Format,InherentPermissions,InherentEntitlements'));
        Observer.Observe('v11', Helper.Facts(2000000280, 1, 75556, 'UseRequestPage,Direction,Format,InherentPermissions,InherentEntitlements'));
        Observer.Observe('perm', Helper.Facts(2000000280, 1, 75559, 'UseRequestPage,Direction,Format,InherentPermissions,InherentEntitlements'));
        Observer.Finish();
    end;
}
