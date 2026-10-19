// @expect AL0223 | The Property 'RoleType' can only be used if the property 'Type' is set to 'Role'
// @expect AL0223 | The Property 'GroupName' can only be used if the property 'Type' is set to 'ConcurrentUserServicePlan'
// RoleType needs Type = Role, and GroupName needs Type = ConcurrentUserServicePlan.
permissionset 59718 "MNC U PS 716" { Permissions = codeunit "Mnc U CU 716" = X; }
codeunit 59719 "Mnc U CU 716" { }
entitlement "MNC U Ent 716" { Type = Implicit; RoleType = Local; GroupName = 'G'; ObjectEntitlements = "MNC U PS 716"; }
