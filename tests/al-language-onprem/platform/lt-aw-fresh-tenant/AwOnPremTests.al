// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160, main app); objects below
// Probe (corpus issue 648), OnPrem app because these platform tables are Scope = OnPrem (AL0296 in a Cloud app): the rows of
// API Webhook Entity for an API page of this app, "Tenant ID" of Published Application for the test apps and Base Application,
// the rows, Insert and Delete of Performance Profile Scheduler and MCP Configuration (BC 28 and later), and the Table Information
// row of a table declared ObsoleteState = Moved (table 80301 of the main app).
// Object ids 98450-98460.

table 98450 "LT AW Api Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 98451 "LT AW Api Page"
{
    PageType = API;
    APIPublisher = 'ltaw';
    APIGroup = 'probe';
    APIVersion = 'v1.0';
    EntityName = 'awEntity';
    EntitySetName = 'awEntities';
    SourceTable = "LT AW Api Src";
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(id; Rec.SystemId) { }
                field(number; Rec.Id) { }
                field(name; Rec.Name) { }
            }
        }
    }
}

codeunit 98452 "LT AW OnPrem Row Text"
{
    procedure RowText(var RR: RecordRef; Skip: Text): Text
    var
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if (FR.Class = FieldClass::Normal) and (FR.Type <> FieldType::Blob) and (FR.Type <> FieldType::Media) and (FR.Type <> FieldType::MediaSet) then
                if not ('|' + Skip + '|').Contains('|' + FR.Name + '|') then
                    Result += FR.Name + '=' + Format(FR.Value, 0, 9) + ';';
        end;
        exit(Result);
    end;
}

codeunit 98453 "LT AW OnPrem Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SystemSkipTok: Label 'SystemId|SystemCreatedAt|SystemCreatedBy|SystemModifiedAt|SystemModifiedBy|SystemRowVersion', Locked = true;

    [Test]
    procedure ApiWebhookEntity_RowOfOwnApiPage()
    var
        Entity: Record "API Webhook Entity";
        RowTexts: Codeunit "LT AW OnPrem Row Text";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Observer.Observe('total_not_empty', Format(not Entity.IsEmpty()));
        Entity.SetRange("Object ID", Page::"LT AW Api Page");
        Observer.Observe('own_rows', Format(Entity.Count()));
        if Entity.FindFirst() then begin
            RR.GetTable(Entity);
            Observer.Observe('own_row', RowTexts.RowText(RR, SystemSkipTok));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure ApiWebhookEntity_FirstRow()
    var
        Entity: Record "API Webhook Entity";
        RowTexts: Codeunit "LT AW OnPrem Row Text";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        if Entity.FindFirst() then begin
            RR.GetTable(Entity);
            Observer.Observe('first_row', RowTexts.RowText(RR, SystemSkipTok));
        end;
        Observer.Finish();
    end;

    local procedure TenantIdOf(AppId: Guid): Text
    var
        PublishedApp: Record "Published Application";
        Result: Text;
    begin
        PublishedApp.SetRange(ID, AppId);
        Result := Format(PublishedApp.Count()) + ' rows;';
        if PublishedApp.FindSet() then
            repeat
                Result += '[tenant=' + PublishedApp."Tenant ID" + ' as=' + Format(PublishedApp."Published As") + ']';
            until PublishedApp.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure PublishedApplication_TenantId()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('base_application', TenantIdOf('437dbf0e-84ff-417a-965d-ed2bb9650972'));
        Observer.Observe('coverage_tests', TenantIdOf('a1b2c3d4-e5f6-7890-abcd-ef1234567890'));
        Observer.Observe('onprem_tests', TenantIdOf('3f8c1a52-9d4e-4b17-8c26-5ea70b93d418'));
        Observer.Observe('session_tenant', TenantId());
        Observer.Finish();
    end;

    [Test]
    procedure PerformanceProfileScheduler_RowsInsertDelete()
    var
        Scheduler: Record "Performance Profile Scheduler";
        RowTexts: Codeunit "LT AW OnPrem Row Text";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Observer.Observe('count', Format(Scheduler.Count()));
        Scheduler.Init();
        RR.GetTable(Scheduler);
        Observer.Observe('init_row', RowTexts.RowText(RR, SystemSkipTok));
        Observer.Observe('insert', Format(Scheduler.Insert()));
        Observer.Observe('count_after_insert', Format(Scheduler.Count()));
        Scheduler.FindFirst();
        RR.GetTable(Scheduler);
        Observer.Observe('stored_row', RowTexts.RowText(RR, SystemSkipTok + '|Schedule ID|User ID|Client Type'));
        Observer.Observe('delete', Format(Scheduler.Delete()));
        Observer.Observe('count_after_delete', Format(Scheduler.Count()));
        Observer.Finish();
    end;

#if BC28PLUS
    [Test]
    procedure McpConfiguration_Rows()
    var
        Config: Record "MCP Configuration";
        RowTexts: Codeunit "LT AW OnPrem Row Text";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Rows: Text;
    begin
        Observer.Observe('count', Format(Config.Count()));
        if Config.FindSet() then
            repeat
                RR.GetTable(Config);
                Rows += '[' + RowTexts.RowText(RR, SystemSkipTok) + ']';
            until Config.Next() = 0;
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;

    [Test]
    procedure McpConfiguration_InsertDelete()
    var
        Config: Record "MCP Configuration";
        RowTexts: Codeunit "LT AW OnPrem Row Text";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Config.Init();
        Config.Name := 'LT AW';
        Observer.Observe('insert', Format(Config.Insert()));
        Observer.Observe('count_after_insert', Format(Config.Count()));
        Config.Get('LT AW');
        RR.GetTable(Config);
        Observer.Observe('stored_row', RowTexts.RowText(RR, SystemSkipTok));
        Observer.Observe('delete', Format(Config.Delete()));
        Observer.Observe('count_after_delete', Format(Config.Count()));
        Config.Get('');
        Observer.Observe('delete_fresh_row', Format(Config.Delete()));
        Observer.Observe('count_after_delete_fresh', Format(Config.Count()));
        Observer.Finish();
    end;
#endif

    [Test]
    procedure MovedTable_TableInformation()
    var
        TableInfo: Record "Table Information";
        Observer: Codeunit "Probe Observer";
    begin
        TableInfo.SetRange("Table No.", 80301);
        Observer.Observe('own_moved_rows', Format(TableInfo.Count()));
        if TableInfo.FindFirst() then
            Observer.Observe('own_moved_name', TableInfo."Table Name" + ' company=' + Format(TableInfo."Company Name" = CompanyName()));
        TableInfo.SetRange("Table No.", 308);
        Observer.Observe('no_series_rows', Format(TableInfo.Count()));
        Observer.Finish();
    end;
}
