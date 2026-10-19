// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); from xmlport/lt-y-xmlport-props/YXmlPortProps.al: table LT Y Item (75550), xmlports LT Y XP Lax (75553),
//   LT Y XP Strict (75554), LT Y XP V10 (75555), LT Y XP V11 (75556), LT Y XP Table Unbound (75563);
//   own state 81114 and import runner 81115 (copies of 75568/75513, so no SingleInstance codeunit is shared with another test codeunit);
//   own table 81080, xmlports 81081-81085, tests 81086
// Probe: corpus issue 657. UseLax with an unknown element and an element of another namespace in the middle of a sequence; default namespaces (xmlns="...")
// on the root, on a table element and on a field element; XmlVersionNo = V11 imports of a 1.0 declaration and of no declaration; Unbound = true on a
// table element; a namespace prefix that no node uses; InlineSchema with more field types, attributes, empty values and no rows.
// The export of a port with an unbound field element is not probed: it does not end (YXmlPortProps.al:716).
// BC versions: 27-29

table 81080 "BD XP Types"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; D; Date) { }
        field(5; B; Boolean) { }
        field(6; Opt; Option) { OptionMembers = Alpha,Beta; }
        field(7; DT; DateTime) { }
        field(8; Cd; Code[10]) { }
        field(9; T; Time) { }
        field(10; Big; BigInteger) { }
        field(11; Dur; Duration) { }
        field(12; G; Guid) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 81081 "BD XP Inline Types"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    InlineSchema = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "BD XP Types")
            {
                XmlName = 'Row';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
                fieldelement(Amt; Rw.Amt) { }
                fieldelement(D; Rw.D) { }
                fieldelement(B; Rw.B) { }
                fieldelement(Opt; Rw.Opt) { }
                fieldelement(DT; Rw.DT) { }
                fieldelement(Cd; Rw.Cd) { }
                fieldelement(T; Rw.T) { }
                fieldelement(Big; Rw.Big) { }
                fieldelement(Dur; Rw.Dur) { }
                fieldelement(G; Rw.G) { }
            }
        }
    }
}

