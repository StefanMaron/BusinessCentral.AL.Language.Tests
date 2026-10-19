// @expect AL0195 | Invalid permission kind. Expected: 'RIMD'
// InherentPermissions with a permission letter that is not R, I, M or D.
table 59005 "MNC InhPerm Row 0969"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { } }
}

codeunit 59006 "MNC InhPerm 0969"
{
    [InherentPermissions(PermissionObjectType::TableData, Database::"MNC InhPerm Row 0969", 'q')]
    procedure Run1()
    begin
    end;
}
