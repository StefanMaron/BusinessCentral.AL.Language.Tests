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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
