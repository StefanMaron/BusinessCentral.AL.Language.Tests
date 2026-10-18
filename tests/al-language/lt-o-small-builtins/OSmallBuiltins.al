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
        Observer.Finish();
    end;

    local procedure CopyIt(Source: Text; Destination: Text): Boolean
    var
        Runner: Codeunit "LT O Copy Runner";
    begin
        Runner.Setup(Source, Destination);
        exit(Runner.Run());
    end;

    [Test]
    procedure O_Database_CopyCompany()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
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
        if CopyIt(CompanyName(), 'LT O Copy Target') then
            Observer.Observe('copy', 'no error')
        else
            Observer.ObserveError('copy');
        Observer.Observe('copy|destination exists', Format(Company.Get('LT O Copy Target')));
        if Company.Get('LT O Copy Target') then
            Company.Delete();
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
