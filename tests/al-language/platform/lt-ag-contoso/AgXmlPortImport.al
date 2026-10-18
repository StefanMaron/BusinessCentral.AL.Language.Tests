// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own tables 78410-78411, codeunit 78405, xmlports 78420 to 78424, test codeunit 78402
// Probe: XmlPort properties that Microsoft's Contoso demo-data xmlports use on import: Occurrence = Optional and Required on field attributes
// (missing and present attribute), SourceTableView on a tableelement (import and export), and an empty requestpage section against none
// (Xmlport.Import and Xmlport.Export from code). MinOccurs on a tableelement, FieldValidate and Encoding on import are pinned in
// xmlport/W7XmlPortTests.al, pages/lt-report-page-properties/06-xmlport-fvat.al and xmlport/lt-af-xmlport/AfXmlPortEncoding.al.
// BC versions: 27-29

table 78410 "LT AG XP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Active; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 78420 "LT AG XP Attr Occurrence"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AG XP Row")
            {
                fieldattribute(Id; Row.Id)
                {
                    Occurrence = Required;
                }
                fieldattribute(Name; Row.Name)
                {
                    Occurrence = Optional;
                }
                fieldattribute(Active; Row.Active)
                {
                    Occurrence = Required;
                }
            }
        }
    }
}

xmlport 78421 "LT AG XP Source Table View"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AG XP Row")
            {
                SourceTableView = sorting(Id) order(descending) where(Active = const(true));
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
                fieldelement(Active; Row.Active) { }
            }
        }
    }
}

xmlport 78422 "LT AG XP Empty Request Page"
{
    Direction = Both;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AG XP Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }

    requestpage
    {
    }
}

xmlport 78423 "LT AG XP No Request Page"
{
    Direction = Both;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AG XP Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 78424 "LT AG XP Elem MinOccurs Import"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AG XP Row")
            {
                MinOccurs = Zero;
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

table 78411 "LT AG XP Job"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Content; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 78405 "LT AG XP Import Runner"
{
    TableNo = "LT AG XP Job";

    trigger OnRun()
    var
        InS: InStream;
    begin
        Rec.CalcFields(Content);
        Rec.Content.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(Rec.Id, InS);
    end;
}

codeunit 78402 "LT AG XP Import"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Rows(): Text
    var
        Row: Record "LT AG XP Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Row.Name + ':' + Format(Row.Active) + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure Seed()
    var
        Row: Record "LT AG XP Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'seed-one';
        Row.Active := true;
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'seed-two';
        Row.Active := false;
        Row.Insert();
    end;

    local procedure RunImport(XmlportId: Integer; Content: Text): Boolean
    var
        Job: Record "LT AG XP Job" temporary;
        OutS: OutStream;
    begin
        Job.Id := XmlportId;
        Job.Content.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        Commit();
        exit(Codeunit.Run(Codeunit::"LT AG XP Import Runner", Job));
    end;

    local procedure ExportText(XmlportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(XmlportId, OutS);
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure ObserveImport(Name: Text; XmlportId: Integer; Content: Text)
    begin
        Seed();
        Observer.Observe(Name + ' ok', Format(RunImport(XmlportId, Content)));
        if GetLastErrorText() <> '' then begin
            Observer.Observe(Name + ' error', GetLastErrorText());
            Observer.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Observe(Name + ' rows', Rows());
    end;

    [Test]
    procedure FieldAttribute_Occurrence_RequiredAndOptional_Import()
    begin
        ObserveImport('all present', Xmlport::"LT AG XP Attr Occurrence", '<Root><Row Id="10" Name="ten" Active="1"/></Root>');
        ObserveImport('optional missing', Xmlport::"LT AG XP Attr Occurrence", '<Root><Row Id="10" Active="1"/></Root>');
        ObserveImport('required Id missing', Xmlport::"LT AG XP Attr Occurrence", '<Root><Row Name="ten" Active="1"/></Root>');
        ObserveImport('required Active missing', Xmlport::"LT AG XP Attr Occurrence", '<Root><Row Id="10" Name="ten"/></Root>');
        ObserveImport('all missing', Xmlport::"LT AG XP Attr Occurrence", '<Root><Row/></Root>');
        ObserveImport('no row element', Xmlport::"LT AG XP Attr Occurrence", '<Root/>');
        Observer.Finish();
    end;

    [Test]
    procedure TableElement_MinOccursZero_Import()
    begin
        ObserveImport('no row element', Xmlport::"LT AG XP Elem MinOccurs Import", '<Root/>');
        ObserveImport('one row', Xmlport::"LT AG XP Elem MinOccurs Import", '<Root><Row><Id>10</Id><Name>ten</Name></Row></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure TableElement_SourceTableView_Import()
    begin
        ObserveImport('active and inactive', Xmlport::"LT AG XP Source Table View", '<Root><Row><Id>3</Id><Name>three</Name><Active>1</Active></Row><Row><Id>4</Id><Name>four</Name><Active>0</Active></Row></Root>');
        ObserveImport('replace seeded row', Xmlport::"LT AG XP Source Table View", '<Root><Row><Id>1</Id><Name>again</Name><Active>1</Active></Row></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure TableElement_SourceTableView_Export()
    begin
        Seed();
        Observer.Observe('export', ExportText(Xmlport::"LT AG XP Source Table View"));
        Observer.Finish();
    end;

    [Test]
    procedure RequestPage_EmptySection_ImportAndExport()
    begin
        ObserveImport('empty requestpage import', Xmlport::"LT AG XP Empty Request Page", '<Root><Row><Id>10</Id><Name>ten</Name></Row></Root>');
        ObserveImport('no requestpage import', Xmlport::"LT AG XP No Request Page", '<Root><Row><Id>10</Id><Name>ten</Name></Row></Root>');
        Seed();
        Observer.Observe('empty requestpage export', ExportText(Xmlport::"LT AG XP Empty Request Page"));
        Observer.Observe('no requestpage export', ExportText(Xmlport::"LT AG XP No Request Page"));
        Observer.Finish();
    end;
}
