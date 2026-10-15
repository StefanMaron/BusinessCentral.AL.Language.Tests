// Batch 6, md:348 [AllObj, AllObjWithCaption]: package ids of an object of the platform app, of Base Application and of this app; the "Object Subtype" and
// "App ID" of own extension objects; namespace columns. Observe-only. Ids and GUIDs are never printed: only null-ness and equality with ModuleInfo.

table 67317 "W6 AO Table"
{
    DataClassification = SystemMetadata;
    Caption = 'W6 AO Table caption';

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

tableextension 67318 "W6 AO Table Ext" extends "W6 AO Table"
{
    fields
    {
        field(67318; ExtField; Integer) { }
    }
}

page 67319 "W6 AO Page"
{
    PageType = List;
    SourceTable = "W6 AO Table";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'W6 AO Page caption';

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

pageextension 67320 "W6 AO Page Ext" extends "W6 AO Page"
{
}

codeunit 67321 "W6 AO Code"
{
    procedure Nothing()
    begin
    end;
}

codeunit 67322 "W6 AllObj Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure PackageFacts(var AllObjRec: Record AllObj; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Module: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Module);
        Observer.Observe(Prefix + '_app_package_id_null', Format(IsNullGuid(AllObjRec."App Package ID")));
        Observer.Observe(Prefix + '_app_runtime_package_id_null', Format(IsNullGuid(AllObjRec."App Runtime Package ID")));
        Observer.Observe(Prefix + '_runtime_equals_package', Format(AllObjRec."App Runtime Package ID" = AllObjRec."App Package ID"));
        Observer.Observe(Prefix + '_package_is_this_apps', Format(AllObjRec."App Package ID" = Module.PackageId()));
    end;

    [Test]
    procedure AllObj_PackageIds_ThisApp_BaseApp_Platform()
    var
        AllObjRec: Record AllObj;
        Observer: Codeunit "Probe Observer";
    begin
        AllObjRec.Get(AllObjRec."Object Type"::Table, Database::"W6 AO Table");
        PackageFacts(AllObjRec, 'own_table', Observer);
        AllObjRec.Get(AllObjRec."Object Type"::Codeunit, Codeunit::"W6 AO Code");
        PackageFacts(AllObjRec, 'own_codeunit', Observer);
        AllObjRec.Get(AllObjRec."Object Type"::Table, Database::Customer);
        PackageFacts(AllObjRec, 'base_app_table_customer', Observer);
        AllObjRec.Get(AllObjRec."Object Type"::Table, Database::User);
        PackageFacts(AllObjRec, 'platform_table_user', Observer);
        AllObjRec.Get(AllObjRec."Object Type"::Table, Database::"Event Subscription");
        PackageFacts(AllObjRec, 'platform_table_event_subscription', Observer);
        Observer.Expect('own_table_app_package_id_null', 'No');
        Observer.Expect('own_table_app_runtime_package_id_null', 'No');
        Observer.Expect('own_table_runtime_equals_package', 'Yes');
        Observer.Expect('own_table_package_is_this_apps', 'Yes');
        Observer.Expect('own_codeunit_app_package_id_null', 'No');
        Observer.Expect('own_codeunit_app_runtime_package_id_null', 'No');
        Observer.Expect('own_codeunit_runtime_equals_package', 'Yes');
        Observer.Expect('own_codeunit_package_is_this_apps', 'Yes');
        Observer.Expect('base_app_table_customer_app_package_id_null', 'No');
        Observer.Expect('base_app_table_customer_app_runtime_package_id_null', 'No');
        Observer.Expect('base_app_table_customer_runtime_equals_package', 'No');
        Observer.Expect('base_app_table_customer_package_is_this_apps', 'No');
        Observer.Expect('platform_table_user_app_package_id_null', 'No');
        Observer.Expect('platform_table_user_app_runtime_package_id_null', 'Yes');
        Observer.Expect('platform_table_user_runtime_equals_package', 'No');
        Observer.Expect('platform_table_user_package_is_this_apps', 'No');
        Observer.Expect('platform_table_event_subscription_app_package_id_null', 'No');
        Observer.Expect('platform_table_event_subscription_app_runtime_package_id_null', 'Yes');
        Observer.Expect('platform_table_event_subscription_runtime_equals_package', 'No');
        Observer.Expect('platform_table_event_subscription_package_is_this_apps', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AllObjWithCaption_ExtensionObjects_Subtype_AndPackage()
    var
        AllObjRec: Record AllObjWithCaption;
        Observer: Codeunit "Probe Observer";
    begin
        AllObjRec.SetRange("Object Type", AllObjRec."Object Type"::TableExtension);
        AllObjRec.SetRange("Object ID", 67318);
        Observer.Observe('table_extension_row_count', Format(AllObjRec.Count()));
        if AllObjRec.FindFirst() then begin
            Observer.Observe('table_extension_name', AllObjRec."Object Name");
            Observer.Observe('table_extension_subtype_is_extended_table_id', Format(AllObjRec."Object Subtype" = Format(Database::"W6 AO Table")));
            Observer.Observe('table_extension_package_id_null', Format(IsNullGuid(AllObjRec."App Package ID")));
        end;
        AllObjRec.SetRange("Object Type", AllObjRec."Object Type"::PageExtension);
        AllObjRec.SetRange("Object ID", 67320);
        Observer.Observe('page_extension_row_count', Format(AllObjRec.Count()));
        if AllObjRec.FindFirst() then begin
            Observer.Observe('page_extension_subtype_is_extended_page_id', Format(AllObjRec."Object Subtype" = Format(Page::"W6 AO Page")));
            Observer.Observe('page_extension_package_id_null', Format(IsNullGuid(AllObjRec."App Package ID")));
        end;
        Observer.Expect('table_extension_row_count', '1');
        Observer.Expect('table_extension_name', 'W6 AO Table Ext');
        Observer.Expect('table_extension_subtype_is_extended_table_id', 'Yes');
        Observer.Expect('table_extension_package_id_null', 'No');
        Observer.Expect('page_extension_row_count', '1');
        Observer.Expect('page_extension_subtype_is_extended_page_id', 'Yes');
        Observer.Expect('page_extension_package_id_null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AllObjWithCaption_AppId_Caption_Subtype()
    var
        Caption: Record AllObjWithCaption;
        Module: ModuleInfo;
        Observer: Codeunit "Probe Observer";
    begin
        NavApp.GetCurrentModuleInfo(Module);
        Caption.Get(Caption."Object Type"::Table, Database::"W6 AO Table");
        Observer.Observe('own_table_caption', Caption."Object Caption");
        Observer.Observe('own_table_name', Caption."Object Name");
        Observer.Observe('own_table_subtype', Caption."Object Subtype");
        Observer.Observe('own_table_app_id_is_this_app', Format(Caption."App ID" = Module.Id()));
        Caption.Get(Caption."Object Type"::Page, Page::"W6 AO Page");
        Observer.Observe('own_page_caption', Caption."Object Caption");
        Observer.Observe('own_page_subtype', Caption."Object Subtype");
        Observer.Observe('own_page_app_id_is_this_app', Format(Caption."App ID" = Module.Id()));
        Caption.Get(Caption."Object Type"::Codeunit, Codeunit::"W6 AO Code");
        Observer.Observe('own_codeunit_caption', Caption."Object Caption");
        Observer.Observe('own_codeunit_subtype', Caption."Object Subtype");
        Observer.Observe('own_codeunit_app_id_is_this_app', Format(Caption."App ID" = Module.Id()));
        Caption.Get(Caption."Object Type"::Table, Database::User);
        Observer.Observe('platform_table_app_id_null', Format(IsNullGuid(Caption."App ID")));
        Caption.Get(Caption."Object Type"::Table, Database::Customer);
        Observer.Observe('base_app_table_app_id_null', Format(IsNullGuid(Caption."App ID")));
        Observer.Expect('own_table_caption', 'W6 AO Table caption');
        Observer.Expect('own_table_name', 'W6 AO Table');
        Observer.Expect('own_table_subtype', 'Normal');
        Observer.Expect('own_table_app_id_is_this_app', 'Yes');
        Observer.Expect('own_page_caption', 'W6 AO Page caption');
        Observer.Expect('own_page_subtype', 'List');
        Observer.Expect('own_page_app_id_is_this_app', 'Yes');
        Observer.Expect('own_codeunit_caption', 'W6 AO Code');
        Observer.Expect('own_codeunit_subtype', '');
        Observer.Expect('own_codeunit_app_id_is_this_app', 'Yes');
        Observer.Expect('platform_table_app_id_null', 'Yes');
        Observer.Expect('base_app_table_app_id_null', 'No');
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
    procedure ColumnNames_AllObj_And_AllObjWithCaption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('allobj_columns', ColumnList(Database::AllObj));
        Observer.Observe('allobjwithcaption_columns', ColumnList(Database::AllObjWithCaption));
#if BC29PLUS
        Observer.Expect('allobj_columns', '1=Object Type;3=Object ID;4=Object Name;5=Name;60=App Package ID;61=App Runtime Package ID;62=AL Namespace;');
#else
        Observer.Expect('allobj_columns', '1=Object Type;3=Object ID;4=Object Name;60=App Package ID;61=App Runtime Package ID;62=AL Namespace;');
#endif
        Observer.Expect('allobjwithcaption_columns', '1=Object Type;3=Object ID;4=Object Name;5=Name;20=Object Caption;30=Object Subtype;60=App Package ID;61=App Runtime Package ID;62=App ID;63=AL Namespace;');
        Observer.Verify();
    end;
}
