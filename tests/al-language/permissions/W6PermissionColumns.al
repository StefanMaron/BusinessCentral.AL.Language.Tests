// Batch 6, md:515 [Permission "Security Filter" (11); Metadata Permission column 14; All Profile "Disable Personalization" (13)].
// (Published Application "Description" and "Tenant Visible" are in a table that is Scope = OnPrem: AL0296 in a Cloud app, see MANIFEST.)
// Observe-only. The columns are found by NUMBER (name, type, value format), then read by name where the name is known. Own permission set 'W6 PermSet' and own
// profile 'W6 Profile' give rows whose declared content is known. Role ids, app ids and counts of Microsoft rows are not observed.

table 67339 "W6 PM Table"
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

codeunit 67340 "W6 PM Code"
{
    procedure Nothing()
    begin
    end;
}

page 67341 "W6 PM Role Center"
{
    PageType = RoleCenter;
    ApplicationArea = All;
    UsageCategory = None;
}

permissionset 67342 "W6 PermSet"
{
    Assignable = true;
    Caption = 'W6 permission set';

    Permissions =
        tabledata "W6 PM Table" = RIM,
        table "W6 PM Table" = X,
        codeunit "W6 PM Code" = X,
        page "W6 PM Role Center" = X;
}

profile "W6 Profile"
{
    Caption = 'W6 profile';
    ProfileDescription = 'W6 profile description';
    RoleCenter = "W6 PM Role Center";
    Enabled = true;
    Promoted = false;
}

codeunit 67343 "W6 Permission Columns"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ColumnFact(TableId: Integer; FieldNumber: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(TableId);
        if not RecRef.FieldExist(FieldNumber) then
            exit('<no such column>');
        FldRef := RecRef.Field(FieldNumber);
        exit(FldRef.Name() + '|' + Format(FldRef.Type()) + '|' + Format(FldRef.Length()));
    end;

    [Test]
    procedure Permission_Column11_SecurityFilter()
    var
        Permission: Record Permission;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('column_11', ColumnFact(Database::Permission, 11));
        Observer.Observe('any_row', Format(Permission.FindFirst()));
        Observer.Observe('security_filter_of_first_row_blank', Format(Format(Permission."Security Filter") = ''));
        Observer.Expect('column_11', 'Security Filter|TableFilter|504');
        Observer.Expect('any_row', 'Yes');
        Observer.Expect('security_filter_of_first_row_blank', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Permission_Rows_OfTheOwnPermissionSet()
    var
        Permission: Record Permission;
        Observer: Codeunit "Probe Observer";
    begin
        Permission.SetRange("Role ID", 'W6 PermSet');
        Observer.Observe('rows_for_own_permission_set', Format(Permission.Count()));
        Observer.Expect('rows_for_own_permission_set', '4');
        Observer.Verify();
    end;

    [Test]
    procedure MetadataPermission_Column14_And_OwnRows()
    var
        MetadataPermission: Record "Metadata Permission";
        Text1: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('column_14', ColumnFact(Database::"Metadata Permission", 14));
        Observer.Observe('column_3', ColumnFact(Database::"Metadata Permission", 3));
        Observer.Observe('column_13', ColumnFact(Database::"Metadata Permission", 13));
        Observer.Observe('column_15', ColumnFact(Database::"Metadata Permission", 15));
        MetadataPermission.SetRange("Role ID", 'W6 PermSet');
        Observer.Observe('own_row_count', Format(MetadataPermission.Count()));
        if MetadataPermission.FindSet() then
            repeat
                Text1 += Format(MetadataPermission."Object Type") + ' ' + Format(MetadataPermission."Read Permission") + Format(MetadataPermission."Insert Permission") +
                    Format(MetadataPermission."Modify Permission") + Format(MetadataPermission."Delete Permission") + Format(MetadataPermission."Execute Permission") + '; ';
            until MetadataPermission.Next() = 0;
        Observer.Observe('own_rows_type_and_rights', Text1);
        Observer.Expect('column_14', 'Security Filter|TableFilter|504');
        Observer.Expect('column_3', 'Role Name|Text|30');
        Observer.Expect('column_13', 'Assignable|Boolean|4');
#if BC29PLUS
        Observer.Expect('column_15', 'AL Object Name|Text|100');
#else
        Observer.Expect('column_15', 'AL Object Name|Text|30');
#endif
        Observer.Expect('own_row_count', '4');
        Observer.Expect('own_rows_type_and_rights', 'Table Data YesYesYes  ; Table     Yes; Codeunit     Yes; Page     Yes; ');
        Observer.Verify();
    end;

    [Test]
    procedure AllProfile_Column13_DisablePersonalization_OfTheOwnProfile()
    var
        AllProfile: Record "All Profile";
        Module: ModuleInfo;
        Observer: Codeunit "Probe Observer";
    begin
        NavApp.GetCurrentModuleInfo(Module);
        Observer.Observe('column_13', ColumnFact(Database::"All Profile", 13));
        Observer.Observe('own_profile_found', Format(AllProfile.Get(AllProfile.Scope::Tenant, Module.Id(), 'W6 Profile')));
        Observer.Observe('disable_personalization', Format(AllProfile."Disable Personalization"));
        Observer.Observe('enabled', Format(AllProfile.Enabled));
        Observer.Observe('promoted', Format(AllProfile.Promoted));
        Observer.Observe('description', AllProfile.Description);
        Observer.Observe('caption', AllProfile.Caption);
        Observer.Expect('column_13', 'Disable Personalization|Boolean|4');
        Observer.Expect('own_profile_found', 'Yes');
        Observer.Expect('disable_personalization', 'No');
        Observer.Expect('enabled', 'Yes');
        Observer.Expect('promoted', 'No');
        Observer.Expect('description', 'W6 profile description');
        Observer.Expect('caption', 'W6 profile');
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
    procedure ColumnNames_Permission_MetadataPermission_AllProfile()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('permission_columns', ColumnList(Database::Permission));
        Observer.Observe('metadata_permission_columns', ColumnList(Database::"Metadata Permission"));
        Observer.Observe('all_profile_columns', ColumnList(Database::"All Profile"));
        Observer.Expect('permission_columns', '1=Role ID;3=Object Type;4=Object ID;6=Read Permission;7=Insert Permission;8=Modify Permission;9=Delete Permission;10=Execute Permission;11=Security Filter;2=Role Name;5=Object Name;12=AL Object Name;');
        Observer.Expect('metadata_permission_columns', '1=App ID;2=Role ID;4=Object Type;5=Object ID;7=Read Permission;8=Insert Permission;9=Modify Permission;10=Delete Permission;11=Execute Permission;12=Type;14=Security Filter;3=Role Name;6=Object Name;13=Assignable;15=AL Object Name;');
        Observer.Expect('all_profile_columns', '1=Scope;2=App ID;3=Profile ID;4=Description;5=Role Center ID;6=Default Role Center;7=Use Comments;8=Use Notes;9=Use Record Notes;10=Record Notebook;11=Use Page Notes;12=Page Notebook;13=Disable Personalization;14=App Name;15=Enabled;16=Caption;17=Promoted;');
        Observer.Verify();
    end;
}
