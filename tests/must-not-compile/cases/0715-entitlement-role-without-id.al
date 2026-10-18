// @expect AL0674 | The property 'Id' is required when property 'Type' is set to 'Role'.
// An entitlement of type Role needs an Id.
permissionset 59716 "MNC U PS 715" { Permissions = codeunit "Mnc U CU 715" = X; }
codeunit 59717 "Mnc U CU 715" { }
entitlement "MNC U Ent 715" { Type = Role; RoleType = Local; ObjectEntitlements = "MNC U PS 715"; }
