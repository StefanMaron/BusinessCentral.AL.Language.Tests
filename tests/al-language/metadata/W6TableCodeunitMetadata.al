// Batch 6, md:349 [Table Metadata, CodeUnit Metadata]: columns DrillDownPageId, PasteIsValid, ReplicateData, CompressionType, Scope, Access and "App ID"
// that the runtime fills from the declared properties. Observe-only; each column is read by name for OWN objects, one table/codeunit with all defaults
// and one that sets the properties.

table 67311 "W6 TM Defaults"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 67312 "W6 TM Props"
{
    DataClassification = SystemMetadata;
    DrillDownPageId = "W6 TM List";
    LookupPageId = "W6 TM List";
    PasteIsValid = false;
    ReplicateData = false;
    CompressionType = Row;
    Access = Internal;
    DataPerCompany = false;
    Extensible = false;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 67313 "W6 TM List"
{
    PageType = List;
    SourceTable = "W6 TM Props";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 67314 "W6 CM Defaults"
{
    procedure Nothing()
    begin
    end;
}

codeunit 67315 "W6 CM Props"
{
    Access = Internal;
    SingleInstance = true;
    TableNo = "W6 TM Defaults";
    InherentPermissions = X;
    InherentEntitlements = X;

    trigger OnRun()
    begin
    end;
}

codeunit 67316 "W6 Table Codeunit Meta"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TableMetadata_Defaults()
    var
        TableMeta: Record "Table Metadata";
        Module: ModuleInfo;
        Observer: Codeunit "Probe Observer";
    begin
        NavApp.GetCurrentModuleInfo(Module);
        TableMeta.Get(Database::"W6 TM Defaults");
        Observer.Observe('name', TableMeta.Name);
        Observer.Observe('drill_down_page_id', Format(TableMeta.DrillDownPageID));
        Observer.Observe('lookup_page_id', Format(TableMeta.LookupPageID));
        Observer.Observe('paste_is_valid', Format(TableMeta.PasteIsValid));
        Observer.Observe('replicate_data', Format(TableMeta.ReplicateData));
        Observer.Observe('compression_type', Format(TableMeta.CompressionType));
        Observer.Observe('scope', Format(TableMeta.Scope));
        Observer.Observe('access', Format(TableMeta.Access));
        Observer.Observe('data_per_company', Format(TableMeta.DataPerCompany));
        Observer.Observe('table_type', Format(TableMeta.TableType));
        Observer.Observe('app_id_is_this_app', Format(TableMeta."App ID" = Module.Id()));
        Observer.Expect('name', 'W6 TM Defaults');
        Observer.Expect('drill_down_page_id', '0');
        Observer.Expect('lookup_page_id', '0');
        Observer.Expect('paste_is_valid', 'Yes');
        Observer.Expect('replicate_data', 'Yes');
        Observer.Expect('compression_type', 'Unspecified');
        Observer.Expect('scope', 'Cloud');
        Observer.Expect('access', 'Public');
        Observer.Expect('data_per_company', 'Yes');
        Observer.Expect('table_type', 'Normal');
        Observer.Expect('app_id_is_this_app', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TableMetadata_DeclaredProperties()
    var
        TableMeta: Record "Table Metadata";
        Module: ModuleInfo;
        Observer: Codeunit "Probe Observer";
    begin
        NavApp.GetCurrentModuleInfo(Module);
        TableMeta.Get(Database::"W6 TM Props");
        Observer.Observe('drill_down_page_is_the_list', Format(TableMeta.DrillDownPageID = Page::"W6 TM List"));
        Observer.Observe('lookup_page_is_the_list', Format(TableMeta.LookupPageID = Page::"W6 TM List"));
        Observer.Observe('paste_is_valid', Format(TableMeta.PasteIsValid));
        Observer.Observe('replicate_data', Format(TableMeta.ReplicateData));
        Observer.Observe('compression_type', Format(TableMeta.CompressionType));
        Observer.Observe('compression_type_ordinal', Format(TableMeta.CompressionType, 0, 2));
        Observer.Observe('scope', Format(TableMeta.Scope));
        Observer.Observe('access', Format(TableMeta.Access));
        Observer.Observe('data_per_company', Format(TableMeta.DataPerCompany));
        Observer.Observe('app_id_is_this_app', Format(TableMeta."App ID" = Module.Id()));
        Observer.Expect('drill_down_page_is_the_list', 'Yes');
        Observer.Expect('lookup_page_is_the_list', 'Yes');
        Observer.Expect('paste_is_valid', 'No');
        Observer.Expect('replicate_data', 'No');
        Observer.Expect('compression_type', 'Row');
        Observer.Expect('compression_type_ordinal', '2');
        Observer.Expect('scope', 'Cloud');
        Observer.Expect('access', 'Internal');
        Observer.Expect('data_per_company', 'No');
        Observer.Expect('app_id_is_this_app', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TableMetadata_OfAPlatformTable_Columns()
    var
        TableMeta: Record "Table Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        TableMeta.Get(Database::"Event Subscription");
        Observer.Observe('platform_table_app_id_is_null', Format(IsNullGuid(TableMeta."App ID")));
        Observer.Observe('platform_table_scope', Format(TableMeta.Scope));
        Observer.Observe('platform_table_access', Format(TableMeta.Access));
        Observer.Observe('platform_table_replicate_data', Format(TableMeta.ReplicateData));
        Observer.Observe('platform_table_compression_type', Format(TableMeta.CompressionType));
        Observer.Observe('platform_table_paste_is_valid', Format(TableMeta.PasteIsValid));
        Observer.Observe('platform_table_drill_down_page_id', Format(TableMeta.DrillDownPageID));
        Observer.Expect('platform_table_app_id_is_null', 'Yes');
        Observer.Expect('platform_table_scope', 'Cloud');
        Observer.Expect('platform_table_access', 'Public');
        Observer.Expect('platform_table_replicate_data', 'Yes');
        Observer.Expect('platform_table_compression_type', 'Unspecified');
        Observer.Expect('platform_table_paste_is_valid', 'Yes');
        Observer.Expect('platform_table_drill_down_page_id', '0');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitMetadata_Defaults()
    var
        CodeunitMeta: Record "CodeUnit Metadata";
        Module: ModuleInfo;
        Observer: Codeunit "Probe Observer";
    begin
        NavApp.GetCurrentModuleInfo(Module);
        CodeunitMeta.Get(Codeunit::"W6 CM Defaults");
        Observer.Observe('name', CodeunitMeta.Name);
        Observer.Observe('table_no', Format(CodeunitMeta.TableNo));
        Observer.Observe('subtype', Format(CodeunitMeta.Subtype));
        Observer.Observe('single_instance', Format(CodeunitMeta.SingleInstance));
        Observer.Observe('app_id_is_this_app', Format(CodeunitMeta."App ID" = Module.Id()));
        Observer.Expect('name', 'W6 CM Defaults');
        Observer.Expect('table_no', '0');
        Observer.Expect('subtype', 'Normal');
        Observer.Expect('single_instance', 'No');
        Observer.Expect('app_id_is_this_app', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitMetadata_DeclaredProperties()
    var
        CodeunitMeta: Record "CodeUnit Metadata";
        Module: ModuleInfo;
        Observer: Codeunit "Probe Observer";
    begin
        NavApp.GetCurrentModuleInfo(Module);
        CodeunitMeta.Get(Codeunit::"W6 CM Props");
        Observer.Observe('name', CodeunitMeta.Name);
        Observer.Observe('table_no_is_defaults_table', Format(CodeunitMeta.TableNo = Database::"W6 TM Defaults"));
        Observer.Observe('single_instance', Format(CodeunitMeta.SingleInstance));
        Observer.Observe('app_id_is_this_app', Format(CodeunitMeta."App ID" = Module.Id()));
        Observer.Expect('name', 'W6 CM Props');
        Observer.Expect('table_no_is_defaults_table', 'Yes');
        Observer.Expect('single_instance', 'Yes');
        Observer.Expect('app_id_is_this_app', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitMetadata_TestCodeunitItself()
    var
        CodeunitMeta: Record "CodeUnit Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        CodeunitMeta.Get(Codeunit::"W6 Table Codeunit Meta");
        Observer.Observe('subtype', Format(CodeunitMeta.Subtype));
        Observer.Observe('subtype_ordinal', Format(CodeunitMeta.Subtype, 0, 2));
        Observer.Observe('single_instance', Format(CodeunitMeta.SingleInstance));
        Observer.Expect('subtype', 'Test');
        Observer.Expect('subtype_ordinal', '1');
        Observer.Expect('single_instance', 'No');
        Observer.Verify();
    end;

    local procedure ColumnList(TableId: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Result: Text;
        i: Integer;
    begin
        RecRef.Open(TableId);
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            Result += Format(FldRef.Number()) + '=' + FldRef.Name() + ';';
        end;
        exit(Result);
    end;

    [Test]
    procedure ColumnNames_TableMetadata_And_CodeunitMetadata()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('table_metadata_columns', ColumnList(Database::"Table Metadata"));
        Observer.Observe('codeunit_metadata_columns', ColumnList(Database::"CodeUnit Metadata"));
        Observer.Expect('table_metadata_columns', '1=ID;2=Name;3=Caption;4=DataPerCompany;5=LookupPageID;6=DrillDownPageId;7=DataCaptionFields;8=PasteIsValid;9=LinkedObject;10=DataIsExternal;11=TableType;12=ExternalName;13=ObsoleteState;14=ObsoleteReason;15=DataClassification;16=ReplicateData;17=CompressionType;18=App ID;19=InherentPermissions;20=InherentEntitlements;21=Scope;22=Access;23=AL Namespace;');
        Observer.Expect('codeunit_metadata_columns', '1=ID;2=Name;3=TableNo;4=SingleInstance;5=SubType;6=App ID;7=InherentPermissions;8=InherentEntitlements;9=TestType;10=RequiredTestIsolation;11=AL Namespace;12=Has Test Data Source;');
        Observer.Verify();
    end;
}
