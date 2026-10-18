// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 67220 (also used by the OnPrem app), codeunits 67221 and 67222
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: Variant.IsDataClassificationType and Variant.IsSecurityFiltering over many value kinds;
// Database.CopyCompany (destination company, copied rows, errors for a missing source and an existing destination).
// BC versions: 27, 28, 29

table 67220 "LT O Blob Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
        field(3; Name; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67221 "LT O Small Builtins"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure VariantKinds(var Observer: Codeunit "Probe Observer"; Tag: Text; V: Variant)
    begin
        Observer.Observe(Tag + '|IsDataClassificationType', Format(V.IsDataClassificationType));
        Observer.Observe(Tag + '|IsSecurityFiltering', Format(V.IsSecurityFiltering));
    end;

    [Test]
    procedure O_Variant_IsDataClassificationType_IsSecurityFiltering()
    var
        Observer: Codeunit "Probe Observer";
        DC: DataClassification;
        SF: SecurityFilter;
        Int: Integer;
        Txt: Text;
        Bool: Boolean;
        Opt: Option A,B;
        Vb: Verbosity;
        Empty: Variant;
    begin
        DC := DataClassification::CustomerContent;
        VariantKinds(Observer, 'DataClassification', DC);
        SF := SecurityFilter::Filtered;
        VariantKinds(Observer, 'SecurityFilter', SF);
        VariantKinds(Observer, 'Integer', Int);
        VariantKinds(Observer, 'Text', Txt);
        VariantKinds(Observer, 'Boolean', Bool);
        VariantKinds(Observer, 'Option', Opt);
        VariantKinds(Observer, 'Verbosity', Vb);
        VariantKinds(Observer, 'empty variant', Empty);
        Observer.Expect('DataClassification|IsDataClassificationType', 'Yes');
        Observer.Expect('DataClassification|IsSecurityFiltering', 'No');
        Observer.Expect('SecurityFilter|IsDataClassificationType', 'No');
        Observer.Expect('SecurityFilter|IsSecurityFiltering', 'Yes');
        Observer.Expect('Integer|IsDataClassificationType', 'No');
        Observer.Expect('Integer|IsSecurityFiltering', 'No');
        Observer.Expect('Text|IsDataClassificationType', 'No');
        Observer.Expect('Text|IsSecurityFiltering', 'No');
        Observer.Expect('Boolean|IsDataClassificationType', 'No');
        Observer.Expect('Boolean|IsSecurityFiltering', 'No');
        Observer.Expect('Option|IsDataClassificationType', 'No');
        Observer.Expect('Option|IsSecurityFiltering', 'No');
        Observer.Expect('Verbosity|IsDataClassificationType', 'No');
        Observer.Expect('Verbosity|IsSecurityFiltering', 'No');
        Observer.Expect('empty variant|IsDataClassificationType', 'No');
        Observer.Expect('empty variant|IsSecurityFiltering', 'No');
        Observer.Verify();
    end;

    local procedure CopyIt(Source: Text; Destination: Text): Boolean
    var
        Runner: Codeunit "LT O Copy Runner";
    begin
        Runner.Setup(Source, Destination);
        exit(Runner.Run());
    end;

    local procedure DropCompany(Name: Text[30])
    var
        Company: Record Company;
    begin
        if Company.Get(Name) then
            Company.Delete(true);
    end;

    // Copies a company the test creates (never the session company): copying the session company also copies the test runner's own row in
    // table "Test Method Line", which the runner holds in its open transaction (corpus issue 654: the copy then failed on Windows 27.5 and 29.0
    // and on Linux 27 with "a record in table 'Test Method Line' is being updated in a transaction done by another session").
    [Test]
    procedure O_Database_CopyCompany()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
        Row: Record "LT O Blob Row";
    begin
        if CopyIt('LT O No Such Company', 'LT O Copy Target') then
            Observer.Observe('missing source', 'no error')
        else
            Observer.ObserveError('missing source');
        Observer.Observe('missing source|destination exists', Format(Company.Get('LT O Copy Target')));
        if CopyIt(CompanyName(), CompanyName()) then
            Observer.Observe('existing destination', 'no error')
        else
            Observer.ObserveError('existing destination');
        DropCompany('LT O Copy Source');
        DropCompany('LT O Copy Target');
        DropCompany('LT O Copy Target 2');
        Company.Init();
        Company.Name := 'LT O Copy Source';
        Company.Insert();
        Commit();
        if CopyIt('LT O Copy Source', 'LT O Copy Target') then
            Observer.Observe('copy', 'no error')
        else
            Observer.ObserveError('copy');
        Observer.Observe('copy|destination exists', Format(Company.Get('LT O Copy Target')));
        Row.ChangeCompany('LT O Copy Source');
        Row.Id := 1;
        Row.Name := 'copied';
        Row.Insert();
        Commit();
        if CopyIt('LT O Copy Source', 'LT O Copy Target 2') then
            Observer.Observe('copy rows', 'no error')
        else
            Observer.ObserveError('copy rows');
        Clear(Row);
        if Row.ChangeCompany('LT O Copy Target 2') then
            Observer.Observe('copy rows|target', Format(Row.Count()) + '|' + Format(Row.Get(1)) + '|' + Row.Name)
        else
            Observer.Observe('copy rows|target', 'no company');
        DropCompany('LT O Copy Source');
        DropCompany('LT O Copy Target');
        DropCompany('LT O Copy Target 2');
        Commit();
        Observer.Finish();
    end;
}

codeunit 67222 "LT O Copy Runner"
{
    var
        SourceName: Text;
        DestinationName: Text;

    procedure Setup(Source: Text; Destination: Text)
    begin
        SourceName := Source;
        DestinationName := Destination;
    end;

    trigger OnRun()
    begin
        Database.CopyCompany(SourceName, DestinationName);
    end;
}
