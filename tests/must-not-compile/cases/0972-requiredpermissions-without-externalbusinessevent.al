// @expect AL0772 | The attribute 'RequiredPermissions' can only be used in combination with attribute 'ExternalBusinessEvent'.
// RequiredPermissions is only valid on an external business event.
table 59020 "MNC ReqPerm Row 0972"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { } }
}

codeunit 59021 "MNC ReqPerm 0972"
{
    [RequiredPermissions(PermissionObjectType::TableData, Database::"MNC ReqPerm Row 0972", 'R')]
    procedure Run1()
    begin
    end;
}
