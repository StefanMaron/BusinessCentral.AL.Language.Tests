// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.io.directoryinfo.getfiles
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; System Application (Web Service Management, DotNet alias
//   QueryMetadataReader), Base Application (codeunit ODataUtility); self-contained table 99400, query 99401, test codeunit 99402
// Probe (writer QX, Microsoft's DemoTool):
//   Create Data Exch. Column Def: DirectoryInfo := DirectoryInfo.DirectoryInfo(Path); if DirectoryInfo.Exists then
//   Enumerator := DirectoryInfo.GetFiles('*.xml').GetEnumerator(); while Enumerator.MoveNext() do FileInfo := Enumerator.Current; ...
//   (what AL sees: Exists, the files the pattern selects and their order, FullName and Name);
//   Create Web Services: ODataUtility.GetTenantWebServiceMetadata(TenantWebService, MetaData) and
//   WebServiceManagement.CreateTenantWebServiceColumnForQuery(..., MetaData): the Tenant Web Service Columns rows a query gives.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.IO.DirectoryInfo"; LtQxDirectoryInfo) { }
        type("System.IO.FileInfo"; LtQxFileInfo) { }
        type("System.IO.Directory"; LtQxDirectory) { }
        type("System.Collections.IEnumerator"; LtQxEnumerator) { }
    }
}

dotnet
{
    assembly("System.Xml")
    {
        type("System.Xml.XmlDocument"; LtRdXmlDocument) { }
    }
}

table 99400 "LT QX DN Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 99401 "LT QX DN Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT QX DN Row")
        {
            column(Id; Id) { }
            column(RowName; Name) { }
            column(Amount; Amount) { }
        }
    }
}

