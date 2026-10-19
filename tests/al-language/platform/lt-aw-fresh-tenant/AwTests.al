// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160), ALT Prompt Dialog Page (60879); objects in AwObjects.al
// Probe (corpus issue 648): platform tables, columns and rows on a fresh tenant of a test container: Session and Active Session
// host columns, Page Metadata SourceTableView with SORTING, ORDER and two conditions, Page Action rows of a page with two containers,
// nested groups, actionrefs and of a page with system actions, Report Layout List for ExcelLayoutMultipleDataSheets, obsolete and
// caption-less layouts, Record Link after RecordRef.AddLink and DeleteLink from another company, a table declared ObsoleteState = Moved,
// Modify of a Feature Key row, and the rows of Agent Creation Control (2000000297).
// Object ids 80350-80356.

codeunit 80350 "LT AW Row Text"
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

codeunit 80351 "LT AW Session Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Session_OwnRow_HostColumnValues()
    var
        SessionRec: Record Session;
        Observer: Codeunit "Probe Observer";
    begin
        SessionRec.SetRange("My Session", true);
        Observer.Observe('count', Format(SessionRec.Count()));
        if SessionRec.FindFirst() then begin
            Observer.Observe('database_name', SessionRec."Database Name");
            Observer.Observe('login_type', Format(SessionRec."Login Type"));
            Observer.Observe('application_name', SessionRec."Application Name");
            Observer.Observe('host_name', SessionRec."Host Name");
        end;
        Observer.Finish();
    end;

    [Test]
    procedure ActiveSession_OwnRow_HostColumnValues()
    var
        ActiveSession: Record "Active Session";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('get', Format(ActiveSession.Get(ServiceInstanceId(), SessionId())));
        Observer.Observe('database_name', ActiveSession."Database Name");
        Observer.Observe('server_instance_name', ActiveSession."Server Instance Name");
        Observer.Observe('client_computer_name', ActiveSession."Client Computer Name");
        Observer.Observe('client_type', Format(ActiveSession."Client Type"));
        Observer.Observe('server_computer_name_blank', Format(ActiveSession."Server Computer Name" = ''));
        Observer.Finish();
    end;
}

codeunit 80352 "LT AW Page Meta Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ViewOf(PageId: Integer): Text
    var
        Meta: Record "Page Metadata";
    begin
        if not Meta.Get(PageId) then
            exit('<no row>');
        exit(Meta.SourceTableView);
    end;

    local procedure ObserveActionRows(var Observer: Codeunit "Probe Observer"; PageId: Integer)
    var
        PageAction: Record "Page Action";
    begin
        PageAction.SetRange("Page ID", PageId);
        Observer.Observe('count', Format(PageAction.Count()));
        if PageAction.FindSet() then
            repeat
                Observer.Observe('row ' + Format(PageAction."Action Index"), StrSubstNo('id=%1 ind=%2 parent=%3 type=%4 sub=%5 name=%6', PageAction."Action ID", PageAction.Indentation,
                    PageAction."Parent Action ID", Format(PageAction."Action Type", 0, 9), Format(PageAction."Action Subtype", 0, 9), PageAction.Name));
            until PageAction.Next() = 0;
    end;

    [Test]
    procedure PageMetadata_SourceTableView_SortingOrderTwoConditions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('ascending', ViewOf(Page::"LT AW View Asc"));
        Observer.Observe('descending', ViewOf(Page::"LT AW View Desc"));
        Observer.Finish();
    end;

    [Test]
    procedure PageAction_ContainersGroupsActionRefs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveActionRows(Observer, Page::"LT AW Actions");
        Observer.Finish();
    end;

    [Test]
    procedure PageAction_SystemActions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveActionRows(Observer, Page::"ALT Prompt Dialog Page");
        Observer.Finish();
    end;
}

