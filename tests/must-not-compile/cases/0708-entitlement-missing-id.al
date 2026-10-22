// @expect AL0674 | The property 'Id' is required when property 'Type' is set to 'ConcurrentUserServicePlan'
// @expect AL0674 | The property 'GroupName' is required when property 'Type' is set to 'ConcurrentUserServicePlan'
// An entitlement of type ConcurrentUserServicePlan needs an Id.
permissionset 59708 "MNC U PS 708" { Permissions = codeunit "Mnc U CU 708" = X; }
codeunit 59709 "Mnc U CU 708" { }
entitlement "MNC U Ent 708" { Type = ConcurrentUserServicePlan; ObjectEntitlements = "MNC U PS 708"; }