codeunit 99402 "LT QX DotNet Demo Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure WriteFile(Name: Text)
    var
        F: File;
    begin
        F.Create(Name);
        F.Write('x');
        F.Close();
    end;

    [Test]
    procedure QX_DirectoryInfo_GetFiles()
    var
        DirectoryInfo: DotNet LtQxDirectoryInfo;
        FileInfo: DotNet LtQxFileInfo;
        Directory: DotNet LtQxDirectory;
        Enumerator: DotNet LtQxEnumerator;
        Path: Text;
        Names: List of [Text];
        Visited: Text;
        Sorted: Text;
        FullNameOk: Boolean;
        Count: Integer;
        Name: Text;
    begin
        Path := TemporaryPath() + 'ltqx' + DelChr(Format(CreateGuid()), '=', '{}-');
        DirectoryInfo := DirectoryInfo.DirectoryInfo(Path);
        Observer.Observe('missing exists', Format(DirectoryInfo.Exists));
        Directory.CreateDirectory(Path);
        WriteFile(Path + '/c.xml');
        WriteFile(Path + '/a.xml');
        WriteFile(Path + '/b.XML');
        WriteFile(Path + '/d.txt');
        WriteFile(Path + '/e.xml.bak');
        DirectoryInfo := DirectoryInfo.DirectoryInfo(Path);
        Observer.Observe('created exists', Format(DirectoryInfo.Exists));
        FullNameOk := true;
        Enumerator := DirectoryInfo.GetFiles('*.xml').GetEnumerator();
        while Enumerator.MoveNext() do begin
            FileInfo := Enumerator.Current;
            Count += 1;
            Names.Add(FileInfo.Name);
            if FileInfo.FullName <> Path + '/' + FileInfo.Name then
                FullNameOk := false;
        end;
        Observer.Observe('count', Format(Count));
        Observer.Observe('fullname is path + / + name', Format(FullNameOk));
        foreach Name in Names do
            if Name = 'a.xml' then
                Sorted += 'a.xml,';
        foreach Name in Names do
            if Name = 'b.XML' then
                Sorted += 'b.XML,';
        foreach Name in Names do
            if Name = 'c.xml' then
                Sorted += 'c.xml,';
        foreach Name in Names do
            if not (Name in ['a.xml', 'b.XML', 'c.xml']) then
                Sorted += Name + ',';
        Observer.Observe('names (fixed order)', Sorted);
        foreach Name in Names do
            Visited += Name + ',';
        Observer.Observe('enumeration order', Visited);
        Directory.Delete(Path, true);
        Observer.Expect('missing exists', 'No');
        Observer.Expect('created exists', 'Yes');
        Observer.Ignore('count');
        Observer.Ignore('fullname is path + / + name');
        Observer.Ignore('names (fixed order)');
        Observer.Ignore('enumeration order');
        Observer.Verify();
    end;

    [Test]
    procedure QX_QueryMetadataReader_TenantWebServiceColumns()
    var
        TenantWebService: Record "Tenant Web Service";
        Columns: Record "Tenant Web Service Columns";
        WebServiceManagement: Codeunit "Web Service Management";
        ODataUtility: Codeunit ODataUtility;
        MetaData: DotNet QueryMetadataReader;
        Result: Text;
    begin
        TenantWebService.SetFilter("Service Name", 'LTQX*');
        TenantWebService.DeleteAll(true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Query, Query::"LT QX DN Query", 'LTQXQuery', true);
        Observer.Observe('get', Format(TenantWebService.Get(TenantWebService."Object Type"::Query, 'LTQXQuery')));
        ODataUtility.GetTenantWebServiceMetadata(TenantWebService, MetaData);
        Observer.Observe('metadata is null', Format(IsNull(MetaData)));
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 1, Database::"LT QX DN Row", MetaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 2, Database::"LT QX DN Row", MetaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 3, Database::"LT QX DN Row", MetaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 9, Database::"LT QX DN Row", MetaData);
        Columns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        if Columns.FindSet() then
            repeat
                Result += '[' + Format(Columns."Data Item") + '|' + Format(Columns."Field Number") + '|' + Columns."Field Name" + '|' + Format(Columns.Include) + ']';
            until Columns.Next() = 0;
        Observer.Observe('columns', Result);
        Columns.DeleteAll();
        TenantWebService.Delete(true);
        Observer.Expect('get', 'Yes');
        Observer.Expect('metadata is null', 'No');
        Observer.Expect('columns', '[99400|1|Id|Yes][99400|2|RowName|Yes][99400|3|Amount|Yes][99400|9||Yes]');
        Observer.Verify();
    end;

    // ---- Writer RD (Microsoft's DemoTool, round 2: Export RapidStart Packages and Config. XML Exchange.ExportPackageXML on the server:
    // FileManagement.ServerDirectoryExists / ServerRemoveDirectory(Path, true) / ServerCreateDirectory (InitializeMediaTempFolder),
    // ServerTempFileName(''), DotNet XmlDocument.Save(ServerFile), ConfigPckgCompressionMgt.ServersideCompress(Src, Dst),
    // ServerFileExists, DeleteServerFile): what AL sees of each step under TemporaryPath, and the static DotNet System.IO.Directory.Exists. ----

    local procedure RdMask(Value: Text): Text
    var
        Index: Integer;
        Result: Text;
    begin
        for Index := 1 to StrLen(Value) do
            if Value[Index] in ['0' .. '9', 'a' .. 'z', 'A' .. 'Z'] then
                Result += 'x'
            else
                Result += Format(Value[Index]);
        exit(Result);
    end;

    local procedure RdTempNameShape(Name: Text): Text
    begin
        if not Name.StartsWith(TemporaryPath()) then
            exit('not under TemporaryPath: ' + RdMask(Name));
        exit('<tmp>' + RdMask(CopyStr(Name, StrLen(TemporaryPath()) + 1)));
    end;

    local procedure RdFileLength(Name: Text): Integer
    var
        F: File;
        L: Integer;
    begin
        if not File.Exists(Name) then
            exit(-1);
        F.Open(Name);
        L := F.Len();
        F.Close();
        exit(L);
    end;

    local procedure RdFirstBytes(Name: Text; Count: Integer): Text
    var
        F: File;
        InS: InStream;
        B: Byte;
        Index: Integer;
        Result: Text;
    begin
        F.Open(Name);
        F.CreateInStream(InS);
        for Index := 1 to Count do
            if not InS.EOS() then begin
                InS.Read(B);
                Result += Format(B) + ' ';
            end;
        F.Close();
        exit(Result);
    end;

    local procedure RdReadText(Name: Text): Text
    var
        F: File;
        TempBlob: Codeunit "Temp Blob";
        FileIn: InStream;
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        F.Open(Name);
        F.CreateInStream(FileIn);
        TempBlob.CreateOutStream(OutS);
        CopyStream(OutS, FileIn);
        F.Close();
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    [Test]
    procedure RD_DirectoryExists_Static()
    var
        Directory: DotNet LtQxDirectory;
        Path: Text;
    begin
        Path := TemporaryPath() + 'ltrd' + DelChr(Format(CreateGuid()), '=', '{}-');
        Observer.Observe('missing', Format(Directory.Exists(Path)));
        Directory.CreateDirectory(Path);
        Observer.Observe('created', Format(Directory.Exists(Path)));
        Observer.Observe('created with trailing slash', Format(Directory.Exists(Path + '/')));
        WriteFile(Path + '/f.txt');
        Observer.Observe('a file path', Format(Directory.Exists(Path + '/f.txt')));
        Observer.Observe('empty text', Format(Directory.Exists('')));
        Observer.Observe('TemporaryPath', Format(Directory.Exists(TemporaryPath())));
        Directory.Delete(Path, true);
        Observer.Observe('deleted', Format(Directory.Exists(Path)));
        Observer.Finish();
    end;

    [Test]
    procedure RD_FileManagement_ServerFolderOperations()
    var
        FileManagement: Codeunit "File Management";
        Path: Text;
        Media: Text;
    begin
        Path := TemporaryPath() + 'ltrd' + DelChr(Format(CreateGuid()), '=', '{}-');
        Media := Path + '/Media';
        Observer.Observe('exists missing', Format(FileManagement.ServerDirectoryExists(Media)));
        FileManagement.ServerRemoveDirectory(Media, true);
        Observer.Observe('remove missing: no error, exists', Format(FileManagement.ServerDirectoryExists(Media)));
        FileManagement.ServerCreateDirectory(Media);
        Observer.Observe('create nested: exists', Format(FileManagement.ServerDirectoryExists(Media)));
        FileManagement.ServerCreateDirectory(Media);
        Observer.Observe('create again: exists', Format(FileManagement.ServerDirectoryExists(Media)));
        WriteFile(Media + '/a.txt');
        WriteFile(Media + '/b.txt');
        Observer.Observe('file exists', Format(FileManagement.ServerFileExists(Media + '/a.txt')));
        Observer.Observe('delete file', Format(FileManagement.DeleteServerFile(Media + '/a.txt')));
        Observer.Observe('file exists after delete', Format(FileManagement.ServerFileExists(Media + '/a.txt')));
        Observer.Observe('delete missing file', Format(FileManagement.DeleteServerFile(Media + '/a.txt')));
        FileManagement.ServerRemoveDirectory(Media, true);
        Observer.Observe('remove recursive with a file: exists', Format(FileManagement.ServerDirectoryExists(Media)));
        Observer.Observe('remove recursive: file exists', Format(FileManagement.ServerFileExists(Media + '/b.txt')));
        Observer.Observe('parent exists', Format(FileManagement.ServerDirectoryExists(Path)));
        FileManagement.ServerRemoveDirectory(Path, false);
        Observer.Observe('remove empty non-recursive: exists', Format(FileManagement.ServerDirectoryExists(Path)));
        Observer.Finish();
    end;

    [Test]
    procedure RD_ServerTempFileName_XmlSave_Compress()
    var
        FileManagement: Codeunit "File Management";
        ConfigPckgCompressionMgt: Codeunit "Config. Pckg. Compression Mgt.";
        DataCompression: Codeunit "Data Compression";
        PackageXml: DotNet LtRdXmlDocument;
        F: File;
        InS: InStream;
        XmlFile: Text;
        GzFile: Text;
        BackFile: Text;
        SecondName: Text;
    begin
        XmlFile := FileManagement.ServerTempFileName('');
        Observer.Observe('temp name shape', RdTempNameShape(XmlFile));
        Observer.Observe('temp name exists', Format(File.Exists(XmlFile)));
        SecondName := FileManagement.ServerTempFileName('xml');
        Observer.Observe('temp name xml shape', RdTempNameShape(SecondName));
        Observer.Observe('two names differ', Format(SecondName <> XmlFile));
        Observer.Observe('directory of temp name is TemporaryPath', Format(FileManagement.GetDirectoryName(XmlFile) + '/' = TemporaryPath()));
        PackageXml := PackageXml.XmlDocument();
        PackageXml.LoadXml('<DataList><Row Id="1">one</Row></DataList>');
        PackageXml.Save(XmlFile);
        Observer.Observe('saved exists', Format(File.Exists(XmlFile)));
        Observer.Observe('saved length', Format(RdFileLength(XmlFile)));
        Observer.Observe('saved first bytes', RdFirstBytes(XmlFile, 4));
        Observer.Observe('saved text', RdReadText(XmlFile));
        PackageXml := PackageXml.XmlDocument();
        PackageXml.LoadXml('<?xml version="1.0" encoding="UTF-16" standalone="yes"?><DataList><Row Id="1">one</Row></DataList>');
        PackageXml.Save(SecondName);
        Observer.Observe('utf-16 declaration: length', Format(RdFileLength(SecondName)));
        Observer.Observe('utf-16 declaration: first bytes', RdFirstBytes(SecondName, 4));
        GzFile := FileManagement.ServerTempFileName('');
        ConfigPckgCompressionMgt.ServersideCompress(XmlFile, GzFile);
        Observer.Observe('compressed exists', Format(File.Exists(GzFile)));
        Observer.Observe('compressed length > 0', Format(RdFileLength(GzFile) > 0));
        Observer.Observe('compressed first bytes', RdFirstBytes(GzFile, 3));
        F.Open(GzFile);
        F.CreateInStream(InS);
        Observer.Observe('IsGZip compressed', Format(DataCompression.IsGZip(InS)));
        F.Close();
        F.Open(XmlFile);
        F.CreateInStream(InS);
        Observer.Observe('IsGZip plain', Format(DataCompression.IsGZip(InS)));
        F.Close();
        BackFile := FileManagement.ServerTempFileName('');
        Observer.Observe('decompress', Format(ConfigPckgCompressionMgt.ServersideDecompress(GzFile, BackFile)));
        Observer.Observe('decompressed text', RdReadText(BackFile));
        Observer.Observe('decompress a plain file', Format(ConfigPckgCompressionMgt.ServersideDecompress(XmlFile, FileManagement.ServerTempFileName(''))));
        asserterror ConfigPckgCompressionMgt.ServersideCompress(XmlFile, GzFile);
        Observer.Observe('compress onto an existing file: error has the name', Format(StrPos(GetLastErrorText(), GzFile) > 0));
        Observer.Observe('compress onto an existing file: error', GetLastErrorText().Replace(GzFile, '<dst>'));
        Observer.Observe('delete', Format(FileManagement.DeleteServerFile(XmlFile)) + Format(FileManagement.DeleteServerFile(SecondName)) + Format(FileManagement.DeleteServerFile(GzFile)) + Format(FileManagement.DeleteServerFile(BackFile)));
        Observer.Finish();
    end;
}