codeunit 80353 "LT AW Layout Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure LayoutRow(LayoutName: Text): Text
    var
        LayoutList: Record "Report Layout List";
        RowTexts: Codeunit "LT AW Row Text";
        RR: RecordRef;
    begin
        LayoutList.SetRange("Report ID", Report::"LT AW Layouts");
        LayoutList.SetRange(Name, LayoutName);
        if not LayoutList.FindFirst() then
            exit('<no row>');
        RR.GetTable(LayoutList);
        exit(RowTexts.RowText(RR, 'Report ID|Name|Runtime Package ID|Application ID'));
    end;

    [Test]
    procedure LayoutList_RowCount()
    var
        LayoutList: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
        Names: Text;
    begin
        LayoutList.SetRange("Report ID", Report::"LT AW Layouts");
        Observer.Observe('count', Format(LayoutList.Count()));
        if LayoutList.FindSet() then
            repeat
                Names += LayoutList.Name + ',';
            until LayoutList.Next() = 0;
        Observer.Observe('names', Names);
        Observer.Finish();
    end;

    [Test]
    procedure LayoutList_ExcelSheetsTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('XlTrue', LayoutRow('XlTrue'));
        Observer.Finish();
    end;

    [Test]
    procedure LayoutList_ExcelSheetsFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('XlFalse', LayoutRow('XlFalse'));
        Observer.Finish();
    end;

    [Test]
    procedure LayoutList_ExcelSheetsOmittedNoCaption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('XlOmit', LayoutRow('XlOmit'));
        Observer.Finish();
    end;

    [Test]
    procedure LayoutList_ObsoletePending()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('XlPending', LayoutRow('XlPending'));
        Observer.Finish();
    end;

    [Test]
    procedure LayoutList_Captioned()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('XlCaptioned', LayoutRow('XlCaptioned'));
        Observer.Finish();
    end;
}

codeunit 80354 "LT AW Link Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        OtherCompanyTok: Label 'LT AW OTHER CO', Locked = true;

    local procedure Seed(var RR: RecordRef)
    var
        Host: Record "LT AW Link Host";
    begin
        Host.DeleteAll();
        Host.Id := 1;
        Host.Name := 'one';
        Host.Insert();
        RR.GetTable(Host);
    end;

    [Test]
    procedure RecordRef_AddLink_CreatedAndCompany()
    var
        RecordLink: Record "Record Link";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Before: DateTime;
        After: DateTime;
        LinkId: Integer;
    begin
        Seed(RR);
        Before := CurrentDateTime();
        LinkId := RR.AddLink('https://example.com/aw', 'aw link');
        After := CurrentDateTime();
        Observer.Observe('get', Format(RecordLink.Get(LinkId)));
        Observer.Observe('company_is_session_company', Format(RecordLink.Company = CompanyName()));
        Observer.Observe('company_blank', Format(RecordLink.Company = ''));
        Observer.Observe('created_set', Format(RecordLink.Created <> 0DT));
        Observer.Observe('created_in_call_window', Format((RecordLink.Created >= Before - 1000) and (RecordLink.Created <= After + 1000)));
        Observer.Observe('type', Format(RecordLink.Type));
        Observer.Observe('description', RecordLink.Description);
        Observer.Observe('user_id_is_session_user', Format(RecordLink."User ID" = UserId()));
        Observer.Observe('record_id_matches', Format(RecordLink."Record ID" = RR.RecordId()));
        Observer.Finish();
    end;

    [Test]
    procedure RecordRef_DeleteLink_FromAnotherCompany()
    var
        Company: Record Company;
        RecordLink: Record "Record Link";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        OtherRR: RecordRef;
        LinkId: Integer;
    begin
        Seed(RR);
        LinkId := RR.AddLink('https://example.com/aw2', 'aw link 2');
        if not Company.Get(OtherCompanyTok) then begin
            Company.Init();
            Company.Name := OtherCompanyTok;
            Company.Insert();
        end;
        OtherRR.Open(Database::"LT AW Link Host", false, OtherCompanyTok);
        Observer.Observe('other_current_company', OtherRR.CurrentCompany());
        Observer.Observe('other_has_links_before', Format(OtherRR.HasLinks()));
        OtherRR.DeleteLink(LinkId);
        Observer.Observe('link_row_after_delete_from_other', Format(RecordLink.Get(LinkId)));
        Observer.Observe('own_has_links_after', Format(RR.HasLinks()));
        RR.ChangeCompany(OtherCompanyTok);
        RR.DeleteLink(LinkId);
        Observer.Observe('link_row_after_delete_changed_company', Format(RecordLink.Get(LinkId)));
        Observer.Finish();
    end;

    [Test]
    procedure RecordRef_DeleteLink_SameCompany()
    var
        RecordLink: Record "Record Link";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        LinkId: Integer;
    begin
        Seed(RR);
        LinkId := RR.AddLink('https://example.com/aw3', 'aw link 3');
        RR.DeleteLink(LinkId);
        Observer.Observe('link_row_after_delete', Format(RecordLink.Get(LinkId)));
        Observer.Finish();
    end;
}

