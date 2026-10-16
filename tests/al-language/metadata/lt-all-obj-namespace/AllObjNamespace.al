// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-using-directive
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT P163 NS Table (73191), LT P163 NS Codeunit (73192), LT P163 NS Page (73194) in P163AllObjNsFixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// RISKY: reads the AL Namespace columns (62 of AllObj, 63 of AllObjWithCaption); own file so a compile failure drops only this file.

using P163Probe.Names;

codeunit 73193 "LT P163 AllObj Namespace"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure AllObjNs(ObjType: Option; ObjId: Integer): Text
    var
        AllObjRec: Record AllObj;
    begin
        if not AllObjRec.Get(ObjType, ObjId) then
            exit('<no row>');
        exit('[' + AllObjRec."AL Namespace" + ']');
    end;

    local procedure CaptionNs(ObjType: Option; ObjId: Integer): Text
    var
        Caption: Record AllObjWithCaption;
    begin
        if not Caption.Get(ObjType, ObjId) then
            exit('<no row>');
        exit('[' + Caption."AL Namespace" + ']');
    end;

    [Test]
    procedure P163_AllObj_ALNamespace_ByObjectKind()
    var
        AllObjRec: Record AllObj;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('table_namespaced', AllObjNs(AllObjRec."Object Type"::Table, Database::"LT P163 NS Table"));
        Observer.Observe('codeunit_namespaced', AllObjNs(AllObjRec."Object Type"::Codeunit, Codeunit::"LT P163 NS Codeunit"));
        Observer.Observe('page_namespaced', AllObjNs(AllObjRec."Object Type"::Page, Page::"LT P163 NS Page"));
        Observer.Observe('own_test_codeunit_no_namespace', AllObjNs(AllObjRec."Object Type"::Codeunit, Codeunit::"LT P163 AllObj Namespace"));
        Observer.Observe('probe_observer_no_namespace', AllObjNs(AllObjRec."Object Type"::Codeunit, 69160));
        Observer.Observe('platform_table_time_zone', AllObjNs(AllObjRec."Object Type"::Table, Database::"Time Zone"));
        Observer.Observe('platform_table_session', AllObjNs(AllObjRec."Object Type"::Table, Database::Session));
        Observer.Observe('base_app_table_customer_BaseApp', AllObjNs(AllObjRec."Object Type"::Table, 18));
        Observer.Observe('base_app_page_customer_card_BaseApp', AllObjNs(AllObjRec."Object Type"::Page, 21));
        Observer.Observe('base_app_codeunit_sales_post_BaseApp', AllObjNs(AllObjRec."Object Type"::Codeunit, 80));
        Observer.Observe('no_such_object', AllObjNs(AllObjRec."Object Type"::Table, 73999));
        Observer.Expect('table_namespaced', '[P163Probe.Names]');
        Observer.Expect('codeunit_namespaced', '[P163Probe.Names]');
        Observer.Expect('page_namespaced', '[P163Probe.Names]');
        Observer.Expect('own_test_codeunit_no_namespace', '[]');
        Observer.Expect('probe_observer_no_namespace', '[]');
        Observer.Expect('platform_table_time_zone', '[System.DateTime]');
        Observer.Expect('platform_table_session', '[System.Environment]');
        Observer.Expect('base_app_table_customer_BaseApp', '[Microsoft.Sales.Customer]');
        Observer.Expect('base_app_page_customer_card_BaseApp', '[Microsoft.Sales.Customer]');
        Observer.Expect('base_app_codeunit_sales_post_BaseApp', '[Microsoft.Sales.Posting]');
        Observer.Expect('no_such_object', '<no row>');
        Observer.Verify();
    end;

    [Test]
    procedure P163_AllObjWithCaption_ALNamespace_ByObjectKind()
    var
        Caption: Record AllObjWithCaption;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('table_namespaced', CaptionNs(Caption."Object Type"::Table, Database::"LT P163 NS Table"));
        Observer.Observe('codeunit_namespaced', CaptionNs(Caption."Object Type"::Codeunit, Codeunit::"LT P163 NS Codeunit"));
        Observer.Observe('page_namespaced', CaptionNs(Caption."Object Type"::Page, Page::"LT P163 NS Page"));
        Observer.Observe('own_test_codeunit_no_namespace', CaptionNs(Caption."Object Type"::Codeunit, Codeunit::"LT P163 AllObj Namespace"));
        Observer.Observe('platform_table_time_zone', CaptionNs(Caption."Object Type"::Table, Database::"Time Zone"));
        Observer.Observe('base_app_table_customer_BaseApp', CaptionNs(Caption."Object Type"::Table, 18));
        Observer.Observe('no_such_object', CaptionNs(Caption."Object Type"::Table, 73999));
        Observer.Expect('table_namespaced', '[P163Probe.Names]');
        Observer.Expect('codeunit_namespaced', '[P163Probe.Names]');
        Observer.Expect('page_namespaced', '[P163Probe.Names]');
        Observer.Expect('own_test_codeunit_no_namespace', '[]');
        Observer.Expect('platform_table_time_zone', '[System.DateTime]');
        Observer.Expect('base_app_table_customer_BaseApp', '[Microsoft.Sales.Customer]');
        Observer.Expect('no_such_object', '<no row>');
        Observer.Verify();
    end;

    [Test]
    procedure P163_AllObj_FilterOnALNamespace()
    var
        AllObjRec: Record AllObj;
        Observer: Codeunit "Probe Observer";
    begin
        AllObjRec.SetRange("AL Namespace", 'P163Probe.Names');
        Observer.Observe('rows_in_namespace', Format(AllObjRec.Count()));
        AllObjRec.SetRange("AL Namespace", 'p163probe.names');
        Observer.Observe('rows_in_namespace_lower', Format(AllObjRec.Count()));
        AllObjRec.SetFilter("AL Namespace", 'P163Probe*');
        Observer.Observe('rows_in_namespace_wildcard', Format(AllObjRec.Count()));
        AllObjRec.SetRange("AL Namespace", 'P163Probe');
        Observer.Observe('rows_in_parent_namespace_only', Format(AllObjRec.Count()));
        Observer.Expect('rows_in_namespace', '4');
        Observer.Expect('rows_in_namespace_lower', '0');
        Observer.Expect('rows_in_namespace_wildcard', '4');
        Observer.Expect('rows_in_parent_namespace_only', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P163_TableMetadata_ALNamespace()
    var
        TableMeta: Record "Table Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        TableMeta.Get(Database::"LT P163 NS Table");
        Observer.Observe('namespaced', '[' + TableMeta."AL Namespace" + ']');
        TableMeta.Get(Database::"Time Zone");
        Observer.Observe('platform', '[' + TableMeta."AL Namespace" + ']');
        TableMeta.Get(18);
        Observer.Observe('base_app_customer_BaseApp', '[' + TableMeta."AL Namespace" + ']');
        Observer.Expect('namespaced', '[P163Probe.Names]');
        Observer.Expect('platform', '[System.DateTime]');
        Observer.Expect('base_app_customer_BaseApp', '[Microsoft.Sales.Customer]');
        Observer.Verify();
    end;

    [Test]
    procedure P163_CodeunitMetadata_ALNamespace()
    var
        CodeunitMeta: Record "CodeUnit Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        CodeunitMeta.Get(Codeunit::"LT P163 NS Codeunit");
        Observer.Observe('namespaced', '[' + CodeunitMeta."AL Namespace" + ']');
        CodeunitMeta.Get(Codeunit::"LT P163 AllObj Namespace");
        Observer.Observe('global_namespace_test_codeunit', '[' + CodeunitMeta."AL Namespace" + ']');
        CodeunitMeta.Get(80);
        Observer.Observe('base_app_sales_post_BaseApp', '[' + CodeunitMeta."AL Namespace" + ']');
        Observer.Expect('namespaced', '[P163Probe.Names]');
        Observer.Expect('global_namespace_test_codeunit', '[]');
        Observer.Expect('base_app_sales_post_BaseApp', '[Microsoft.Sales.Posting]');
        Observer.Verify();
    end;
}
