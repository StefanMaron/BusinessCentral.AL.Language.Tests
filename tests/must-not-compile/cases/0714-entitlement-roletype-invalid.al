// @expect AL0169 | The option value 'Wrong' is not valid
// RoleType takes Local or Delegated only.
permissionset 59714 "MNC U PS 714" { Permissions = codeunit "Mnc U CU 714" = X; }
codeunit 59715 "Mnc U CU 714" { }
entitlement "MNC U Ent 714" { Type = Role; Id = 'D365 BASIC'; RoleType = Wrong; ObjectEntitlements = "MNC U PS 714"; }