xmlport 81082 "BD XP Inline Attrs"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    InlineSchema = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "BD XP Types")
            {
                XmlName = 'Row';
                MinOccurs = Zero;
                fieldattribute(Id; Rw.Id) { }
                fieldattribute(Amt; Rw.Amt) { }
                fieldattribute(B; Rw.B) { Occurrence = Optional; }
                textattribute(Note) { }
                fieldelement(Name; Rw.Name) { }
                textelement(Extra) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 81083 "BD XP Unused Prefix"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    Namespaces = p = 'urn:bd-p', q = 'urn:bd-q';

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { NamespacePrefix = 'p'; }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 81084 "BD XP No Prefix Used"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    Namespaces = q = 'urn:bd-q';

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

xmlport 81085 "BD XP Default Ns"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    DefaultNamespace = 'urn:bd-default';
    UseDefaultNamespace = true;

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

codeunit 81086 "BD XmlPort Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seen: Codeunit "BD XP State";

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
        ClearLastError();
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
        ClearLastError();
        if Codeunit.Run(Codeunit::"BD XP Import Runner") then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Import(var Observer: Codeunit "Probe Observer"; Name: Text; XmlPortId: Integer; Xml: Text)
    begin
        Seed();
        Observer.Observe(Name, ImportText(XmlPortId, Xml));
        Observer.Observe(Name + ' rows', Rows());
    end;

    local procedure SeedTypes(WithValues: Boolean)
    var
        R: Record "BD XP Types";
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        if WithValues then begin
            R.Name := 'Alpha & <b>';
            R.Amt := -1234.5;
            R.D := DMY2Date(5, 3, 2024);
            R.B := true;
            R.Opt := R.Opt::Beta;
            R.DT := CreateDateTime(DMY2Date(5, 3, 2024), 090507T);
            R.Cd := 'CODE1';
            R.T := 143015T;
            R.Big := 9876543210L;
            R.Dur := 90061001;
            R.G := '{5A2F6C9E-1B3D-4E8F-9A0B-1C2D3E4F5A6B}';
        end;
        R.Insert();
        Commit();
    end;

    [Test]
    procedure BdUseLax_UnknownElementMidSequence()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'lax', 75553, '<Root><Item><Id>7</Id><Unknown>x</Unknown><Name>seven</Name></Item></Root>');
        Import(Observer, 'strict', 75554, '<Root><Item><Id>7</Id><Unknown>x</Unknown><Name>seven</Name></Item></Root>');
        Import(Observer, 'lax first', 75553, '<Root><Item><Unknown>x</Unknown><Id>8</Id><Name>eight</Name></Item></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure BdUseLax_OtherNamespaceMidSequence()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'lax', 75553, '<Root><Item><Id>6</Id><Unknown xmlns="urn:other">x</Unknown><Name>six</Name></Item></Root>');
        Import(Observer, 'strict', 75554, '<Root><Item><Id>6</Id><Unknown xmlns="urn:other">x</Unknown><Name>six</Name></Item></Root>');
        Import(Observer, 'lax between items', 75553, '<Root><Item><Id>9</Id><Name>nine</Name></Item><Other xmlns="urn:other"/><Item><Id>10</Id><Name>ten</Name></Item></Root>');
        Import(Observer, 'lax first', 75553, '<Root><Item><Unknown xmlns="urn:other">x</Unknown><Id>11</Id><Name>eleven</Name></Item></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure BdDefaultNamespace_OnRoot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'strict', 75554, '<Root xmlns="urn:x"><Item><Id>4</Id><Name>four</Name></Item></Root>');
        Import(Observer, 'lax', 75553, '<Root xmlns="urn:x"><Item><Id>4</Id><Name>four</Name></Item></Root>');
        Import(Observer, 'strict empty', 75554, '<Root xmlns=""><Item><Id>5</Id><Name>five</Name></Item></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure BdDefaultNamespace_InheritedFromParent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'strict item', 75554, '<Root><Item xmlns="urn:x"><Id>3</Id><Name>three</Name></Item></Root>');
        Import(Observer, 'lax item', 75553, '<Root><Item xmlns="urn:x"><Id>3</Id><Name>three</Name></Item></Root>');
        Import(Observer, 'strict field', 75554, '<Root><Item><Id xmlns="urn:x">12</Id><Name>twelve</Name></Item></Root>');
        Import(Observer, 'lax field', 75553, '<Root><Item><Id>13</Id><Name xmlns="urn:x">thirteen</Name></Item></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure BdDefaultNamespace_PortWithDefaultNamespace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', 81085);
        Import(Observer, 'same namespace', 81085, '<Root xmlns="urn:bd-default"><Item><Id>14</Id><Name>fourteen</Name></Item></Root>');
        Import(Observer, 'no namespace', 81085, '<Root><Item><Id>15</Id><Name>fifteen</Name></Item></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure BdXmlVersionNo_V11_ImportOtherDeclarations()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'v11 decl 1.0', 75556, '<?xml version="1.0" encoding="utf-8"?><Root><Item><Id>7</Id><Name>seven</Name></Item></Root>');
        Import(Observer, 'v11 no decl', 75556, '<Root><Item><Id>8</Id><Name>eight</Name></Item></Root>');
        Import(Observer, 'v10 no decl', 75555, '<Root><Item><Id>9</Id><Name>nine</Name></Item></Root>');
        Import(Observer, 'v10 decl 1.1', 75555, '<?xml version="1.1" encoding="utf-8"?><Root><Item><Id>10</Id><Name>ten</Name></Item></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure BdUnbound_TableElement_ExportAndImport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', 75563);
        Import(Observer, 'import', 75563, '<Root><Item><Id>31</Id></Item><Plain>p</Plain></Root>');
        Import(Observer, 'import two', 75563, '<Root><Item><Id>32</Id></Item><Item><Id>33</Id></Item><Plain>p</Plain></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure BdNamespaces_PrefixNoNodeUses()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'one unused', 81083);
        Export(Observer, 'all unused', 81084);
        Import(Observer, 'import one unused', 81083, '<Root xmlns:p="urn:bd-p"><Item><p:Id>16</p:Id><Name>sixteen</Name></Item></Root>');
        Import(Observer, 'import all unused', 81084, '<Root><Item><Id>17</Id><Name>seventeen</Name></Item></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure BdInlineSchema_FieldTypes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedTypes(true);
        Export(Observer, 'values', 81081);
        Observer.Finish();
    end;

    [Test]
    procedure BdInlineSchema_FieldTypesEmptyValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedTypes(false);
        Export(Observer, 'empty', 81081);
        Observer.Finish();
    end;

    [Test]
    procedure BdInlineSchema_NoRows()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "BD XP Types";
    begin
        R.DeleteAll();
        Commit();
        Export(Observer, 'types', 81081);
        Observer.Finish();
    end;

    [Test]
    procedure BdInlineSchema_NoRowsAttributes()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "BD XP Types";
    begin
        R.DeleteAll();
        Commit();
        Export(Observer, 'attrs', 81082);
        Observer.Finish();
    end;

    [Test]
    procedure BdInlineSchema_Attributes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedTypes(true);
        Export(Observer, 'values', 81082);
        Observer.Finish();
    end;

    [Test]
    procedure BdInlineSchema_AttributesEmptyValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedTypes(false);
        Export(Observer, 'empty', 81082);
        Observer.Finish();
    end;
}

codeunit 81114 "BD XP State"
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

codeunit 81115 "BD XP Import Runner"
{
    trigger OnRun()
    var
        Seen: Codeunit "BD XP State";
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