codeunit 80355 "LT AW Moved Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure MovedTable_OwnApp_AllObj()
    var
        AllObj: Record AllObj;
        Observer: Codeunit "Probe Observer";
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", 80301);
        Observer.Observe('allobj_rows', Format(AllObj.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure MovedTable_OwnApp_ReadAndWrite()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        // The table is declared in this app with ObsoleteState = Moved: it is not in the runtime app, so RecordRef.Open fails.
        asserterror RR.Open(80301);
        Observer.Observe('open_error', GetLastErrorText());
        Observer.Observe('open_error_code', GetLastErrorCode());
        Observer.Finish();
    end;

    [Test]
    procedure MovedTable_BaseApp_NoSeries_AllObjRows()
    var
        AllObj: Record AllObj;
        Observer: Codeunit "Probe Observer";
        Names: Text;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", 308);
        Observer.Observe('rows_308', Format(AllObj.Count()));
        if AllObj.FindSet() then
            repeat
                Names += AllObj."Object Name" + ',';
            until AllObj.Next() = 0;
        Observer.Observe('names_308', Names);
        AllObj.SetRange("Object ID");
        AllObj.SetRange("Object Name", 'No. Series');
        Observer.Observe('rows_named_no_series', Format(AllObj.Count()));
        Observer.Finish();
    end;
}

codeunit 80356 "LT AW Feature Key Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        FeatureTok: Label 'ConcurrentResourcePosting', Locked = true;

    local procedure State(): Text
    var
        FeatureKey: Record "Feature Key";
        Result: Text;
    begin
        if not FeatureKey.Get(FeatureTok) then
            exit('<no row>');
        Result := 'get=' + Format(FeatureKey.Enabled);
        FeatureKey.SetRange(ID, FeatureTok);
        if FeatureKey.FindSet() then
            Result += ' findset=' + Format(FeatureKey.Enabled);
        FeatureKey.SetRange(Enabled, FeatureKey.Enabled::None);
        Result += ' count_none=' + Format(FeatureKey.Count());
        exit(Result);
    end;

    local procedure Restore()
    var
        FeatureKey: Record "Feature Key";
    begin
        if FeatureKey.Get(FeatureTok) then
            if FeatureKey.Enabled <> FeatureKey.Enabled::"All Users" then begin
                FeatureKey.Enabled := FeatureKey.Enabled::"All Users";
                FeatureKey.Modify();
            end;
    end;

    [Test]
    procedure FeatureKey_A_ModifyEnabled_ReadBack()
    var
        FeatureKey: Record "Feature Key";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('before', State());
        FeatureKey.Get(FeatureTok);
        FeatureKey.Enabled := FeatureKey.Enabled::None;
        Observer.Observe('modify', Format(FeatureKey.Modify()));
        Observer.Observe('after', State());
        // Left changed on purpose: the next test reads it and restores it.
        Observer.Finish();
    end;

    [Test]
    procedure FeatureKey_B_NextTest_SeesChange_ThenRestore()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('next_test', State());
        Restore();
        Observer.Observe('restored', State());
        Observer.Finish();
    end;

    [Test]
    procedure FeatureKey_C_ModifyUnchanged()
    var
        FeatureKey: Record "Feature Key";
        Observer: Codeunit "Probe Observer";
    begin
        Restore();
        FeatureKey.Get(FeatureTok);
        Observer.Observe('modify_nothing_changed', Format(FeatureKey.Modify()));
        Observer.Observe('after_nothing', State());
        FeatureKey.Get(FeatureTok);
        FeatureKey.Enabled := FeatureKey.Enabled;
        Observer.Observe('modify_same_value', Format(FeatureKey.Modify()));
        Observer.Observe('after_same', State());
        Observer.Finish();
    end;

    [Test]
    procedure FeatureKey_D_ModifyThenRollback()
    var
        FeatureKey: Record "Feature Key";
        Observer: Codeunit "Probe Observer";
    begin
        Restore();
        asserterror
        begin
            FeatureKey.Get(FeatureTok);
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
            Error('LT AW rollback');
        end;
        Observer.Observe('error', GetLastErrorText());
        Observer.Observe('after_rollback', State());
        Restore();
        Observer.Finish();
    end;
}

codeunit 80357 "LT AW Agent Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TryOpen(var RR: RecordRef)
    begin
        RR.Open(2000000297);
    end;

    [Test]
    procedure AgentCreationControl_Rows()
    var
        RowTexts: Codeunit "LT AW Row Text";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Rows: Text;
    begin
        ClearLastError();
        asserterror
        begin
            TryOpen(RR);
            Rows := 'name=' + RR.Name + ' count=' + Format(RR.Count()) + ';';
            if RR.FindSet() then
                repeat
                    Rows += '[' + RowTexts.RowText(RR, 'SystemId|SystemCreatedAt|SystemCreatedBy|SystemModifiedAt|SystemModifiedBy|SystemRowVersion') + ']';
                until RR.Next() = 0;
            Error('LT AW done');
        end;
        Observer.Observe('rows', Rows);
        Observer.Observe('error', GetLastErrorText());
        Observer.Finish();
    end;
}
